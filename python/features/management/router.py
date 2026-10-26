"""기존 운영 데이터 조회 전용 API. DB 구조와 데이터는 변경하지 않는다."""
from fastapi import APIRouter, Depends, HTTPException, Query
from pymysql import MySQLError
from python.database import connect
from python.features.auth.router import require_admin

router = APIRouter(dependencies=[Depends(require_admin)])
QUERIES = {
    'users': '''SELECT user_id, name, user_email, phone, registered_at FROM user
                WHERE withdrawn_at IS NULL ORDER BY registered_at DESC, user_id LIMIT %s OFFSET %s''',
    'rooms': '''SELECT family_room_id, care_recipient_name, created_at,
                (SELECT COUNT(*) FROM participate p WHERE p.family_room_id = f.family_room_id
                 AND p.is_active = 1 AND p.left_at IS NULL) AS member_count
                FROM family_room f WHERE family_room_deleted_at IS NULL
                ORDER BY created_at DESC, family_room_id LIMIT %s OFFSET %s''',
    'questions': '''SELECT q.question_seq, q.question_title, q.question_content, q.questioned_at,
                   u.name AS user_name,
                   (SELECT COUNT(*) FROM answer a WHERE a.question_seq = q.question_seq
                    AND a.answer_deleted_at IS NULL) AS answer_count
                   FROM question q LEFT JOIN user u ON u.user_id = q.user_id
                   WHERE q.question_deleted_at IS NULL
                   ORDER BY q.questioned_at DESC, q.question_seq DESC LIMIT %s OFFSET %s''',
    'notices': '''SELECT notice_id, notice_title, notice_content, notice_created_at
                 FROM create_notice WHERE notice_deleted_at IS NULL
                 ORDER BY notice_created_at DESC, notice_id LIMIT %s OFFSET %s''',
}

@router.get('/{section}')
def list_records(section: str, limit: int = Query(30, ge=1, le=100),
                 offset: int = Query(0, ge=0)):
    if section not in QUERIES:
        raise HTTPException(404, '지원하지 않는 메뉴입니다.')
    connection = None
    try:
        connection = connect()
        with connection.cursor() as cursor:
            cursor.execute('START TRANSACTION READ ONLY')
            cursor.execute(QUERIES[section], (limit + 1, offset))
            rows = cursor.fetchall()
        return {'items': rows[:limit], 'has_more': len(rows) > limit}
    except (MySQLError, ValueError):
        raise HTTPException(503, '데이터를 불러오지 못했습니다. DB 연결을 확인해 주세요.') from None
    finally:
        if connection is not None:
            connection.rollback()
            connection.close()
