from unittest import TestCase
from unittest.mock import MagicMock, patch
from fastapi.testclient import TestClient
from python.main import app
from python.features.auth.router import require_admin, AdminProfile
from python.features.auth.firebase_auth import require_firebase_user

class NoticeTests(TestCase):
 def tearDown(self): app.dependency_overrides.clear()
 def test_auth_all_operations(self):
  with TestClient(app) as c, patch('python.features.content.router.connect') as db:
   for method,path,body in [('GET','/admin/notices',None),('GET','/notices',None),('GET','/admin/notices/a/n',None),('POST','/admin/notices',{}),('PUT','/admin/notices/a/n',{}),('DELETE','/admin/notices/a/n',None)]:
    self.assertEqual(c.request(method,path,json=body).status_code,401)
   db.assert_not_called()
 def test_validation(self):
  app.dependency_overrides[require_admin]=lambda: AdminProfile(admin_id='a',admin_email=None)
  with TestClient(app) as c, patch('python.features.content.router.connect') as db:
   for title,content in [(' ','x'),('x',' '),('x'*101,'x'),('x',chr(0x1F600)),('x','a'*65536)]:
    self.assertEqual(c.post('/admin/notices',json={'notice_title':title,'notice_content':content}).status_code,422)
   db.assert_not_called()
 def test_create_identity_and_update_composite_key(self):
  app.dependency_overrides[require_admin]=lambda: AdminProfile(admin_id='verified',admin_email=None)
  conn=MagicMock(); cursor=conn.cursor.return_value.__enter__.return_value
  cursor.fetchone.return_value={'notice_id':'n'}
  with TestClient(app) as c, patch('python.features.content.router.connect',return_value=conn):
   r=c.post('/admin/notices',json={'notice_title':' t ','notice_content':' c '})
   self.assertEqual(r.status_code,201)
   self.assertEqual(cursor.execute.call_args.args[1][0],'verified')
   self.assertEqual(c.put('/admin/notices/owner/n',json={'notice_title':'t2','notice_content':'c2'}).status_code,200)
   self.assertEqual(cursor.execute.call_args.args[1],('t2','c2','owner','n'))
   self.assertEqual(c.delete('/admin/notices/owner/n').status_code,200)
   self.assertIn('notice_deleted_at=CURRENT_TIMESTAMP',cursor.execute.call_args.args[0])
   self.assertEqual(cursor.execute.call_args.args[1],('owner','n'))
  self.assertEqual(conn.commit.call_count,3)
 def test_public_scope_and_deleted_detail(self):
  app.dependency_overrides[require_firebase_user]=lambda: {'uid':'family'}
  conn=MagicMock(); cursor=conn.cursor.return_value.__enter__.return_value
  cursor.fetchall.return_value=[];cursor.fetchone.return_value=None
  with TestClient(app) as c, patch('python.features.content.router.connect',return_value=conn):
   self.assertEqual(c.get('/notices').status_code,200)
   self.assertIn('notice_deleted_at IS NULL',cursor.execute.call_args.args[0])
   self.assertEqual(c.get('/notices/a/n').status_code,404)
  conn.commit.assert_not_called()
