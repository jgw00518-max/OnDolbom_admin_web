"""답변 유무와 별개인 처리 상태. 승인된 DDL 적용 전에는 조회만 안전하게 제공한다."""
from typing import Literal
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, ConfigDict
from pymysql import MySQLError
from python.database import connect
from python.features.auth.router import require_admin
from python.features.auth.firebase_auth import require_firebase_user
from python.features.schema_support import status_ready

router = APIRouter(dependencies=[Depends(require_admin)])
user_router = APIRouter()
Status = Literal['RECEIVED', 'IN_REVIEW', 'NEEDS_INFO', 'RESOLVED']
STATUS_LABELS = {'RECEIVED': '접수', 'IN_REVIEW': '확인 중', 'NEEDS_INFO': '추가 확인 필요', 'RESOLVED': '처리 완료'}


class StatusInput(BaseModel):
    model_config = ConfigDict(extra='forbid')
    processing_status: Status
    expected_status: Status


def read_inquiries(question_seq=None, claims=None, limit=30, offset=0):
    connection = None
    try:
        connection = connect()
        with connection.cursor() as cursor:
            owner = None
            if claims is not None:
                # 일반 사용자는 검증된 UID로 찾은 본인 문의만 조회한다.
                cursor.execute('''SELECT user_id FROM user WHERE user_firebase_uid=%s
                    AND BINARY user_firebase_uid=BINARY %s AND withdrawn_at IS NULL''', (claims['uid'], claims['uid']))
                user = cursor.fetchone()
                if user is None:
                    raise HTTPException(403, '사용자 등록 상태를 확인해 주세요.')
                owner = user['user_id']
            ready = status_ready(cursor)
            fields = 'q.processing_status, q.status_updated_at' if ready else 'NULL AS processing_status, NULL AS status_updated_at'
            sql = f'''SELECT q.question_seq, q.question_title, q.question_content, q.family_room_id,
                q.questioned_at, {fields}, EXISTS(SELECT 1 FROM answer a WHERE
                a.question_seq=q.question_seq AND a.user_id=q.user_id AND a.answer_deleted_at IS NULL) AS answered
                FROM question q WHERE q.question_deleted_at IS NULL'''
            params = []
            if owner is not None:
                sql += ' AND q.user_id=%s'
                params.append(owner)
            if question_seq is not None:
                sql += ' AND q.question_seq=%s'
                params.append(question_seq)
            sql += ' ORDER BY q.question_seq DESC LIMIT %s OFFSET %s'
            cursor.execute(sql, tuple(params + [limit + 1, offset]))
            rows = cursor.fetchall()
            for row in rows:
                row['answered'] = bool(row['answered'])
                row['status_supported'] = ready
                row['processing_status_label'] = STATUS_LABELS.get(row['processing_status'])
            if question_seq is None:
                return {'items': rows[:limit], 'has_more': len(rows) > limit, 'status_supported': ready}
            if not rows:
                raise HTTPException(404, '문의를 찾을 수 없습니다.')
            row = rows[0]
            cursor.execute('''SELECT answer_seq, answer_content, answered_at FROM answer
                WHERE question_seq=%s AND answer_deleted_at IS NULL
                AND user_id=(SELECT user_id FROM question WHERE question_seq=%s)
                ORDER BY answered_at, answer_seq''', (question_seq, question_seq))
            row['answers'] = cursor.fetchall()
            return row
    except (MySQLError, ValueError):
        raise HTTPException(503, '문의를 불러오지 못했습니다.') from None
    finally:
        if connection is not None:
            connection.close()


@router.get('/{question_seq}')
def admin_detail(question_seq: int):
    return read_inquiries(question_seq)


@user_router.get('')
def user_list(limit: int = Query(30, ge=1, le=100), offset: int = Query(0, ge=0), claims=Depends(require_firebase_user)):
    return read_inquiries(claims=claims, limit=limit, offset=offset)


@user_router.get('/{question_seq}')
def user_detail(question_seq: int, claims=Depends(require_firebase_user)):
    return read_inquiries(question_seq, claims)


@router.patch('/{question_seq}/status')
def update_status(question_seq: int, body: StatusInput, admin=Depends(require_admin)):
    connection = None
    try:
        connection = connect()
        with connection.cursor() as cursor:
            if not status_ready(cursor):
                raise HTTPException(503, '문의 상태 DB 적용 대기: 승인 후 002_inquiry_status.sql을 적용해야 합니다.')
            cursor.execute('''SELECT processing_status FROM question WHERE question_seq=%s
                AND question_deleted_at IS NULL FOR UPDATE''', (question_seq,))
            row = cursor.fetchone()
            if row is None:
                raise HTTPException(404, '문의를 찾을 수 없습니다.')
            # 타 관리자 변경 덮어쓰기를 막고, 동일 상태 재요청은 변경 시각을 갱신하지 않는다.
            if row['processing_status'] != body.expected_status:
                raise HTTPException(409, '처리 상태가 변경되었습니다. 새로고침해 주세요.')
            if row['processing_status'] != body.processing_status:
                cursor.execute('''UPDATE question SET processing_status=%s, status_updated_at=CURRENT_TIMESTAMP,
                    status_updated_by=%s WHERE question_seq=%s''', (body.processing_status, admin.admin_id, question_seq))
        connection.commit()
        return {'processing_status': body.processing_status, 'processing_status_label': STATUS_LABELS[body.processing_status]}
    except (MySQLError, ValueError):
        raise HTTPException(503, '처리 상태 저장 결과를 확인하지 못했습니다.') from None
    finally:
        if connection is not None:
            connection.rollback()
            connection.close()
