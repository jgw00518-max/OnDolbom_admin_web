from unittest import TestCase
from unittest.mock import MagicMock, patch
from fastapi.testclient import TestClient
from python.main import app
from python.features.auth.router import require_admin
from python.features.management.router import QUERIES

class ManagementTests(TestCase):
    def tearDown(self):
        app.dependency_overrides.clear()

    def test_all_sections_require_authentication(self):
        with TestClient(app) as client, patch('python.features.management.router.connect') as connect:
            for section in QUERIES:
                self.assertEqual(client.get('/admin/management/' + section).status_code, 401)
            connect.assert_not_called()

    def test_read_only_and_pagination(self):
        app.dependency_overrides[require_admin] = lambda: object()
        for section in QUERIES:
            connection = MagicMock()
            cursor = connection.cursor.return_value.__enter__.return_value
            cursor.fetchall.return_value = [{'id': i} for i in range(31)]
            with TestClient(app) as client, patch('python.features.management.router.connect', return_value=connection):
                response = client.get('/admin/management/' + section + '?offset=30')
            self.assertEqual(response.status_code, 200)
            self.assertEqual(len(response.json()['items']), 30)
            self.assertTrue(response.json()['has_more'])
            self.assertEqual(cursor.execute.call_args_list[0].args, ('START TRANSACTION READ ONLY',))
            self.assertEqual(cursor.execute.call_args.args[1], (31, 30))
            connection.commit.assert_not_called()
            connection.rollback.assert_called_once()
            connection.close.assert_called_once()
