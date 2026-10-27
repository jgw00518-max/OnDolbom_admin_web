from unittest import TestCase
from unittest.mock import MagicMock, patch
from fastapi.testclient import TestClient
from python.main import app
from python.features.auth.router import require_admin, AdminProfile
from python.features.auth.firebase_auth import require_firebase_user

class FaqTests(TestCase):
 def setUp(self):
  patcher=patch('python.features.faqs.router.require_faq_schema')
  patcher.start()
  self.addCleanup(patcher.stop)

 def tearDown(self): app.dependency_overrides.clear()
 def test_auth_all_operations(self):
  with TestClient(app) as c, patch('python.features.faqs.router.connect') as db:
   for method,path,body in [('GET','/admin/faqs',None),('GET','/faqs',None),('GET','/admin/faqs/a/n',None),('POST','/admin/faqs',{}),('PUT','/admin/faqs/a/n',{}),('DELETE','/admin/faqs/a/n',None)]:
    self.assertEqual(c.request(method,path,json=body).status_code,401)
   db.assert_not_called()
 def test_validation(self):
  app.dependency_overrides[require_admin]=lambda: AdminProfile(admin_id='a',admin_email=None)
  with TestClient(app) as c, patch('python.features.faqs.router.connect') as db:
   for title,content in [(' ','x'),('x',' '),('x'*101,'x'),('x',chr(0x1F600)),('x','a'*65536)]:
    self.assertEqual(c.post('/admin/faqs',json={'faq_question':title,'faq_answer':content}).status_code,422)
   db.assert_not_called()
 def test_create_identity_and_update_composite_key(self):
  app.dependency_overrides[require_admin]=lambda: AdminProfile(admin_id='verified',admin_email=None)
  conn=MagicMock(); cursor=conn.cursor.return_value.__enter__.return_value
  cursor.fetchone.return_value={'faq_id':'n'}
  with TestClient(app) as c, patch('python.features.faqs.router.connect',return_value=conn):
   r=c.post('/admin/faqs',json={'faq_question':' t ','faq_answer':' c '})
   self.assertEqual(r.status_code,201)
   self.assertEqual(cursor.execute.call_args.args[1][0],'verified')
   self.assertEqual(c.put('/admin/faqs/owner/n',json={'faq_question':'t2','faq_answer':'c2'}).status_code,200)
   self.assertEqual(cursor.execute.call_args.args[1],('t2','c2','owner','n'))
   self.assertEqual(c.delete('/admin/faqs/owner/n').status_code,200)
   self.assertIn('faq_deleted_at=CURRENT_TIMESTAMP',cursor.execute.call_args.args[0])
   self.assertEqual(cursor.execute.call_args.args[1],('owner','n'))
  self.assertEqual(conn.commit.call_count,3)
 def test_public_scope_and_deleted_detail(self):
  app.dependency_overrides[require_firebase_user]=lambda: {'uid':'family'}
  conn=MagicMock(); cursor=conn.cursor.return_value.__enter__.return_value
  cursor.fetchall.return_value=[];cursor.fetchone.return_value=None
  with TestClient(app) as c, patch('python.features.faqs.router.connect',return_value=conn):
   self.assertEqual(c.get('/faqs').status_code,200)
   self.assertIn('faq_deleted_at IS NULL',cursor.execute.call_args.args[0])
   self.assertEqual(c.get('/faqs/a/n').status_code,404)
  conn.commit.assert_not_called()
