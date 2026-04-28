from datetime import datetime, timezone
from typing import List, Optional
from uuid import uuid4

from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models.core import Role, User, UserRole


class UserRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def get_active_local_by_login(self, *, tenant_id: int, login_id: str) -> Optional[User]:
        statement = select(User).where(
            User.tenant_id == tenant_id,
            User.login_id == login_id,
            User.auth_provider == "LOCAL",
            User.is_active.is_(True),
            User.deleted_at.is_(None),
        )
        result = await self._session.execute(statement)
        return result.scalar_one_or_none()

    async def local_login_exists(self, *, tenant_id: int, login_id: str) -> bool:
        statement = (
            select(User.user_id)
            .where(
                User.tenant_id == tenant_id,
                User.login_id == login_id,
                User.auth_provider == "LOCAL",
                User.deleted_at.is_(None),
            )
            .limit(1)
        )
        result = await self._session.execute(statement)
        return result.scalar_one_or_none() is not None

    async def create_local_user(
        self,
        *,
        tenant_id: int,
        login_id: str,
        password_hash: str,
    ) -> User:
        now = datetime.now(timezone.utc)
        user = User(
            user_uid=uuid4(),
            tenant_id=tenant_id,
            company_id=None,
            branch_id=None,
            login_id=login_id,
            password_hash=password_hash,
            user_name=login_id,
            email=None,
            phone=None,
            user_type="ADMIN",
            auth_provider="LOCAL",
            mfa_enabled=False,
            locked_at=None,
            last_login_at=None,
            is_active=True,
            deleted_at=None,
            created_at=now,
            updated_at=now,
        )
        self._session.add(user)
        await self._session.flush()
        return user

    async def get_active_by_id(self, *, user_id: int, tenant_id: int) -> Optional[User]:
        statement = select(User).where(
            User.user_id == user_id,
            User.tenant_id == tenant_id,
            User.is_active.is_(True),
            User.deleted_at.is_(None),
        )
        result = await self._session.execute(statement)
        return result.scalar_one_or_none()

    async def get_role_codes(self, *, user_id: int, tenant_id: int) -> List[str]:
        statement = (
            select(Role.role_code)
            .join(UserRole, UserRole.role_id == Role.role_id)
            .where(
                UserRole.user_id == user_id,
                UserRole.is_active.is_(True),
                UserRole.deleted_at.is_(None),
                Role.tenant_id == tenant_id,
                Role.is_active.is_(True),
                Role.deleted_at.is_(None),
            )
            .order_by(Role.role_code)
        )
        result = await self._session.execute(statement)
        return list(result.scalars().all())

    async def mark_last_login(self, user_id: int) -> None:
        statement = (
            update(User)
            .where(User.user_id == user_id)
            .values(last_login_at=datetime.now(timezone.utc), updated_at=datetime.now(timezone.utc))
        )
        await self._session.execute(statement)
