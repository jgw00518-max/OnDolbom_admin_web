from unittest import TestCase
from unittest.mock import MagicMock, patch

from fastapi.testclient import TestClient
from firebase_admin import auth

from python.main import app
from python.features.auth.firebase_auth import require_firebase_user, verify_firebase_token
from python.features.auth.router import require_admin


class AdminAuthTests(TestCase):
    def setUp(self):
        self.client = TestClient(app)

    def tearDown(self):
        app.dependency_overrides.clear()
        self.client.close()

    def test_missing_token_rejected_before_database(self):
        with patch('python.features.auth.router.connect') as connect:
            self.assertEqual(self.client.get('/admin/auth/me').status_code, 401)
            connect.assert_not_called()

    def test_invalid_token_rejected(self):
        with patch('python.features.auth.firebase_auth.get_firebase_app', return_value=object()), patch(
            'python.features.auth.firebase_auth.auth.verify_id_token', side_effect=auth.InvalidIdTokenError('private')
        ):
            response = self.client.get('/admin/auth/me', headers={'Authorization': 'Bearer invalid'})
            self.assertEqual(response.status_code, 401)
            self.assertNotIn('private', response.text)

    def lookup(self, row):
        # 인증된 claims만 대체하며 실제 DB나 사용자는 변경하지 않는다.
        app.dependency_overrides[require_firebase_user] = lambda: {'uid': 'verified-uid'}
        connection = MagicMock()
        cursor = connection.cursor.return_value.__enter__.return_value
        cursor.fetchone.return_value = row
        with patch('python.features.auth.router.connect', return_value=connection):
            response = self.client.get('/admin/auth/me?uid=attacker&admin_email=attacker@example.com')
        self.assertEqual(cursor.execute.call_args.args[1], ('verified-uid', 'verified-uid'))
        self.assertIn('BINARY admin_firebase_uid', cursor.execute.call_args.args[0])
        connection.close.assert_called_once()
        connection.commit.assert_not_called()
        return response

    def test_family_user_denied_even_with_firebase_login(self):
        self.assertEqual(self.lookup(None).status_code, 403)

    def test_preregistered_admin_allowed(self):
        response = self.lookup({'admin_id': 'admin-test', 'admin_email': 'admin@example.com'})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json(), {'admin_id': 'admin-test', 'admin_email': 'admin@example.com'})

    def test_database_failure_does_not_grant_access(self):
        app.dependency_overrides[require_firebase_user] = lambda: {'uid': 'verified-uid'}
        with patch('python.features.auth.router.connect', side_effect=ValueError('private')):
            response = self.client.get('/admin/auth/me')
        self.assertEqual(response.status_code, 503)
        self.assertNotIn('private', response.text)

    def test_revocation_check_is_enabled(self):
        with patch('python.features.auth.firebase_auth.get_firebase_app', return_value='app'), patch(
            'python.features.auth.firebase_auth.auth.verify_id_token', return_value={'uid': 'verified-uid'}
        ) as verify:
            verify_firebase_token('test')
            verify.assert_called_once_with('test', app='app', check_revoked=True)

    def test_cors_allows_local_web_and_rejects_other_origin(self):
        headers = {'Origin': 'http://localhost:5173', 'Access-Control-Request-Method': 'GET', 'Access-Control-Request-Headers': 'authorization'}
        response = self.client.options('/admin/auth/me', headers=headers)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.headers['access-control-allow-origin'], headers['Origin'])
        headers['Origin'] = 'https://untrusted.example'
        self.assertEqual(self.client.options('/admin/auth/me', headers=headers).status_code, 400)
