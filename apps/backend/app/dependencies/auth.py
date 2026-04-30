from typing import Optional

from fastapi import Depends
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import PermissionDenied, TokenInvalid
from app.core.security import decode_token
from app.dependencies.db import get_db_session
from app.repositories.tenant_repository import TenantRepository
from app.repositories.user_repository import UserRepository
from app.schemas.user import CurrentTenant, CurrentUser

bearer_scheme = HTTPBearer(auto_error=False)


async def get_current_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(bearer_scheme),
    session: AsyncSession = Depends(get_db_session),
) -> CurrentUser:
    if credentials is None:
        raise TokenInvalid()

    payload = decode_token(credentials.credentials)
    if payload.get("typ") != "access":
        raise TokenInvalid()

    try:
        user_id = int(payload["sub"])
        tenant_id = int(payload["tenant_id"])
    except (KeyError, TypeError, ValueError) as exc:
        raise TokenInvalid() from exc

    user_repository = UserRepository(session)
    tenant_repository = TenantRepository(session)
    user = await user_repository.get_active_by_id(user_id=user_id, tenant_id=tenant_id)
    tenant = await tenant_repository.get_active_by_id(tenant_id=tenant_id)

    if user is None or tenant is None:
        raise TokenInvalid()

    roles = await user_repository.get_role_codes(user_id=user.user_id, tenant_id=tenant.tenant_id)

    return CurrentUser(
        id=user.user_id,
        uid=user.user_uid,
        tenant=CurrentTenant(
            id=tenant.tenant_id,
            uid=tenant.tenant_uid,
            code=tenant.tenant_code,
            name=tenant.tenant_name,
            timezone=tenant.timezone,
            locale=tenant.locale,
        ),
        company_id=user.company_id,
        branch_id=user.branch_id,
        login_id=user.login_id,
        name=user.user_name,
        email=user.email,
        phone=user.phone,
        user_type=user.user_type,
        mfa_enabled=user.mfa_enabled,
        roles=roles,
    )


def _has_admin_capability(current_user: CurrentUser) -> bool:
    admin_user_types = {"ADMIN", "INTERNAL", "AUDITOR"}
    admin_roles = {"ADMIN", "TENANT_ADMIN", "SYSTEM_ADMIN", "SUPER_ADMIN"}
    if current_user.user_type.upper() in admin_user_types:
        return True
    return bool(admin_roles.intersection({role.upper() for role in current_user.roles}))


async def require_admin_user(
    current_user: CurrentUser = Depends(get_current_user),
) -> CurrentUser:
    if not _has_admin_capability(current_user):
        raise PermissionDenied()
    return current_user
