"""공지 관리. 기존 복합 PK와 논리 삭제를 유지한다."""
from uuid import uuid4
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, ConfigDict, Field, field_validator
from pymysql import MySQLError
from python.database import connect
from python.features.auth.router import require_admin
from python.features.auth.firebase_auth import require_firebase_user


class NoticeInput(BaseModel):
    model_config = ConfigDict(extra='forbid', str_strip_whitespace=True)
    notice_title: str = Field(min_length=1, max_length=100)
    notice_content: str = Field(min_length=1)

    @field_validator('notice_title', 'notice_content')
    @classmethod
    def supported_text(cls, value):
        # 공유 공지 테이블의 utf8mb3/TEXT 제한을 미리 검증한다.
        if any(ord(c) > 0xFFFF for c in value) or len(value.encode('utf-8')) > 65535:
            raise ValueError('지원하지 않는 문자 또는 저장 가능한 길이를 확인해 주세요.')
        return value


FIELDS = 'admin_id, notice_id, notice_title, notice_content, notice_created_at, notice_updated_at'
router = APIRouter(dependencies=[Depends(require_admin)])
public_router = APIRouter(dependencies=[Depends(require_firebase_user)])


def read_notices(admin_id=None, notice_id=None, limit=30, offset=0):
    connection = None
    try:
        connection = connect()
        with connection.cursor() as cursor:
            if notice_id is None:
                cursor.execute(f'''SELECT {FIELDS} FROM create_notice WHERE notice_deleted_at IS NULL
                    ORDER BY notice_created_at DESC, admin_id, notice_id LIMIT %s OFFSET %s''', (limit + 1, offset))
                rows = cursor.fetchall()
                return {'items': rows[:limit], 'has_more': len(rows) > limit}
            cursor.execute(f'''SELECT {FIELDS} FROM create_notice WHERE admin_id=%s AND notice_id=%s
                AND notice_deleted_at IS NULL''', (admin_id, notice_id))
            row = cursor.fetchone()
            if row is None:
                raise HTTPException(404, '공지를 찾을 수 없습니다.')
            return row
    except (MySQLError, ValueError):
        raise HTTPException(503, '공지를 불러오지 못했습니다.') from None
    finally:
        if connection is not None:
            connection.close()


@router.get('')
@public_router.get('')
def notice_list(limit: int = Query(30, ge=1, le=100), offset: int = Query(0, ge=0)):
    return read_notices(limit=limit, offset=offset)


@router.get('/{admin_id}/{notice_id}')
@public_router.get('/{admin_id}/{notice_id}')
def notice_detail(admin_id: str, notice_id: str):
    return read_notices(admin_id, notice_id)


@router.post('', status_code=201)
def create_notice(body: NoticeInput, admin=Depends(require_admin)):
    return write_notice('create', admin.admin_id, str(uuid4()), body)


@router.put('/{admin_id}/{notice_id}')
def update_notice(admin_id: str, notice_id: str, body: NoticeInput):
    return write_notice('update', admin_id, notice_id, body)


@router.delete('/{admin_id}/{notice_id}')
def delete_notice(admin_id: str, notice_id: str):
    return write_notice('delete', admin_id, notice_id)


def write_notice(action, admin_id, notice_id, body=None):
    connection = None
    try:
        connection = connect()
        with connection.cursor() as cursor:
            if action == 'create':
                # 작성자 ID는 인증 결과에서 결정한다. 기존 관리자 공통 권한을 유지한다.
                cursor.execute('''INSERT INTO create_notice (admin_id, notice_id, notice_title, notice_content)
                    VALUES (%s,%s,%s,%s)''', (admin_id, notice_id, body.notice_title, body.notice_content))
            else:
                cursor.execute('''SELECT notice_id FROM create_notice WHERE admin_id=%s AND notice_id=%s
                    AND notice_deleted_at IS NULL FOR UPDATE''', (admin_id, notice_id))
                if cursor.fetchone() is None:
                    raise HTTPException(404, '공지를 찾을 수 없습니다.')
                if action == 'update':
                    cursor.execute('''UPDATE create_notice SET notice_title=%s, notice_content=%s,
                        notice_updated_at=CURRENT_TIMESTAMP WHERE admin_id=%s AND notice_id=%s''',
                        (body.notice_title, body.notice_content, admin_id, notice_id))
                else:
                    cursor.execute('''UPDATE create_notice SET notice_deleted_at=CURRENT_TIMESTAMP
                        WHERE admin_id=%s AND notice_id=%s''', (admin_id, notice_id))
        connection.commit()
        return {'admin_id': admin_id, 'notice_id': notice_id}
    except (MySQLError, ValueError):
        raise HTTPException(503, '저장 결과를 확인하지 못했습니다. 목록을 확인해 주세요.') from None
    finally:
        if connection is not None:
            connection.rollback()
            connection.close()
