import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondolbom_admin/main.dart';
import 'package:ondolbom_admin/vm/management/admin_records_vm.dart';
import 'package:ondolbom_admin/model/auth/admin_user.dart';
import 'package:ondolbom_admin/vm/auth/admin_auth_vm.dart';

class FakeAdminAuth extends Fake implements FirebaseAuth {
  String? email;
  String? password;
  int signouts = 0;
  @override
  Future<void> setPersistence(Persistence persistence) async {}
  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    this.email = email;
    this.password = password;
    return FakeCredential();
  }

  @override
  Future<void> signOut() async {
    signouts++;
  }
}

class FakeCredential extends Fake implements UserCredential {}

class FakeUser extends Fake implements User {}

void main() {
  testWidgets('Login is required, input validated, no signup offered', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('온돌봄 관리자 로그인'), findsOneWidget);
    expect(find.text('회원가입'), findsNothing);
    await tester.tap(find.text('로그인'));
    await tester.pump();
    expect(find.text('비밀번호를 입력해 주세요.'), findsOneWidget);
  });

  testWidgets('Family account cannot see management screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionProvider.overrideWith((ref) => Stream.value(FakeUser())),
          adminUserProvider.overrideWith(
            (ref) async =>
                throw const AdminAuthError('관리자로 등록된 계정만 이용할 수 있습니다.'),
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('관리자로 등록된 계정만 이용할 수 있습니다.'), findsOneWidget);
    expect(find.text('관리자 인증 완료'), findsNothing);
    expect(find.text('로그아웃'), findsOneWidget);
  });

  testWidgets('Server-authorized admin enters and can sign out', (
    tester,
  ) async {
    final auth = FakeAdminAuth();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseAuthProvider.overrideWithValue(auth),
          adminRecordsProvider.overrideWith(
            (ref, request) async => const AdminRecords([], false),
          ),
          authSessionProvider.overrideWith((ref) => Stream.value(FakeUser())),
          adminUserProvider.overrideWith(
            (ref) async =>
                const AdminUser(id: 'admin', email: 'admin@example.com'),
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();
    // 기본 테스트 화면은 좁아서 메뉴가 Drawer에 표시된다.
    expect(find.text('사용자 관리'), findsOneWidget);
    expect(find.text('표시할 데이터가 없습니다.'), findsOneWidget);
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('로그아웃'));
    await tester.pumpAndSettle();
    expect(auth.signouts, 1);
  });

  test('Login trims email and preserves password', () async {
    final auth = FakeAdminAuth();
    final container = ProviderContainer(
      overrides: [firebaseAuthProvider.overrideWithValue(auth)],
    );
    addTearDown(container.dispose);
    await container
        .read(adminAuthVmProvider.notifier)
        .signIn(' admin@example.com ', ' password ');
    expect(auth.email, 'admin@example.com');
    expect(auth.password, ' password ');
  });
}
