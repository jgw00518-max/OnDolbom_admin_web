-- 먼저 이전 앱/API 버전으로 전환하고, 추가 데이터는 별도 백업한 뒤 운영자가 실행한다.
-- 아래 SQL은 승인 없이 실행하지 않는다. FAQ 데이터와 상태 메타데이터가 제거된다.
ALTER TABLE question
  DROP FOREIGN KEY fk_question_status_admin,
  DROP CHECK chk_question_processing_status,
  DROP COLUMN status_updated_by,
  DROP COLUMN status_updated_at,
  DROP COLUMN processing_status;
DROP TABLE faq;
