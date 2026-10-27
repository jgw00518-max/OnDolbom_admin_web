import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondolbom_admin/vm/auth/admin_auth_vm.dart';

class ContentApi {
  ContentApi(this.ref);
  final Ref ref;
  Future<Map<String, dynamic>> request(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) throw const AdminAuthError('다시 로그인해 주세요.');
    final base = ref.read(apiBaseUrlProvider).replaceAll(RegExp(r'/+$'), '');
    final client = ref.read(httpClientProvider);
    final uri = Uri.parse('$base$path');
    final token = await user.getIdToken();
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    // 저장 요청은 응답 유실 시 중복 생성할 수 있으므로 자동 재시도하지 않는다.
    final response = await switch (method) {
      'POST' => client.post(uri, headers: headers, body: jsonEncode(body)),
      'PUT' => client.put(uri, headers: headers, body: jsonEncode(body)),
      'PATCH' => client.patch(uri, headers: headers, body: jsonEncode(body)),
      'DELETE' => client.delete(uri, headers: headers),
      _ => client.get(uri, headers: headers),
    }.timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AdminAuthError(switch (response.statusCode) {
        401 => '로그인이 만료되었습니다. 다시 로그인해 주세요.',
        403 => '접근 권한이 없습니다.',
        404 => '삭제되었거나 존재하지 않는 항목입니다.',
        409 => '다른 관리자가 변경했습니다. 새로고침 후 다시 시도해 주세요.',
        422 => '필수 입력·길이·지원하지 않는 문자를 확인해 주세요.',
        _ => _errorMessage(response.body),
      });
    }
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  String _errorMessage(String body) {
    try {
      final detail = (jsonDecode(body) as Map<String, dynamic>)['detail'];
      if (detail is String && detail.contains('DB 적용 대기')) return detail;
    } catch (_) {
      /* 응답 형식이 달라도 일반 오류를 안내한다. */
    }
    return '처리 결과를 확인하지 못했습니다. 목록을 새로고침해 주세요.';
  }
}

final contentApiProvider = Provider.autoDispose((ref) => ContentApi(ref));
final contentDataProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>(
      (ref, path) => ref.watch(contentApiProvider).request(path),
    );
