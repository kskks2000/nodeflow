from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies.auth import get_current_user
from app.dependencies.db import get_db_session
from app.schemas.transport_order import TransportOrderCreateRequest, TransportOrderResponse
from app.schemas.user import CurrentUser
from app.services.transport_order_service import TransportOrderService

router = APIRouter()


@router.post("", response_model=TransportOrderResponse, status_code=status.HTTP_201_CREATED)
async def create_transport_order(
    request: TransportOrderCreateRequest,
    current_user: CurrentUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_db_session),
) -> TransportOrderResponse:
    service = TransportOrderService(session)
    return await service.create_manual_order(request=request, current_user=current_user)
