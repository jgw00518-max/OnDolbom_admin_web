"""기존 문의와 답변 테이블을 사용하는 관리자 기능."""
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, field_validator
from pymysql import MySQLError
from python.database import connect
from python.features.auth.router import AdminProfile, require_admin

router = APIRouter()


class AnswerInput(BaseModel):
    content: str

    @field_validator('content')
    @classmethod
    def validate_content(cls, value):
        value = value.strip()
        if not value:
            raise ValueError('답변을 입력해 주세요.')
        if any(ord(char) > 0xFFFF for char in value):
            raise ValueError('현재 DB에서 지원하지 않는 이모지·문자가 포함되어 있습니다.')
        if len(value.encode('utf-8')) > 65535:
            raise ValueError('답변이 너무 깁니다.')
        return value


@router.get('/{question_seq}/answers')
def answers(question_seq: int, admin: AdminProfile = Depends(require_admin)):
    connection = None
    try:
        connection = connect()
        with connection.cursor() as cursor:
            cursor.execute('START TRANSACTION READ ONLY')
            cursor.execute('SELECT question_seq FROM question WHERE question_seq=%s AND question_deleted_at IS NULL', (question_seq,))
            if cursor.fetchone() is None:
                raise HTTPException(404, '문의를 찾을 수 없습니다.')
            cursor.execute('''SELECT answer_seq, answer_content, answered_at FROM answer
                              WHERE question_seq=%s AND answer_deleted_at IS NULL
                              ORDER BY answered_at, answer_seq''', (question_seq,))
            return {'items': cursor.fetchall()}
    except (MySQLError, ValueError):
        raise HTTPException(503, '답변을 불러오지 못했습니다.') from None
    finally:
        if connection is not None:
            connection.rollback()
            connection.close()


@router.post('/{question_seq}/answers', status_code=201)
def create_answer(question_seq: int, body: AnswerInput, admin: AdminProfile = Depends(require_admin)):
    connection = None
    try:
        connection = connect()
        with connection.cursor() as cursor:
            # 삭제된 문의에는 답변하지 않으며 작성자 ID는 DB에서만 가져온다.
            cursor.execute('SELECT user_id FROM question WHERE question_seq=%s AND question_deleted_at IS NULL FOR UPDATE', (question_seq,))
            question = cursor.fetchone()
            if question is None:
                raise HTTPException(404, '문의를 찾을 수 없습니다.')
            cursor.execute('''INSERT INTO answer (question_seq, user_id, admin_id, answer_content)
                              VALUES (%s, %s, %s, %s)''',
                           (question_seq, question['user_id'], admin.admin_id, body.content))
            answer_seq = cursor.lastrowid
        connection.commit()
        return {'answer_seq': answer_seq}
    except (MySQLError, ValueError):
        raise HTTPException(503, '답변 저장 결과를 확인하지 못했습니다. 답변 목록을 확인해 주세요.') from None
    finally:
        if connection is not None:
            connection.rollback()
            connection.close()
