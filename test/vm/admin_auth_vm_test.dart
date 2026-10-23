import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ondolbom_admin/vm/auth/admin_auth_vm.dart';

class TokenUser extends Fake implements User {
  @override
  String get uid => 'verified';
  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async =>
      forceRefresh ? 'renewed' : 'first';
}

class TokenAuth extends Fake implements FirebaseAuth {
  @override
  User get currentUser => TokenUser();
}

void main() {
  test('Admin lookup refreshes 401 once and sends Firebase ID token', () async {
    var calls = 0;
    final client = MockClient((request) async {
      calls++;
      expect(request.url.path, '/admin/auth/me');
      expect(
        request.headers['Authorization'],
        'Bearer ${calls == 1 ? 'first' : 'renewed'}',
      );
      return calls == 1
          ? http.Response('', 401)
          : http.Response('{"admin_id":"admin","admin_email":null}', 200);
    });
    final container = ProviderContainer(
      overrides: [
        firebaseAuthProvider.overrideWithValue(TokenAuth()),
        authSessionProvider.overrideWith((ref) => Stream.value(TokenUser())),
        httpClientProvider.overrideWithValue(client),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(client.close);
    final subscription = container.listen(adminUserProvider, (_, _) {});
    addTearDown(subscription.close);
    expect((await container.read(adminUserProvider.future))?.id, 'admin');
    expect(calls, 2);
  });

  test('403 and server errors do not produce an admin profile', () async {
    for (final status in [403, 503]) {
      final client = MockClient(
        (_) async => http.Response('private error', status),
      );
      final container = ProviderContainer(
        overrides: [
          firebaseAuthProvider.overrideWithValue(TokenAuth()),
          authSessionProvider.overrideWith((ref) => Stream.value(TokenUser())),
          httpClientProvider.overrideWithValue(client),
        ],
      );
      final subscription = container.listen(adminUserProvider, (_, _) {});
      try {
        await expectLater(
          container.read(adminUserProvider.future),
          throwsA(isA<AdminAuthError>()),
        );
      } finally {
        subscription.close();
        container.dispose();
        client.close();
      }
    }
  });
}
