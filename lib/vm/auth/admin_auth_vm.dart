import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:ondolbom_admin/model/auth/admin_user.dart';

// SDK와 HTTP를 주입 가능하게 두어 실제 계정 없이 인증 흐름을 테스트한다.
final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);
final authSessionProvider = StreamProvider<User?>(
  (ref) => ref.watch(firebaseAuthProvider).authStateChanges(),
);
final apiBaseUrlProvider = Provider<String>(
  (ref) => const String.fromEnvironment(
    'ADMIN_API_BASE_URL',
    defaultValue: 'http://localhost:8001',
  ),
);
final httpClientProvider = Provider.autoDispose<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

class AdminAuthError implements Exception {
  const AdminAuthError(this.message);
  final String message;
  @override
  String toString() => message;
}

// Firebase 로그인 성공만으로 화면을 허용하지 않고 서버 권한 조회를 추가한다.
final adminUserProvider = FutureProvider.autoDispose<AdminUser?>(
  retry: (_, _) => null,
  (ref) async {
    final session = await ref.watch(authSessionProvider.future);
    if (session == null) return null;
    final auth = ref.watch(firebaseAuthProvider);
    final client = ref.watch(httpClientProvider);
    final uri = Uri.parse(
      '${ref.watch(apiBaseUrlProvider).replaceAll(RegExp(r'/+$'), '')}/admin/auth/me',
    );
    try {
      for (var attempt = 0; attempt < 2; attempt++) {
        final user = auth.currentUser;
        if (user == null || user.uid != session.uid) {
          throw const AdminAuthError('로그인 상태가 변경되었습니다. 다시 로그인해 주세요.');
        }
        // 최초 401은 ID 토큰 강제 갱신 후 한 번만 재시도한다.
        final token = await user.getIdToken(attempt == 1);
        if (token == null || token.isEmpty) {
          throw const AdminAuthError('다시 로그인해 주세요.');
        }
        final response = await client
            .get(uri, headers: {'Authorization': 'Bearer $token'})
            .timeout(const Duration(seconds: 15));
        if (response.statusCode == 401 && attempt == 0) continue;
        if (response.statusCode != 200) {
          throw AdminAuthError(switch (response.statusCode) {
            401 => '로그인이 만료되었습니다. 다시 로그인해 주세요.',
            403 => '관리자로 등록된 계정만 이용할 수 있습니다.',
            503 => '인증 서버 또는 DB 설정을 확인해 주세요.',
            _ => '관리자 정보를 불러오지 못했습니다.',
          });
        }
        return AdminUser.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
        );
      }
      throw const AdminAuthError('다시 로그인해 주세요.');
    } on AdminAuthError {
      rethrow;
    } on TimeoutException {
      throw const AdminAuthError('서버 응답 시간이 초과되었습니다.');
    } catch (_) {
      throw const AdminAuthError('서버 주소·연결·응답을 확인해 주세요.');
    }
  },
);

final adminAuthVmProvider = NotifierProvider<AdminAuthVm, AsyncValue<void>>(
  AdminAuthVm.new,
);

class AdminAuthVm extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> signIn(String email, String password) => _run(() async {
    // 브라우저 종료 후까지 관리자 세션을 보존하지 않도록 session persistence를 사용한다.
    await ref.read(firebaseAuthProvider).setPersistence(Persistence.SESSION);
    await ref
        .read(firebaseAuthProvider)
        .signInWithEmailAndPassword(email: email.trim(), password: password);
  });

  Future<void> signOut() =>
      _run(() => ref.read(firebaseAuthProvider).signOut());

  Future<void> _run(Future<void> Function() action) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
  }
}

String loginErrorMessage(Object error) {
  if (error is! FirebaseAuthException) return '요청을 처리하지 못했습니다. 다시 시도해 주세요.';
  return switch (error.code) {
    'invalid-credential' ||
    'user-not-found' ||
    'wrong-password' => '이메일 또는 비밀번호를 확인해 주세요.',
    'invalid-email' => '이메일 형식을 확인해 주세요.',
    'user-disabled' => '사용이 중지된 계정입니다.',
    'too-many-requests' => '잠시 후 다시 시도해 주세요.',
    'network-request-failed' => '네트워크 연결을 확인해 주세요.',
    _ => '로그인에 실패했습니다. 인증 설정을 확인해 주세요.',
  };
}
