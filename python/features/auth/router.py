"""모든 관리자 API는 require_admin을 사용해 DB의 사전 등록 여부를 확인한다."""

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from pymysql import MySQLError

from python.database import connect
from python.features.auth.firebase_auth import require_firebase_user

router = APIRouter()


class AdminProfile(BaseModel):
    admin_id: str
    admin_email: str | None


def require_admin(claims: dict = Depends(require_firebase_user)) -> AdminProfile:
    """Firebase 인증은 신원 확인일 뿐이다. 관리자 권한은 매 요청마다 DB로 확인한다."""
    connection = None
    try:
        connection = connect()
        with connection.cursor() as cursor:
            # 이메일만 같은 가족 계정을 관리자에 자동 연결하지 않는다.
            # 현재 collation의 대소문자 무시를 보완하도록 UID 정확 비교도 적용한다.
            cursor.execute(
                '''SELECT admin_id, admin_email FROM admin
                   WHERE admin_firebase_uid = %s AND BINARY admin_firebase_uid = BINARY %s
                   LIMIT 1''', (claims['uid'], claims['uid']),
            )
            row = cursor.fetchone()
        if row is None:
            raise HTTPException(403, '관리자로 등록된 계정만 이용할 수 있습니다.')
        # 비밀번호와 서비스 계정 정보는 응답에 포함하지 않는다.
        return AdminProfile(**row)
    except (MySQLError, ValueError):
        raise HTTPException(503, '관리자 정보를 확인하지 못했습니다. 서버 설정을 확인해 주세요.') from None
    finally:
        if connection is not None:
            connection.close()


@router.get('/me', response_model=AdminProfile)
def current_admin(admin: AdminProfile = Depends(require_admin)):
    return admin
