from datetime import datetime
from typing import Any, Dict, List, Optional

from pydantic import BaseModel, ConfigDict, Field, field_validator


class AdminEntityField(BaseModel):
    key: str
    label: str
    field_type: str = "text"
    required: bool = False
    read_only: bool = False
    list_visible: bool = True
    form_visible: bool = True
    option_entity: Optional[str] = None
    help_text: Optional[str] = None


class AdminEntityDefinition(BaseModel):
    key: str
    label: str
    group: str
    description: str
    id_field: str
    title_field: str
    fields: List[AdminEntityField]
    supports_create: bool = True
    supports_update: bool = True
    supports_delete: bool = True
    supports_import: bool = True


class AdminEntityDefinitionList(BaseModel):
    entities: List[AdminEntityDefinition]


class AdminRecordListResponse(BaseModel):
    entity: AdminEntityDefinition
    rows: List[Dict[str, Any]]
    total: int
    page: int
    page_size: int


class AdminRecordResponse(BaseModel):
    entity: AdminEntityDefinition
    record: Dict[str, Any]


class AdminRecordMutationRequest(BaseModel):
    data: Dict[str, Any] = Field(default_factory=dict)


class AdminIdListRequest(BaseModel):
    ids: List[int] = Field(default_factory=list)


class AdminIdListResponse(BaseModel):
    ids: List[int]


class AdminImportRequest(BaseModel):
    file_name: str = Field(default="manual-import.csv", max_length=240)
    rows: List[Dict[str, Any]] = Field(default_factory=list, max_length=1000)
    mode: str = Field(default="create", pattern="^(create)$")

    @field_validator("rows")
    @classmethod
    def rows_must_not_be_empty(cls, value: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        if not value:
            raise ValueError("At least one row is required.")
        return value


class AdminImportError(BaseModel):
    row_no: int
    field_name: Optional[str] = None
    error_message: str
    raw_data: Dict[str, Any]


class AdminImportResponse(BaseModel):
    import_job_id: int
    entity_key: str
    status_code: str
    total_rows: int
    success_rows: int
    failed_rows: int
    errors: List[AdminImportError]


class AdminAuditLogEntry(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    audit_log_id: int
    tenant_id: Optional[int]
    actor_user_id: Optional[int]
    actor_name: Optional[str] = None
    action_code: str
    resource_type: str
    resource_id: Optional[str]
    resource_label: Optional[str]
    before_data: Dict[str, Any]
    after_data: Dict[str, Any]
    metadata: Dict[str, Any]
    created_at: datetime


class AdminAuditLogListResponse(BaseModel):
    rows: List[AdminAuditLogEntry]
    total: int
    page: int
    page_size: int


class AdminMetric(BaseModel):
    key: str
    label: str
    value: int
    description: str


class AdminActivity(BaseModel):
    label: str
    value: str
    status: str
    created_at: Optional[datetime] = None


class AdminOverviewResponse(BaseModel):
    metrics: List[AdminMetric]
    recent_activity: List[AdminActivity]
    master_entities: List[AdminEntityDefinition]
