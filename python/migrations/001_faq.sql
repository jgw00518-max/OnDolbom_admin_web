-- 공유 DB 적용 전 승인 필요. 기존 테이블/데이터는 변경하지 않는다.
CREATE TABLE faq (
  faq_id VARCHAR(50) NOT NULL PRIMARY KEY,
  admin_id VARCHAR(50) NOT NULL,
  faq_question VARCHAR(100) NOT NULL,
  faq_answer TEXT NOT NULL,
  faq_created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  faq_updated_at DATETIME NULL,
  faq_deleted_at DATETIME NULL,
  CONSTRAINT fk_faq_admin FOREIGN KEY (admin_id) REFERENCES admin(admin_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
