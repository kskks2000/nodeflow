from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.repositories.transport_order_repository import TransportOrderRepository
from app.schemas.transport_order import TransportOrderCreateRequest, TransportOrderResponse
from app.schemas.user import CurrentUser


class TransportOrderService:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session
        self._repository = TransportOrderRepository(session)

    async def create_manual_order(
        self,
        *,
        request: TransportOrderCreateRequest,
        current_user: CurrentUser,
    ) -> TransportOrderResponse:
        try:
            response = await self._repository.create_manual_order(
                request=request,
                current_user=current_user,
            )
            await self._session.commit()
            return response
        except IntegrityError:
            await self._session.rollback()
            raise
