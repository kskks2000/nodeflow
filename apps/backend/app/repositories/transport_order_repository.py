from datetime import date, datetime, timezone
from typing import Optional
from uuid import uuid4

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.transport_order import (
    TransportOrderCreateRequest,
    TransportOrderResponse,
    TransportOrderStopRequest,
)
from app.schemas.user import CurrentUser


class TransportOrderRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def create_manual_order(
        self,
        *,
        request: TransportOrderCreateRequest,
        current_user: CurrentUser,
    ) -> TransportOrderResponse:
        customer_id, customer_name = await self._get_or_create_customer(
            tenant_id=current_user.tenant.id,
            user_id=current_user.id,
            customer_name=request.customer_name,
            customer_code=request.customer_code,
        )

        now = datetime.now(timezone.utc)
        status_code = "CONFIRMED" if request.confirm else "DRAFT"
        accepted_by = current_user.id if request.confirm else None
        accepted_at = now if request.confirm else None
        order_no = request.order_no or self._generate_order_no(now)
        order_date = request.order_date or date.today()

        order_row = await self._session.execute(
            text(
                """
                INSERT INTO ord.orders (
                    tenant_id,
                    order_no,
                    customer_id,
                    customer_order_no,
                    order_type,
                    service_level,
                    status_code,
                    order_date,
                    requested_pickup_at,
                    requested_delivery_at,
                    required_vehicle_type,
                    required_ton_class,
                    temperature_type,
                    is_exclusive,
                    is_emergency,
                    total_qty,
                    total_weight_kg,
                    total_volume_cbm,
                    total_pallets,
                    special_instructions,
                    created_by,
                    updated_by,
                    accepted_by,
                    accepted_at
                )
                VALUES (
                    :tenant_id,
                    :order_no,
                    :customer_id,
                    :customer_order_no,
                    :order_type,
                    :service_level,
                    :status_code,
                    :order_date,
                    :requested_pickup_at,
                    :requested_delivery_at,
                    :required_vehicle_type,
                    :required_ton_class,
                    :temperature_type,
                    :is_exclusive,
                    :is_emergency,
                    :total_qty,
                    :total_weight_kg,
                    :total_volume_cbm,
                    :total_pallets,
                    :special_instructions,
                    :user_id,
                    :user_id,
                    :accepted_by,
                    :accepted_at
                )
                RETURNING
                    order_id,
                    order_no,
                    customer_id,
                    status_code,
                    order_date,
                    requested_pickup_at,
                    requested_delivery_at,
                    created_at,
                    accepted_at
                """
            ),
            {
                "tenant_id": current_user.tenant.id,
                "order_no": order_no,
                "customer_id": customer_id,
                "customer_order_no": request.customer_order_no,
                "order_type": request.order_type or "ONE_WAY",
                "service_level": request.service_level,
                "status_code": status_code,
                "order_date": order_date,
                "requested_pickup_at": request.requested_pickup_at,
                "requested_delivery_at": request.requested_delivery_at,
                "required_vehicle_type": request.required_vehicle_type,
                "required_ton_class": request.required_ton_class,
                "temperature_type": request.temperature_type,
                "is_exclusive": request.is_exclusive,
                "is_emergency": request.is_emergency,
                "total_qty": request.total_qty,
                "total_weight_kg": request.total_weight_kg,
                "total_volume_cbm": request.total_volume_cbm,
                "total_pallets": request.total_pallets,
                "special_instructions": request.special_instructions,
                "user_id": current_user.id,
                "accepted_by": accepted_by,
                "accepted_at": accepted_at,
            },
        )
        order = order_row.mappings().one()
        order_id = order["order_id"]

        await self._insert_stop(
            tenant_id=current_user.tenant.id,
            user_id=current_user.id,
            order_id=order_id,
            stop_seq=1,
            stop_type="PICKUP",
            request=request.pickup,
        )
        await self._insert_stop(
            tenant_id=current_user.tenant.id,
            user_id=current_user.id,
            order_id=order_id,
            stop_seq=2,
            stop_type="DELIVERY",
            request=request.delivery,
        )
        await self._insert_item(
            tenant_id=current_user.tenant.id,
            user_id=current_user.id,
            order_id=order_id,
            request=request,
        )
        await self._insert_status_history(
            tenant_id=current_user.tenant.id,
            user_id=current_user.id,
            order_id=order_id,
            status_code=status_code,
        )

        return TransportOrderResponse(
            order_id=order["order_id"],
            order_no=order["order_no"],
            customer_id=order["customer_id"],
            customer_name=customer_name,
            status_code=order["status_code"],
            order_date=order["order_date"],
            requested_pickup_at=order["requested_pickup_at"],
            requested_delivery_at=order["requested_delivery_at"],
            created_at=order["created_at"],
            accepted_at=order["accepted_at"],
        )

    async def _get_or_create_customer(
        self,
        *,
        tenant_id: int,
        user_id: int,
        customer_name: str,
        customer_code: Optional[str],
    ) -> tuple[int, str]:
        if customer_code:
            result = await self._session.execute(
                text(
                    """
                    SELECT customer_id, customer_name
                    FROM mdm.customers
                    WHERE tenant_id = :tenant_id
                      AND customer_code = :customer_code
                      AND deleted_at IS NULL
                    LIMIT 1
                    """
                ),
                {"tenant_id": tenant_id, "customer_code": customer_code},
            )
        else:
            result = await self._session.execute(
                text(
                    """
                    SELECT customer_id, customer_name
                    FROM mdm.customers
                    WHERE tenant_id = :tenant_id
                      AND lower(customer_name) = lower(:customer_name)
                      AND deleted_at IS NULL
                    LIMIT 1
                    """
                ),
                {"tenant_id": tenant_id, "customer_name": customer_name},
            )

        existing = result.mappings().one_or_none()
        if existing is not None:
            return existing["customer_id"], existing["customer_name"]

        generated_code = customer_code or f"CUST-{uuid4().hex[:8].upper()}"
        partner_result = await self._session.execute(
            text(
                """
                INSERT INTO mdm.business_partners (
                    tenant_id,
                    partner_code,
                    partner_name,
                    partner_type,
                    created_by,
                    updated_by
                )
                VALUES (
                    :tenant_id,
                    :partner_code,
                    :partner_name,
                    'CUSTOMER',
                    :user_id,
                    :user_id
                )
                RETURNING partner_id
                """
            ),
            {
                "tenant_id": tenant_id,
                "partner_code": generated_code,
                "partner_name": customer_name,
                "user_id": user_id,
            },
        )
        partner_id = partner_result.scalar_one()

        customer_result = await self._session.execute(
            text(
                """
                INSERT INTO mdm.customers (
                    tenant_id,
                    partner_id,
                    customer_code,
                    customer_name,
                    created_by,
                    updated_by
                )
                VALUES (
                    :tenant_id,
                    :partner_id,
                    :customer_code,
                    :customer_name,
                    :user_id,
                    :user_id
                )
                RETURNING customer_id, customer_name
                """
            ),
            {
                "tenant_id": tenant_id,
                "partner_id": partner_id,
                "customer_code": generated_code,
                "customer_name": customer_name,
                "user_id": user_id,
            },
        )
        customer = customer_result.mappings().one()
        return customer["customer_id"], customer["customer_name"]

    async def _insert_stop(
        self,
        *,
        tenant_id: int,
        user_id: int,
        order_id: int,
        stop_seq: int,
        stop_type: str,
        request: TransportOrderStopRequest,
    ) -> None:
        await self._session.execute(
            text(
                """
                INSERT INTO ord.order_stops (
                    tenant_id,
                    order_id,
                    stop_seq,
                    stop_type,
                    location_name,
                    address1,
                    address2,
                    requested_arrival_from,
                    requested_arrival_to,
                    contact_name,
                    contact_phone,
                    work_note,
                    created_by,
                    updated_by
                )
                VALUES (
                    :tenant_id,
                    :order_id,
                    :stop_seq,
                    :stop_type,
                    :location_name,
                    :address1,
                    :address2,
                    :requested_arrival_from,
                    :requested_arrival_to,
                    :contact_name,
                    :contact_phone,
                    :work_note,
                    :user_id,
                    :user_id
                )
                """
            ),
            {
                "tenant_id": tenant_id,
                "order_id": order_id,
                "stop_seq": stop_seq,
                "stop_type": stop_type,
                "location_name": request.location_name,
                "address1": request.address1,
                "address2": request.address2,
                "requested_arrival_from": request.requested_arrival_from,
                "requested_arrival_to": request.requested_arrival_to,
                "contact_name": request.contact_name,
                "contact_phone": request.contact_phone,
                "work_note": request.work_note,
                "user_id": user_id,
            },
        )

    async def _insert_item(
        self,
        *,
        tenant_id: int,
        user_id: int,
        order_id: int,
        request: TransportOrderCreateRequest,
    ) -> None:
        await self._session.execute(
            text(
                """
                INSERT INTO ord.order_items (
                    tenant_id,
                    order_id,
                    item_seq,
                    item_name,
                    package_type,
                    qty,
                    weight_kg,
                    volume_cbm,
                    pallets,
                    temperature_type,
                    is_hazardous,
                    handling_note,
                    created_by,
                    updated_by
                )
                VALUES (
                    :tenant_id,
                    :order_id,
                    1,
                    :item_name,
                    :package_type,
                    :qty,
                    :weight_kg,
                    :volume_cbm,
                    :pallets,
                    :temperature_type,
                    :is_hazardous,
                    :handling_note,
                    :user_id,
                    :user_id
                )
                """
            ),
            {
                "tenant_id": tenant_id,
                "order_id": order_id,
                "item_name": request.item.item_name,
                "package_type": request.item.package_type,
                "qty": request.total_qty,
                "weight_kg": request.total_weight_kg,
                "volume_cbm": request.total_volume_cbm,
                "pallets": request.total_pallets,
                "temperature_type": request.temperature_type or request.item.temperature_type,
                "is_hazardous": request.item.is_hazardous,
                "handling_note": request.item.handling_note,
                "user_id": user_id,
            },
        )

    async def _insert_status_history(
        self,
        *,
        tenant_id: int,
        user_id: int,
        order_id: int,
        status_code: str,
    ) -> None:
        await self._session.execute(
            text(
                """
                INSERT INTO ord.order_status_history (
                    tenant_id,
                    order_id,
                    to_status_code,
                    reason_text,
                    changed_by,
                    created_by,
                    updated_by
                )
                VALUES (
                    :tenant_id,
                    :order_id,
                    :status_code,
                    'Manual order registration',
                    :user_id,
                    :user_id,
                    :user_id
                )
                """
            ),
            {
                "tenant_id": tenant_id,
                "order_id": order_id,
                "status_code": status_code,
                "user_id": user_id,
            },
        )

    def _generate_order_no(self, now: datetime) -> str:
        return f"ORD{now.strftime('%Y%m%d%H%M%S%f')[:-3]}"
