from datetime import datetime, timezone
from typing import Optional
from uuid import uuid4

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models.core import Tenant


class TenantRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def get_active_by_code(self, tenant_code: str) -> Optional[Tenant]:
        statement = select(Tenant).where(
            func.upper(Tenant.tenant_code) == tenant_code.upper(),
            Tenant.is_active.is_(True),
            Tenant.deleted_at.is_(None),
        )
        result = await self._session.execute(statement)
        return result.scalar_one_or_none()

    async def get_active_by_id(self, tenant_id: int) -> Optional[Tenant]:
        statement = select(Tenant).where(
            Tenant.tenant_id == tenant_id,
            Tenant.is_active.is_(True),
            Tenant.deleted_at.is_(None),
        )
        result = await self._session.execute(statement)
        return result.scalar_one_or_none()

    async def create_basic(self, tenant_code: str) -> Tenant:
        now = datetime.now(timezone.utc)
        tenant = Tenant(
            tenant_uid=uuid4(),
            tenant_code=tenant_code,
            tenant_name=tenant_code,
            timezone="Asia/Seoul",
            locale="ko-KR",
            is_active=True,
            created_at=now,
            updated_at=now,
            deleted_at=None,
        )
        self._session.add(tenant)
        await self._session.flush()
        return tenant
