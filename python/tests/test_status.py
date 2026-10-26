from unittest import TestCase
from unittest.mock import MagicMock, patch
from fastapi.testclient import TestClient
from python.main import app
from python.features.auth.router import require_admin, AdminProfile
from python.features.auth.firebase_auth import require_firebase_user

class StatusTests(TestCase):
 def setUp(self):
  self.conn=MagicMock();self.cursor=self.conn.cursor.return_value.__enter__.return_value
 def tearDown(self): app.dependency_overrides.clear()
 def admin(self): app.dependency_overrides[require_admin]=lambda: AdminProfile(admin_id='verified',admin_email=None)
 def test_protected_and_invalid_state(self):
  with TestClient(app) as c, patch('python.features.inquiries.status.connect') as db:
   self.assertEqual(c.patch('/admin/inquiries/1/status',json={'processing_status':'RESOLVED','expected_status':'RECEIVED'}).status_code,401)
   self.admin()
   self.assertEqual(c.patch('/admin/inquiries/1/status',json={'processing_status':'INVALID','expected_status':'RECEIVED'}).status_code,422)
   db.assert_not_called()
 def test_missing_schema_blocks_writes(self):
  self.admin()
  with TestClient(app) as c, patch('python.features.inquiries.status.connect',return_value=self.conn), patch('python.features.inquiries.status.status_ready',return_value=False):
   self.assertEqual(c.patch('/admin/inquiries/1/status',json={'processing_status':'RESOLVED','expected_status':'RECEIVED'}).status_code,503)
  self.conn.commit.assert_not_called()
  self.cursor.execute.assert_not_called()
 def test_manual_transitions_conflicts_and_missing(self):
  self.admin()
  with TestClient(app) as c, patch('python.features.inquiries.status.connect',return_value=self.conn), patch('python.features.inquiries.status.status_ready',return_value=True):
   for target in ['RECEIVED','IN_REVIEW','NEEDS_INFO','RESOLVED']:
    self.cursor.fetchone.return_value={'processing_status':'IN_REVIEW'}
    self.assertEqual(c.patch('/admin/inquiries/1/status',json={'processing_status':target,'expected_status':'IN_REVIEW'}).status_code,200)
   self.assertEqual(self.conn.commit.call_count,4)
   self.assertEqual(c.patch('/admin/inquiries/1/status',json={'processing_status':'RESOLVED','expected_status':'RECEIVED'}).status_code,409)
   self.cursor.fetchone.return_value=None
   self.assertEqual(c.patch('/admin/inquiries/1/status',json={'processing_status':'RESOLVED','expected_status':'RECEIVED'}).status_code,404)
   self.assertEqual(self.conn.commit.call_count,4)
 def test_user_cannot_read_other_inquiry(self):
  app.dependency_overrides[require_firebase_user]=lambda:{'uid':'verified'}
  self.cursor.fetchone.return_value={'user_id':'owner'}
  self.cursor.fetchall.return_value=[]
  with TestClient(app) as c, patch('python.features.inquiries.status.connect',return_value=self.conn), patch('python.features.inquiries.status.status_ready',return_value=False):
   self.assertEqual(c.get('/inquiries/9').status_code,404)
  sql,params=self.cursor.execute.call_args.args
  self.assertIn('q.user_id=%s',sql)
  self.assertEqual(params,('owner',9,31,0))
 def test_faq_schema_pending(self):
  self.admin()
  with TestClient(app) as c, patch('python.features.faqs.router.connect',return_value=self.conn):
   self.cursor.fetchone.return_value={'count':0}
   r=c.get('/admin/faqs');self.assertEqual(r.status_code,503)
   self.assertIn('DB',r.json()['detail'])
  self.conn.commit.assert_not_called()
