"""기존 운영 데이터 조회 전용 API. DB 구조와 데이터는 변경하지 않는다."""
from fastapi import APIRouter, Depends, HTTPException, Query
from pymysql import MySQLError
from python.database import connect
from python.features.auth.router import require_admin
from python.features.schema_support import status_ready
from python.features.inquiries.status import STATUS_LABELS

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
    'notices': '''SELECT admin_id, notice_id, notice_title, notice_content, notice_created_at
                 FROM create_notice WHERE notice_deleted_at IS NULL
                 ORDER BY notice_created_at DESC, notice_id LIMIT %s OFFSET %s''',
}

@router.get('/{section}')
def list_records(section: str, limit: int = Query(30, ge=1, le=100),
                 offset: int = Query(0, ge=0), q: str = Query('', max_length=100)):
    if section not in QUERIES:
        raise HTTPException(404, '지원하지 않는 메뉴입니다.')
    connection = None
    try:
        connection = connect()
        with connection.cursor() as cursor:
            cursor.execute('START TRANSACTION READ ONLY')
            sql = QUERIES[section]
            ready = status_ready(cursor) if section == 'questions' else False
            if section == 'questions':
                fields = 'q.processing_status, q.status_updated_at' if ready else 'NULL AS processing_status, NULL AS status_updated_at'
                sql = sql.replace('SELECT q.question_seq', f'SELECT {fields}, q.question_seq', 1)
            params = []
            if q.strip() and section in ('users', 'rooms'):
                # LOCATE로 %, _도 와일드카드가 아닌 실제 검색어로 처리한다.
                columns = ('name', 'user_email', 'phone') if section == 'users' else ('care_recipient_name', 'family_room_id')
                condition = ' AND (' + ' OR '.join(f'LOCATE(%s, COALESCE({column}, \'\')) > 0' for column in columns) + ')'
                sql = sql.replace(' ORDER BY', condition + ' ORDER BY', 1) if section == 'users' else sql.replace('\n                ORDER BY', condition + '\n                ORDER BY', 1)
                params.extend([q.strip()] * len(columns))
            cursor.execute(sql, tuple(params + [limit + 1, offset]))
            rows = cursor.fetchall()
            if section == 'questions':
                for row in rows:
                    row['status_supported'] = ready
                    row['processing_status_label'] = STATUS_LABELS.get(row.get('processing_status'))
        return {'items': rows[:limit], 'has_more': len(rows) > limit}
    except (MySQLError, ValueError):
        raise HTTPException(503, '데이터를 불러오지 못했습니다. DB 연결을 확인해 주세요.') from None
    finally:
        if connection is not None:
            connection.rollback()
            connection.close()


@router.get('/rooms/{room_id}')
def room_detail(room_id: str):
    connection = None
    try:
        connection = connect()
        with connection.cursor() as cursor:
            cursor.execute('START TRANSACTION READ ONLY')
            cursor.execute('''SELECT family_room_id, care_recipient_name, birth_date,
                              care_address, special_notes, created_at
                              FROM family_room WHERE family_room_id = %s
                              AND family_room_deleted_at IS NULL''', (room_id,))
            room = cursor.fetchone()
            if room is None:
                raise HTTPException(404, '공간을 찾을 수 없습니다.')
            cursor.execute('''SELECT u.name, u.user_email, p.is_representative, p.joined_at
                              FROM participate p JOIN user u ON u.user_id = p.user_id
                              WHERE p.family_room_id = %s AND p.is_active = 1
                              AND p.left_at IS NULL AND u.withdrawn_at IS NULL
                              ORDER BY p.is_representative DESC, p.joined_at, p.participate_seq''', (room_id,))
            room['members'] = cursor.fetchall()
        return room
    except (MySQLError, ValueError):
        raise HTTPException(503, '공간 정보를 불러오지 못했습니다.') from None
    finally:
        if connection is not None:
            connection.rollback()
            connection.close()
