-- 모든 기존 문의는 답변 여부와 무관하게 RECEIVED로 시작한다.
ALTER TABLE question
  ADD COLUMN processing_status VARCHAR(30) NOT NULL DEFAULT 'RECEIVED',
  ADD COLUMN status_updated_at DATETIME NULL,
  ADD COLUMN status_updated_by VARCHAR(50) NULL,
  ADD CONSTRAINT chk_question_processing_status CHECK
    (processing_status IN ('RECEIVED','IN_REVIEW','NEEDS_INFO','RESOLVED')),
  ADD CONSTRAINT fk_question_status_admin FOREIGN KEY (status_updated_by) REFERENCES admin(admin_id);
