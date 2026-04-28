from typing import List, Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class CurrentTenant(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    uid: UUID
    code: str
    name: str
    timezone: str
    locale: str


class CurrentUser(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    uid: UUID
    tenant: CurrentTenant
    company_id: Optional[int]
    branch_id: Optional[int]
    login_id: str
    name: str
    email: Optional[str]
    phone: Optional[str]
    user_type: str
    mfa_enabled: bool
    roles: List[str]
