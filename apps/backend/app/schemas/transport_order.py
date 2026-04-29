from datetime import date, datetime
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field, field_validator


class TransportOrderStopRequest(BaseModel):
    location_name: str = Field(min_length=1, max_length=200)
    address1: str = Field(min_length=1, max_length=500)
    address2: Optional[str] = Field(default=None, max_length=500)
    contact_name: Optional[str] = Field(default=None, max_length=100)
    contact_phone: Optional[str] = Field(default=None, max_length=50)
    requested_arrival_from: Optional[datetime] = None
    requested_arrival_to: Optional[datetime] = None
    work_note: Optional[str] = None

    @field_validator("location_name", "address1", "address2", "contact_name", "contact_phone")
    @classmethod
    def strip_optional_text(cls, value: Optional[str]) -> Optional[str]:
        if value is None:
            return None
        stripped = value.strip()
        return stripped or None


class TransportOrderItemRequest(BaseModel):
    item_name: str = Field(default="일반화물", min_length=1, max_length=200)
    package_type: Optional[str] = Field(default=None, max_length=50)
    qty: Decimal = Field(default=Decimal("1"), ge=0)
    weight_kg: Decimal = Field(default=Decimal("0"), ge=0)
    volume_cbm: Decimal = Field(default=Decimal("0"), ge=0)
    pallets: Decimal = Field(default=Decimal("0"), ge=0)
    temperature_type: Optional[str] = Field(default=None, max_length=30)
    is_hazardous: bool = False
    handling_note: Optional[str] = None

    @field_validator("item_name", "package_type", "temperature_type")
    @classmethod
    def strip_optional_text(cls, value: Optional[str]) -> Optional[str]:
        if value is None:
            return None
        stripped = value.strip()
        return stripped or None


class TransportOrderCreateRequest(BaseModel):
    order_no: Optional[str] = Field(default=None, max_length=50)
    customer_name: str = Field(min_length=1, max_length=200)
    customer_code: Optional[str] = Field(default=None, max_length=50)
    customer_order_no: Optional[str] = Field(default=None, max_length=100)
    order_type: str = Field(default="ONE_WAY", max_length=30)
    service_level: Optional[str] = Field(default="STANDARD", max_length=30)
    confirm: bool = False
    order_date: Optional[date] = None
    requested_pickup_at: Optional[datetime] = None
    requested_delivery_at: Optional[datetime] = None
    required_vehicle_type: Optional[str] = Field(default=None, max_length=30)
    required_ton_class: Optional[Decimal] = Field(default=None, ge=0)
    temperature_type: Optional[str] = Field(default=None, max_length=30)
    is_exclusive: bool = False
    is_emergency: bool = False
    total_qty: Decimal = Field(default=Decimal("1"), ge=0)
    total_weight_kg: Decimal = Field(default=Decimal("0"), ge=0)
    total_volume_cbm: Decimal = Field(default=Decimal("0"), ge=0)
    total_pallets: Decimal = Field(default=Decimal("0"), ge=0)
    special_instructions: Optional[str] = None
    pickup: TransportOrderStopRequest
    delivery: TransportOrderStopRequest
    item: TransportOrderItemRequest = Field(default_factory=TransportOrderItemRequest)

    @field_validator(
        "order_no",
        "customer_name",
        "customer_code",
        "customer_order_no",
        "order_type",
        "service_level",
        "required_vehicle_type",
        "temperature_type",
    )
    @classmethod
    def strip_text(cls, value: Optional[str]) -> Optional[str]:
        if value is None:
            return None
        stripped = value.strip()
        return stripped or None


class TransportOrderResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    order_id: int
    order_no: str
    customer_id: int
    customer_name: str
    status_code: str
    order_date: date
    requested_pickup_at: Optional[datetime]
    requested_delivery_at: Optional[datetime]
    created_at: datetime
    accepted_at: Optional[datetime]
