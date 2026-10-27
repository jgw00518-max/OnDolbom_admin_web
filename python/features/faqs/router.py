"""승인된 FAQ 테이블 적용 후 활성화되는 관리·조회 API. 논리 삭제 사용."""
from uuid import uuid4
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, ConfigDict, Field, field_validator
from pymysql import MySQLError
from python.database import connect
from python.features.schema_support import require_faq_schema
from python.features.auth.router import require_admin
from python.features.auth.firebase_auth import require_firebase_user


class FaqInput(BaseModel):
    model_config = ConfigDict(extra='forbid', str_strip_whitespace=True)
    faq_question: str = Field(min_length=1, max_length=100)
    faq_answer: str = Field(min_length=1)

    @field_validator('faq_question', 'faq_answer')
    @classmethod
    def supported_text(cls, value):
        # 공유 FAQ 테이블의 utf8mb3/TEXT 제한을 미리 검증한다.
        if any(ord(c) > 0xFFFF for c in value) or len(value.encode('utf-8')) > 65535:
            raise ValueError('지원하지 않는 문자 또는 저장 가능한 길이를 확인해 주세요.')
        return value


FIELDS = 'admin_id, faq_id, faq_question, faq_answer, faq_created_at, faq_updated_at'
router = APIRouter(dependencies=[Depends(require_admin)])
public_router = APIRouter(dependencies=[Depends(require_firebase_user)])


def read_faqs(admin_id=None, faq_id=None, limit=30, offset=0):
    connection = None
    try:
        connection = connect()
        with connection.cursor() as cursor:
            require_faq_schema(cursor)
            if faq_id is None:
                cursor.execute(f'''SELECT {FIELDS} FROM faq WHERE faq_deleted_at IS NULL
                    ORDER BY faq_created_at DESC, admin_id, faq_id LIMIT %s OFFSET %s''', (limit + 1, offset))
                rows = cursor.fetchall()
                return {'items': rows[:limit], 'has_more': len(rows) > limit}
            cursor.execute(f'''SELECT {FIELDS} FROM faq WHERE admin_id=%s AND faq_id=%s
                AND faq_deleted_at IS NULL''', (admin_id, faq_id))
            row = cursor.fetchone()
            if row is None:
                raise HTTPException(404, 'FAQ를 찾을 수 없습니다.')
            return row
    except (MySQLError, ValueError):
        raise HTTPException(503, 'FAQ를 불러오지 못했습니다.') from None
    finally:
        if connection is not None:
            connection.close()


@router.get('')
@public_router.get('')
def faq_list(limit: int = Query(30, ge=1, le=100), offset: int = Query(0, ge=0)):
    return read_faqs(limit=limit, offset=offset)


@router.get('/{admin_id}/{faq_id}')
@public_router.get('/{admin_id}/{faq_id}')
def faq_detail(admin_id: str, faq_id: str):
    return read_faqs(admin_id, faq_id)


@router.post('', status_code=201)
def create_faq(body: FaqInput, admin=Depends(require_admin)):
    return write_faq('create', admin.admin_id, str(uuid4()), body)


@router.put('/{admin_id}/{faq_id}')
def update_faq(admin_id: str, faq_id: str, body: FaqInput):
    return write_faq('update', admin_id, faq_id, body)


@router.delete('/{admin_id}/{faq_id}')
def delete_faq(admin_id: str, faq_id: str):
    return write_faq('delete', admin_id, faq_id)


def write_faq(action, admin_id, faq_id, body=None):
    connection = None
    try:
        connection = connect()
        with connection.cursor() as cursor:
            require_faq_schema(cursor)
            if action == 'create':
                # 작성자 ID는 인증 결과에서 결정한다. 기존 관리자 공통 권한을 유지한다.
                cursor.execute('''INSERT INTO faq (admin_id, faq_id, faq_question, faq_answer)
                    VALUES (%s,%s,%s,%s)''', (admin_id, faq_id, body.faq_question, body.faq_answer))
            else:
                cursor.execute('''SELECT faq_id FROM faq WHERE admin_id=%s AND faq_id=%s
                    AND faq_deleted_at IS NULL FOR UPDATE''', (admin_id, faq_id))
                if cursor.fetchone() is None:
                    raise HTTPException(404, 'FAQ를 찾을 수 없습니다.')
                if action == 'update':
                    cursor.execute('''UPDATE faq SET faq_question=%s, faq_answer=%s,
                        faq_updated_at=CURRENT_TIMESTAMP WHERE admin_id=%s AND faq_id=%s''',
                        (body.faq_question, body.faq_answer, admin_id, faq_id))
                else:
                    cursor.execute('''UPDATE faq SET faq_deleted_at=CURRENT_TIMESTAMP
                        WHERE admin_id=%s AND faq_id=%s''', (admin_id, faq_id))
        connection.commit()
        return {'admin_id': admin_id, 'faq_id': faq_id}
    except (MySQLError, ValueError):
        raise HTTPException(503, '저장 결과를 확인하지 못했습니다. 목록을 확인해 주세요.') from None
    finally:
        if connection is not None:
            connection.rollback()
            connection.close()
