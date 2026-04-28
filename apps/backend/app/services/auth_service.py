from datetime import timedelta

from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import get_settings
from app.core.exceptions import AccountLocked, AuthenticationFailed, TokenInvalid, UserAlreadyExists
from app.core.security import create_token, decode_token, hash_password, verify_password
from app.repositories.tenant_repository import TenantRepository
from app.repositories.user_repository import UserRepository
from app.schemas.auth import LoginRequest, RegisterRequest, TokenResponse
from app.schemas.user import CurrentTenant, CurrentUser


class AuthService:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session
        self._tenant_repository = TenantRepository(session)
        self._user_repository = UserRepository(session)

    async def login(self, request: LoginRequest) -> TokenResponse:
        tenant = await self._tenant_repository.get_active_by_code(request.company_code)
        if tenant is None:
            raise AuthenticationFailed()

        user = await self._user_repository.get_active_local_by_login(
            tenant_id=tenant.tenant_id,
            login_id=request.login_id,
        )
        if user is None:
            raise AuthenticationFailed()

        if user.locked_at is not None:
            raise AccountLocked()

        if not verify_password(request.password, user.password_hash):
            raise AuthenticationFailed()

        response = await self._build_token_response(user=user, tenant=tenant)
        await self._user_repository.mark_last_login(user.user_id)
        await self._session.commit()

        return response

    async def register(self, request: RegisterRequest) -> TokenResponse:
        try:
            tenant = await self._tenant_repository.get_active_by_code(request.company_code)
            if tenant is None:
                tenant = await self._tenant_repository.create_basic(request.company_code)

            if await self._user_repository.local_login_exists(
                tenant_id=tenant.tenant_id,
                login_id=request.login_id,
            ):
                raise UserAlreadyExists()

            user = await self._user_repository.create_local_user(
                tenant_id=tenant.tenant_id,
                login_id=request.login_id,
                password_hash=hash_password(request.password),
            )
            response = await self._build_token_response(user=user, tenant=tenant)
            await self._session.commit()
            return response
        except IntegrityError as exc:
            await self._session.rollback()
            raise UserAlreadyExists() from exc

    async def refresh(self, refresh_token: str) -> TokenResponse:
        payload = decode_token(refresh_token)
        if payload.get("typ") != "refresh":
            raise TokenInvalid()

        try:
            user_id = int(payload["sub"])
            tenant_id = int(payload["tenant_id"])
        except (KeyError, TypeError, ValueError) as exc:
            raise TokenInvalid() from exc

        tenant = await self._tenant_repository.get_active_by_id(tenant_id)
        user = await self._user_repository.get_active_by_id(user_id=user_id, tenant_id=tenant_id)
        if tenant is None or user is None:
            raise TokenInvalid()
        if user.locked_at is not None:
            raise AccountLocked()

        return await self._build_token_response(user=user, tenant=tenant)

    async def _build_token_response(self, *, user, tenant) -> TokenResponse:
        settings = get_settings()
        roles = await self._user_repository.get_role_codes(
            user_id=user.user_id,
            tenant_id=tenant.tenant_id,
        )

        tenant_payload = CurrentTenant(
            id=tenant.tenant_id,
            uid=tenant.tenant_uid,
            code=tenant.tenant_code,
            name=tenant.tenant_name,
            timezone=tenant.timezone,
            locale=tenant.locale,
        )
        user_payload = CurrentUser(
            id=user.user_id,
            uid=user.user_uid,
            tenant=tenant_payload,
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

        token_claims = {
            "tenant_id": tenant.tenant_id,
            "tenant_code": tenant.tenant_code,
            "login_id": user.login_id,
            "roles": roles,
        }
        access_delta = timedelta(minutes=settings.access_token_minutes)
        refresh_delta = timedelta(days=settings.refresh_token_days)

        return TokenResponse(
            access_token=create_token(
                subject=str(user.user_id),
                token_type="access",
                expires_delta=access_delta,
                claims=token_claims,
            ),
            refresh_token=create_token(
                subject=str(user.user_id),
                token_type="refresh",
                expires_delta=refresh_delta,
                claims={"tenant_id": tenant.tenant_id},
            ),
            expires_in=int(access_delta.total_seconds()),
            user=user_payload,
            tenant=tenant_payload,
        )
