"""미승인 DDL을 자동 실행하지 않고 적용 여부만 읽는다."""
from fastapi import HTTPException


def faq_ready(cursor):
    cursor.execute('''SELECT COUNT(*) AS count FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='faq'
        AND COLUMN_NAME IN ('faq_id','admin_id','faq_question','faq_answer',
                            'faq_created_at','faq_updated_at','faq_deleted_at')''')
    row = cursor.fetchone()
    return row is not None and row['count'] == 7


def status_ready(cursor):
    cursor.execute('''SELECT COUNT(*) AS count FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='question'
        AND COLUMN_NAME IN ('processing_status','status_updated_at','status_updated_by')''')
    row = cursor.fetchone()
    return row is not None and row['count'] == 3


def require_faq_schema(cursor):
    if not faq_ready(cursor):
        raise HTTPException(503, 'FAQ DB 적용 대기: 승인 후 001_faq.sql을 적용해야 합니다.')
