from unittest import TestCase
from unittest.mock import MagicMock, patch
from fastapi.testclient import TestClient
from python.main import app
from python.features.auth.router import require_admin, AdminProfile

class InquiryTests(TestCase):
 def tearDown(self): app.dependency_overrides.clear()
 def test_auth_required(self):
  with TestClient(app) as c, patch('python.features.inquiries.router.connect') as connect:
   self.assertEqual(c.post('/admin/inquiries/1/answers',json={'content':'answer'}).status_code,401)
   self.assertEqual(c.get('/admin/inquiries/1/answers').status_code,401)
   connect.assert_not_called()
 def test_validation(self):
  app.dependency_overrides[require_admin]=lambda: AdminProfile(admin_id='admin',admin_email=None)
  with TestClient(app) as c, patch('python.features.inquiries.router.connect') as connect:
   for content in ['   ', chr(0x1F600), 'a'*65536]:
    self.assertEqual(c.post('/admin/inquiries/1/answers',json={'content':content}).status_code,422)
   connect.assert_not_called()
 def test_insert_uses_server_identity(self):
  app.dependency_overrides[require_admin]=lambda: AdminProfile(admin_id='server-admin',admin_email=None)
  connection=MagicMock()
  cursor=connection.cursor.return_value.__enter__.return_value
  cursor.fetchone.return_value={'user_id':'question-owner'}
  cursor.lastrowid=7
  with TestClient(app) as c, patch('python.features.inquiries.router.connect',return_value=connection):
   r=c.post('/admin/inquiries/1/answers',json={'content':'  answer  ','admin_id':'attacker','user_id':'attacker'})
  self.assertEqual(r.status_code,201)
  self.assertEqual(cursor.execute.call_args.args[1],(1,'question-owner','server-admin','answer'))
  connection.commit.assert_called_once()
  connection.close.assert_called_once()
 def test_missing_question_never_commits(self):
  app.dependency_overrides[require_admin]=lambda: AdminProfile(admin_id='admin',admin_email=None)
  connection=MagicMock()
  connection.cursor.return_value.__enter__.return_value.fetchone.return_value=None
  with TestClient(app) as c, patch('python.features.inquiries.router.connect',return_value=connection):
   self.assertEqual(c.post('/admin/inquiries/1/answers',json={'content':'answer'}).status_code,404)
  connection.commit.assert_not_called()
  connection.rollback.assert_called_once()
