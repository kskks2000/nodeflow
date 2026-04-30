from __future__ import annotations

import csv
import io
import json
from dataclasses import dataclass
from datetime import date, datetime
from decimal import Decimal
from typing import Any, Dict, Iterable, List, Optional, Sequence
from uuid import UUID

from sqlalchemy import text
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import ResourceConflict, ResourceNotFound, ValidationFailed
from app.schemas.admin import (
    AdminActivity,
    AdminAuditLogEntry,
    AdminEntityDefinition,
    AdminEntityField,
    AdminImportError,
    AdminImportResponse,
    AdminMetric,
    AdminOverviewResponse,
)
from app.schemas.user import CurrentUser


@dataclass(frozen=True)
class EntityFieldConfig:
    key: str
    label: str
    field_type: str = "text"
    required: bool = False
    read_only: bool = False
    list_visible: bool = True
    form_visible: bool = True
    option_entity: Optional[str] = None
    help_text: Optional[str] = None


@dataclass(frozen=True)
class EntityConfig:
    key: str
    label: str
    group: str
    description: str
    schema: str
    table: str
    id_field: str
    title_field: str
    fields: Sequence[EntityFieldConfig]
    search_fields: Sequence[str]
    tenant_scoped: bool = True
    tenant_nullable: bool = False
    custom_tenant_filter: Optional[str] = None
    supports_create: bool = True
    supports_update: bool = True
    supports_delete: bool = True
    supports_import: bool = True

    @property
    def field_keys(self) -> List[str]:
        return [field.key for field in self.fields]

    @property
    def mutable_fields(self) -> List[str]:
        return [
            field.key
            for field in self.fields
            if not field.read_only and field.form_visible and field.key != self.id_field
        ]

    @property
    def list_fields(self) -> List[str]:
        return [field.key for field in self.fields if field.list_visible]


AUDIT_COLUMNS = {
    "created_at",
    "created_by",
    "updated_at",
    "updated_by",
    "deleted_at",
    "deleted_by",
}


ENTITY_CONFIGS: Dict[str, EntityConfig] = {}


def _field(
    key: str,
    label: str,
    field_type: str = "text",
    *,
    required: bool = False,
    read_only: bool = False,
    list_visible: bool = True,
    form_visible: bool = True,
    option_entity: Optional[str] = None,
    help_text: Optional[str] = None,
) -> EntityFieldConfig:
    return EntityFieldConfig(
        key=key,
        label=label,
        field_type=field_type,
        required=required,
        read_only=read_only,
        list_visible=list_visible,
        form_visible=form_visible,
        option_entity=option_entity,
        help_text=help_text,
    )


def _register(config: EntityConfig) -> None:
    ENTITY_CONFIGS[config.key] = config


def _register_entities() -> None:
    if ENTITY_CONFIGS:
        return

    common_audit = [
        _field("is_active", "사용", "boolean"),
        _field("created_at", "생성일", "datetime", read_only=True, form_visible=False),
        _field("created_by", "생성자", "number", read_only=True, list_visible=False, form_visible=False),
        _field("updated_at", "수정일", "datetime", read_only=True, form_visible=False),
        _field("updated_by", "수정자", "number", read_only=True, list_visible=False, form_visible=False),
        _field("deleted_at", "삭제일", "datetime", read_only=True, list_visible=False, form_visible=False),
        _field("deleted_by", "삭제자", "number", read_only=True, list_visible=False, form_visible=False),
    ]

    _register(
        EntityConfig(
            key="common_code_groups",
            label="공통코드 그룹",
            group="codes",
            description="상태, 유형, 정책 분류 등 시스템에서 공유하는 코드 묶음입니다.",
            schema="core",
            table="common_code_groups",
            id_field="code_group_id",
            title_field="group_name",
            tenant_nullable=True,
            fields=[
                _field("code_group_id", "ID", "number", read_only=True, form_visible=False),
                _field("group_code", "그룹코드", required=True),
                _field("group_name", "그룹명", required=True),
                _field("is_system", "시스템", "boolean", read_only=True),
                *common_audit,
            ],
            search_fields=["group_code", "group_name"],
        )
    )
    _register(
        EntityConfig(
            key="common_codes",
            label="공통코드",
            group="codes",
            description="공통코드 그룹에 속한 실제 코드값입니다.",
            schema="core",
            table="common_codes",
            id_field="code_id",
            title_field="code_name",
            tenant_scoped=False,
            custom_tenant_filter=(
                "EXISTS (SELECT 1 FROM core.common_code_groups g "
                "WHERE g.code_group_id = t.code_group_id "
                "AND (g.tenant_id = :tenant_id OR g.tenant_id IS NULL) "
                "AND g.deleted_at IS NULL)"
            ),
            fields=[
                _field("code_id", "ID", "number", read_only=True, form_visible=False),
                _field(
                    "code_group_id",
                    "그룹",
                    "number",
                    required=True,
                    option_entity="common_code_groups",
                ),
                _field("code", "코드", required=True),
                _field("code_name", "코드명", required=True),
                _field("sort_order", "정렬", "number"),
                _field("properties", "속성", "json", list_visible=False),
                *common_audit,
            ],
            search_fields=["code", "code_name"],
        )
    )
    _register(
        EntityConfig(
            key="companies",
            label="회사",
            group="masters",
            description="테넌트 내 운영 회사와 법인 정보를 관리합니다.",
            schema="core",
            table="companies",
            id_field="company_id",
            title_field="company_name",
            fields=[
                _field("company_id", "ID", "number", read_only=True, form_visible=False),
                _field("company_code", "회사코드", required=True),
                _field("company_name", "회사명", required=True),
                _field("company_type", "회사유형", required=True),
                _field("business_no", "사업자번호"),
                _field("phone", "전화"),
                _field("email", "이메일"),
                *common_audit,
            ],
            search_fields=["company_code", "company_name", "business_no", "phone"],
        )
    )
    _register(
        EntityConfig(
            key="branches",
            label="지점",
            group="masters",
            description="운영 지점, 센터, 영업소를 관리합니다.",
            schema="core",
            table="branches",
            id_field="branch_id",
            title_field="branch_name",
            fields=[
                _field("branch_id", "ID", "number", read_only=True, form_visible=False),
                _field("company_id", "회사", "number", required=True, option_entity="companies"),
                _field("parent_branch_id", "상위지점", "number", option_entity="branches"),
                _field("branch_code", "지점코드", required=True),
                _field("branch_name", "지점명", required=True),
                *common_audit,
            ],
            search_fields=["branch_code", "branch_name"],
        )
    )
    _register(
        EntityConfig(
            key="business_partners",
            label="거래처",
            group="masters",
            description="고객사, 운송사, 정산처의 기준 파트너입니다.",
            schema="mdm",
            table="business_partners",
            id_field="partner_id",
            title_field="partner_name",
            fields=[
                _field("partner_id", "ID", "number", read_only=True, form_visible=False),
                _field("partner_code", "거래처코드", required=True),
                _field("partner_name", "거래처명", required=True),
                _field("partner_type", "유형", required=True),
                _field("business_no", "사업자번호"),
                _field("phone", "전화"),
                _field("email", "이메일"),
                _field("payment_terms", "결제조건"),
                *common_audit,
            ],
            search_fields=["partner_code", "partner_name", "business_no", "phone"],
        )
    )
    _register(
        EntityConfig(
            key="customers",
            label="고객사",
            group="masters",
            description="화주와 청구 고객사를 관리합니다.",
            schema="mdm",
            table="customers",
            id_field="customer_id",
            title_field="customer_name",
            fields=[
                _field("customer_id", "ID", "number", read_only=True, form_visible=False),
                _field("partner_id", "거래처", "number", option_entity="business_partners"),
                _field("customer_code", "고객코드", required=True),
                _field("customer_name", "고객명", required=True),
                _field(
                    "billing_partner_id",
                    "청구처",
                    "number",
                    option_entity="business_partners",
                ),
                _field("default_service_level", "기본서비스"),
                *common_audit,
            ],
            search_fields=["customer_code", "customer_name", "default_service_level"],
        )
    )
    _register(
        EntityConfig(
            key="carriers",
            label="운송사",
            group="masters",
            description="차량과 기사 자원을 제공하는 운송사를 관리합니다.",
            schema="mdm",
            table="carriers",
            id_field="carrier_id",
            title_field="carrier_name",
            fields=[
                _field("carrier_id", "ID", "number", read_only=True, form_visible=False),
                _field("partner_id", "거래처", "number", option_entity="business_partners"),
                _field("carrier_code", "운송사코드", required=True),
                _field("carrier_name", "운송사명", required=True),
                _field(
                    "settlement_partner_id",
                    "정산처",
                    "number",
                    option_entity="business_partners",
                ),
                _field("carrier_grade", "등급"),
                _field("allow_spot", "스팟허용", "boolean"),
                *common_audit,
            ],
            search_fields=["carrier_code", "carrier_name", "carrier_grade"],
        )
    )
    _register(
        EntityConfig(
            key="drivers",
            label="기사",
            group="masters",
            description="기사 계정, 면허, 가용 상태와 자격 정보를 관리합니다.",
            schema="mdm",
            table="drivers",
            id_field="driver_id",
            title_field="driver_name",
            fields=[
                _field("driver_id", "ID", "number", read_only=True, form_visible=False),
                _field("carrier_id", "운송사", "number", option_entity="carriers"),
                _field("user_id", "사용자", "number", option_entity="users"),
                _field("driver_code", "기사코드"),
                _field("driver_name", "기사명", required=True),
                _field("phone", "전화", required=True),
                _field("license_no", "면허번호"),
                _field("license_type", "면허유형"),
                _field("license_expired_on", "면허만료일", "date"),
                _field("status_code", "상태"),
                _field("qualifications", "자격", "json", list_visible=False),
                *common_audit,
            ],
            search_fields=["driver_code", "driver_name", "phone", "status_code"],
        )
    )
    _register(
        EntityConfig(
            key="vehicles",
            label="차량",
            group="masters",
            description="차량 번호, 차종, 적재 제원과 운행 상태를 관리합니다.",
            schema="mdm",
            table="vehicles",
            id_field="vehicle_id",
            title_field="vehicle_no",
            fields=[
                _field("vehicle_id", "ID", "number", read_only=True, form_visible=False),
                _field("carrier_id", "운송사", "number", option_entity="carriers"),
                _field("vehicle_no", "차량번호", required=True),
                _field("vehicle_type", "차종", required=True),
                _field("ton_class", "톤급", "number"),
                _field("max_weight_kg", "최대중량", "number"),
                _field("max_volume_cbm", "최대CBM", "number"),
                _field("pallet_capacity", "팔레트", "number"),
                _field("has_lift", "리프트", "boolean"),
                _field("temperature_min_c", "최저온도", "number"),
                _field("temperature_max_c", "최고온도", "number"),
                _field("status_code", "상태"),
                _field("insurance_expired_on", "보험만료일", "date"),
                *common_audit,
            ],
            search_fields=["vehicle_no", "vehicle_type", "status_code"],
        )
    )
    _register(
        EntityConfig(
            key="locations",
            label="거점",
            group="masters",
            description="상차지, 하차지, 센터 등 물류 거점을 관리합니다.",
            schema="mdm",
            table="locations",
            id_field="location_id",
            title_field="location_name",
            fields=[
                _field("location_id", "ID", "number", read_only=True, form_visible=False),
                _field("location_code", "거점코드"),
                _field("location_name", "거점명", required=True),
                _field("location_type", "거점유형", required=True),
                _field("partner_id", "거래처", "number", option_entity="business_partners"),
                _field("address1", "주소", required=True),
                _field("address2", "상세주소"),
                _field("latitude", "위도", "number"),
                _field("longitude", "경도", "number"),
                _field("contact_name", "담당자"),
                _field("contact_phone", "연락처"),
                _field("operation_hours", "운영시간", "json", list_visible=False),
                _field("vehicle_restrictions", "차량제한", "json", list_visible=False),
                *common_audit,
            ],
            search_fields=["location_code", "location_name", "address1", "contact_phone"],
        )
    )
    _register(
        EntityConfig(
            key="contracts",
            label="계약",
            group="rules",
            description="고객/운송사 계약과 적용 기간을 관리합니다.",
            schema="mdm",
            table="contracts",
            id_field="contract_id",
            title_field="contract_name",
            fields=[
                _field("contract_id", "ID", "number", read_only=True, form_visible=False),
                _field("contract_no", "계약번호", required=True),
                _field("contract_type", "계약유형", required=True),
                _field("customer_id", "고객사", "number", option_entity="customers"),
                _field("carrier_id", "운송사", "number", option_entity="carriers"),
                _field("contract_name", "계약명", required=True),
                _field("effective_from", "시작일", "date", required=True),
                _field("effective_to", "종료일", "date", required=True),
                _field("currency_code", "통화"),
                _field("vat_rate", "VAT", "number"),
                _field("status_code", "상태"),
                _field("terms", "조건", "json", list_visible=False),
                *common_audit,
            ],
            search_fields=["contract_no", "contract_name", "contract_type", "status_code"],
        )
    )
    _register(
        EntityConfig(
            key="contract_rates",
            label="요율",
            group="rules",
            description="계약별 운임 요율, 공식, 할증 규칙을 관리합니다.",
            schema="mdm",
            table="contract_rates",
            id_field="contract_rate_id",
            title_field="rate_name",
            fields=[
                _field("contract_rate_id", "ID", "number", read_only=True, form_visible=False),
                _field("contract_id", "계약", "number", required=True, option_entity="contracts"),
                _field("rate_code", "요율코드", required=True),
                _field("rate_name", "요율명", required=True),
                _field("order_type", "오더유형"),
                _field("service_level", "서비스"),
                _field("origin_zone", "출발권역"),
                _field("destination_zone", "도착권역"),
                _field("vehicle_type", "차종"),
                _field("ton_class", "톤급", "number"),
                _field("rate_method", "계산방식", required=True),
                _field("base_amount", "기본금액", "number"),
                _field("unit_price", "단가", "number"),
                _field("formula", "공식", "json", list_visible=False),
                _field("surcharge_rules", "할증규칙", "json", list_visible=False),
                _field("priority", "우선순위", "number"),
                *common_audit,
            ],
            search_fields=["rate_code", "rate_name", "origin_zone", "destination_zone"],
        )
    )
    _register(
        EntityConfig(
            key="users",
            label="사용자",
            group="security",
            description="관리자, 담당자, 기사 계정을 관리합니다.",
            schema="core",
            table="users",
            id_field="user_id",
            title_field="user_name",
            fields=[
                _field("user_id", "ID", "number", read_only=True, form_visible=False),
                _field("company_id", "회사", "number", option_entity="companies"),
                _field("branch_id", "지점", "number", option_entity="branches"),
                _field("login_id", "로그인ID", required=True),
                _field("user_name", "사용자명", required=True),
                _field("email", "이메일"),
                _field("phone", "전화"),
                _field("user_type", "사용자유형", required=True),
                _field("auth_provider", "인증방식", read_only=True),
                _field("mfa_enabled", "MFA", "boolean"),
                _field("locked_at", "잠금일", "datetime", read_only=True),
                _field("last_login_at", "최근로그인", "datetime", read_only=True),
                *common_audit,
            ],
            search_fields=["login_id", "user_name", "email", "phone", "user_type"],
        )
    )
    _register(
        EntityConfig(
            key="roles",
            label="역할",
            group="security",
            description="관리 권한 묶음과 업무 역할을 관리합니다.",
            schema="core",
            table="roles",
            id_field="role_id",
            title_field="role_name",
            fields=[
                _field("role_id", "ID", "number", read_only=True, form_visible=False),
                _field("role_code", "역할코드", required=True),
                _field("role_name", "역할명", required=True),
                _field("is_system", "시스템", "boolean"),
                *common_audit,
            ],
            search_fields=["role_code", "role_name"],
        )
    )
    _register(
        EntityConfig(
            key="permissions",
            label="권한",
            group="security",
            description="리소스별 수행 가능한 행위 권한입니다.",
            schema="core",
            table="permissions",
            id_field="permission_id",
            title_field="permission_name",
            tenant_scoped=False,
            fields=[
                _field("permission_id", "ID", "number", read_only=True, form_visible=False),
                _field("permission_code", "권한코드", required=True),
                _field("permission_name", "권한명", required=True),
                _field("resource_type", "리소스", required=True),
                _field("action_code", "행위", required=True),
                *common_audit,
            ],
            search_fields=["permission_code", "permission_name", "resource_type", "action_code"],
        )
    )
    _register(
        EntityConfig(
            key="system_settings",
            label="시스템 설정",
            group="settings",
            description="테넌트별 운영 기본값, 알림, 연동 설정을 관리합니다.",
            schema="core",
            table="system_settings",
            id_field="setting_id",
            title_field="setting_name",
            fields=[
                _field("setting_id", "ID", "number", read_only=True, form_visible=False),
                _field("category", "분류", required=True),
                _field("setting_key", "설정키", required=True),
                _field("setting_name", "설정명", required=True),
                _field("setting_value", "값", "json", required=True, list_visible=False),
                _field("value_type", "값유형", required=True),
                _field("description", "설명", list_visible=False),
                _field("is_secret", "비밀값", "boolean"),
                *common_audit,
            ],
            search_fields=["category", "setting_key", "setting_name"],
        )
    )


_register_entities()


class AdminRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    def list_definitions(self) -> List[AdminEntityDefinition]:
        return [self._definition(config) for config in ENTITY_CONFIGS.values()]

    def get_definition(self, entity_key: str) -> AdminEntityDefinition:
        return self._definition(self._get_config(entity_key))

    async def overview(self, current_user: CurrentUser) -> AdminOverviewResponse:
        metrics: List[AdminMetric] = []
        metric_sources = [
            ("common_codes", "공통코드", "등록된 코드값"),
            ("customers", "고객사", "활성 고객사"),
            ("drivers", "기사", "등록 기사"),
            ("vehicles", "차량", "등록 차량"),
            ("audit_logs", "감사로그", "최근 변경 추적"),
        ]
        for key, label, description in metric_sources:
            value = await self._count_for_metric(key, current_user)
            metrics.append(
                AdminMetric(key=key, label=label, value=value, description=description)
            )

        recent_activity = []
        rows, _total = await self.list_audit_logs(
            current_user=current_user,
            page=1,
            page_size=6,
            search=None,
        )
        for row in rows:
            recent_activity.append(
                AdminActivity(
                    label=f"{row.action_code} {row.resource_type}",
                    value=row.resource_label or row.resource_id or "-",
                    status=row.actor_name or "system",
                    created_at=row.created_at,
                )
            )

        master_entities = [
            self._definition(config)
            for config in ENTITY_CONFIGS.values()
            if config.group in {"masters", "rules"}
        ]
        return AdminOverviewResponse(
            metrics=metrics,
            recent_activity=recent_activity,
            master_entities=master_entities,
        )

    async def list_records(
        self,
        *,
        entity_key: str,
        current_user: CurrentUser,
        page: int,
        page_size: int,
        search: Optional[str],
        active_only: bool,
    ) -> tuple[List[Dict[str, Any]], int]:
        config = self._get_config(entity_key)
        page = max(page, 1)
        page_size = min(max(page_size, 1), 200)
        params: Dict[str, Any] = {
            "tenant_id": current_user.tenant.id,
            "limit": page_size,
            "offset": (page - 1) * page_size,
        }
        where = self._base_where(config, active_only=active_only)
        if search:
            params["search"] = f"%{search.strip()}%"
            search_parts = [
                f"CAST(t.{field} AS TEXT) ILIKE :search"
                for field in config.search_fields
                if field in config.field_keys
            ]
            if search_parts:
                where.append("(" + " OR ".join(search_parts) + ")")

        where_sql = " AND ".join(where) if where else "TRUE"
        order_sql = self._order_sql(config)
        select_columns = ", ".join(f"t.{field}" for field in config.list_fields)

        count_result = await self._session.execute(
            text(
                f"""
                SELECT COUNT(*)
                FROM {config.schema}.{config.table} t
                WHERE {where_sql}
                """
            ),
            params,
        )
        total = int(count_result.scalar_one() or 0)

        result = await self._session.execute(
            text(
                f"""
                SELECT {select_columns}
                FROM {config.schema}.{config.table} t
                WHERE {where_sql}
                {order_sql}
                LIMIT :limit OFFSET :offset
                """
            ),
            params,
        )
        return [self._serialize_row(row) for row in result.mappings().all()], total

    async def get_record(
        self,
        *,
        entity_key: str,
        record_id: int,
        current_user: CurrentUser,
    ) -> Dict[str, Any]:
        config = self._get_config(entity_key)
        row = await self._fetch_record(config, record_id, current_user)
        if row is None:
            raise ResourceNotFound(config.label)
        return row

    async def create_record(
        self,
        *,
        entity_key: str,
        data: Dict[str, Any],
        current_user: CurrentUser,
        audit: bool = True,
    ) -> Dict[str, Any]:
        config = self._get_config(entity_key)
        if not config.supports_create:
            raise ValidationFailed(f"{config.label} does not support creation.")
        values = self._clean_mutation_values(config, data, creating=True)
        await self._prepare_special_create(config, values, current_user)

        if config.tenant_scoped and "tenant_id" not in values:
            values["tenant_id"] = current_user.tenant.id
        if "created_by" in config.field_keys:
            values["created_by"] = current_user.id
        if "updated_by" in config.field_keys:
            values["updated_by"] = current_user.id

        self._validate_required(config, values)
        if not values:
            raise ValidationFailed("No fields were provided.")

        columns = list(values.keys())
        params = self._sql_params(config, values)
        placeholders = [
            self._placeholder(config, column, f"value_{column}") for column in columns
        ]

        try:
            result = await self._session.execute(
                text(
                    f"""
                    INSERT INTO {config.schema}.{config.table}
                        ({", ".join(columns)})
                    VALUES
                        ({", ".join(placeholders)})
                    RETURNING *
                    """
                ),
                params,
            )
            row = self._serialize_row(result.mappings().one())
            if audit:
                await self._write_audit(
                    current_user=current_user,
                    action_code="CREATE",
                    resource_type=config.key,
                    resource_id=str(row[config.id_field]),
                    resource_label=str(row.get(config.title_field) or ""),
                    before_data={},
                    after_data=row,
                )
            return row
        except IntegrityError as exc:
            raise ResourceConflict("A record with the same key already exists.") from exc

    async def update_record(
        self,
        *,
        entity_key: str,
        record_id: int,
        data: Dict[str, Any],
        current_user: CurrentUser,
    ) -> Dict[str, Any]:
        config = self._get_config(entity_key)
        if not config.supports_update:
            raise ValidationFailed(f"{config.label} does not support updates.")
        before = await self.get_record(
            entity_key=entity_key,
            record_id=record_id,
            current_user=current_user,
        )
        values = self._clean_mutation_values(config, data, creating=False)
        if "updated_by" in config.field_keys:
            values["updated_by"] = current_user.id
        if not values:
            return before

        params = self._sql_params(config, values)
        params.update({"record_id": record_id, "tenant_id": current_user.tenant.id})
        assignments = [
            f"{column} = {self._placeholder(config, column, f'value_{column}')}"
            for column in values
        ]
        if "updated_at" in config.field_keys:
            assignments.append("updated_at = now()")

        try:
            result = await self._session.execute(
                text(
                    f"""
                    UPDATE {config.schema}.{config.table} t
                    SET {", ".join(assignments)}
                    WHERE t.{config.id_field} = :record_id
                      AND {" AND ".join(self._base_where(config, active_only=False))}
                    RETURNING *
                    """
                ),
                params,
            )
            row = result.mappings().one_or_none()
            if row is None:
                raise ResourceNotFound(config.label)
            after = self._serialize_row(row)
            await self._write_audit(
                current_user=current_user,
                action_code="UPDATE",
                resource_type=config.key,
                resource_id=str(record_id),
                resource_label=str(after.get(config.title_field) or ""),
                before_data=before,
                after_data=after,
            )
            return after
        except IntegrityError as exc:
            raise ResourceConflict("The update conflicts with existing data.") from exc

    async def delete_record(
        self,
        *,
        entity_key: str,
        record_id: int,
        current_user: CurrentUser,
    ) -> Dict[str, Any]:
        config = self._get_config(entity_key)
        if not config.supports_delete:
            raise ValidationFailed(f"{config.label} does not support deletion.")
        before = await self.get_record(
            entity_key=entity_key,
            record_id=record_id,
            current_user=current_user,
        )
        params = {"record_id": record_id, "tenant_id": current_user.tenant.id}

        if "deleted_at" in config.field_keys:
            assignments = ["deleted_at = now()"]
            if "deleted_by" in config.field_keys:
                assignments.append("deleted_by = :user_id")
                params["user_id"] = current_user.id
            if "updated_by" in config.field_keys:
                assignments.append("updated_by = :user_id")
                params["user_id"] = current_user.id
            if "updated_at" in config.field_keys:
                assignments.append("updated_at = now()")
            if "is_active" in config.field_keys:
                assignments.append("is_active = false")
            result = await self._session.execute(
                text(
                    f"""
                    UPDATE {config.schema}.{config.table} t
                    SET {", ".join(assignments)}
                    WHERE t.{config.id_field} = :record_id
                      AND {" AND ".join(self._base_where(config, active_only=False))}
                    RETURNING *
                    """
                ),
                params,
            )
        else:
            result = await self._session.execute(
                text(
                    f"""
                    DELETE FROM {config.schema}.{config.table} t
                    WHERE t.{config.id_field} = :record_id
                      AND {" AND ".join(self._base_where(config, active_only=False))}
                    RETURNING *
                    """
                ),
                params,
            )

        row = result.mappings().one_or_none()
        if row is None:
            raise ResourceNotFound(config.label)
        after = self._serialize_row(row)
        await self._write_audit(
            current_user=current_user,
            action_code="DELETE",
            resource_type=config.key,
            resource_id=str(record_id),
            resource_label=str(before.get(config.title_field) or ""),
            before_data=before,
            after_data=after,
        )
        return after

    async def import_records(
        self,
        *,
        entity_key: str,
        file_name: str,
        rows: List[Dict[str, Any]],
        current_user: CurrentUser,
    ) -> AdminImportResponse:
        config = self._get_config(entity_key)
        if not config.supports_import:
            raise ValidationFailed(f"{config.label} does not support import.")

        job_id = await self._create_import_job(
            entity_key=entity_key,
            file_name=file_name,
            total_rows=len(rows),
            current_user=current_user,
        )
        errors: List[AdminImportError] = []
        success_rows = 0

        for index, row in enumerate(rows, start=1):
            try:
                async with self._session.begin_nested():
                    created = await self.create_record(
                        entity_key=entity_key,
                        data=row,
                        current_user=current_user,
                        audit=False,
                    )
                    await self._write_audit(
                        current_user=current_user,
                        action_code="IMPORT_CREATE",
                        resource_type=entity_key,
                        resource_id=str(created[config.id_field]),
                        resource_label=str(created.get(config.title_field) or ""),
                        before_data={},
                        after_data=created,
                        metadata={"import_job_id": job_id, "row_no": index},
                    )
                success_rows += 1
            except Exception as exc:  # noqa: BLE001 - row-level import must continue.
                errors.append(
                    AdminImportError(
                        row_no=index,
                        field_name=None,
                        error_message=str(getattr(exc, "message", exc)),
                        raw_data=row,
                    )
                )
                await self._insert_import_error(job_id, errors[-1])

        failed_rows = len(errors)
        status_code = "COMPLETED" if failed_rows == 0 else "COMPLETED_WITH_ERRORS"
        await self._complete_import_job(
            job_id=job_id,
            status_code=status_code,
            success_rows=success_rows,
            failed_rows=failed_rows,
        )
        return AdminImportResponse(
            import_job_id=job_id,
            entity_key=entity_key,
            status_code=status_code,
            total_rows=len(rows),
            success_rows=success_rows,
            failed_rows=failed_rows,
            errors=errors,
        )

    async def export_csv(
        self,
        *,
        entity_key: str,
        current_user: CurrentUser,
        search: Optional[str],
        active_only: bool,
    ) -> str:
        rows, _total = await self.list_records(
            entity_key=entity_key,
            current_user=current_user,
            page=1,
            page_size=1000,
            search=search,
            active_only=active_only,
        )
        config = self._get_config(entity_key)
        output = io.StringIO()
        writer = csv.DictWriter(output, fieldnames=config.list_fields, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(rows)
        return output.getvalue()

    async def list_audit_logs(
        self,
        *,
        current_user: CurrentUser,
        page: int,
        page_size: int,
        search: Optional[str],
    ) -> tuple[List[AdminAuditLogEntry], int]:
        page = max(page, 1)
        page_size = min(max(page_size, 1), 200)
        params: Dict[str, Any] = {
            "tenant_id": current_user.tenant.id,
            "limit": page_size,
            "offset": (page - 1) * page_size,
        }
        where = ["l.tenant_id = :tenant_id"]
        if search:
            params["search"] = f"%{search.strip()}%"
            where.append(
                "(l.action_code ILIKE :search OR l.resource_type ILIKE :search "
                "OR l.resource_label ILIKE :search OR u.user_name ILIKE :search)"
            )
        where_sql = " AND ".join(where)
        count_result = await self._session.execute(
            text(f"SELECT COUNT(*) FROM core.audit_logs l LEFT JOIN core.users u ON u.user_id = l.actor_user_id WHERE {where_sql}"),
            params,
        )
        total = int(count_result.scalar_one() or 0)
        result = await self._session.execute(
            text(
                f"""
                SELECT
                    l.audit_log_id,
                    l.tenant_id,
                    l.actor_user_id,
                    u.user_name AS actor_name,
                    l.action_code,
                    l.resource_type,
                    l.resource_id,
                    l.resource_label,
                    l.before_data,
                    l.after_data,
                    l.metadata,
                    l.created_at
                FROM core.audit_logs l
                LEFT JOIN core.users u ON u.user_id = l.actor_user_id
                WHERE {where_sql}
                ORDER BY l.created_at DESC, l.audit_log_id DESC
                LIMIT :limit OFFSET :offset
                """
            ),
            params,
        )
        rows = [
            AdminAuditLogEntry(
                **{
                    **dict(row),
                    "before_data": self._json_dict(row["before_data"]),
                    "after_data": self._json_dict(row["after_data"]),
                    "metadata": self._json_dict(row["metadata"]),
                }
            )
            for row in result.mappings().all()
        ]
        return rows, total

    async def set_user_roles(
        self,
        *,
        user_id: int,
        role_ids: List[int],
        current_user: CurrentUser,
    ) -> List[int]:
        target = await self._session.execute(
            text(
                """
                SELECT user_id
                FROM core.users
                WHERE user_id = :user_id
                  AND tenant_id = :tenant_id
                  AND deleted_at IS NULL
                """
            ),
            {"user_id": user_id, "tenant_id": current_user.tenant.id},
        )
        if target.scalar_one_or_none() is None:
            raise ResourceNotFound("User")

        valid_role_ids = await self._valid_role_ids(role_ids, current_user.tenant.id)
        before = await self._assigned_role_ids(user_id)
        await self._session.execute(
            text(
                """
                UPDATE core.user_roles
                SET is_active = false,
                    deleted_at = now(),
                    deleted_by = :actor_id,
                    updated_at = now(),
                    updated_by = :actor_id
                WHERE user_id = :user_id
                  AND deleted_at IS NULL
                """
            ),
            {"user_id": user_id, "actor_id": current_user.id},
        )
        for role_id in valid_role_ids:
            await self._session.execute(
                text(
                    """
                    INSERT INTO core.user_roles (
                        user_id,
                        role_id,
                        granted_by,
                        granted_at,
                        is_active,
                        created_by,
                        updated_by
                    )
                    VALUES (
                        :user_id,
                        :role_id,
                        :actor_id,
                        now(),
                        true,
                        :actor_id,
                        :actor_id
                    )
                    ON CONFLICT (user_id, role_id)
                    DO UPDATE SET
                        is_active = true,
                        deleted_at = NULL,
                        deleted_by = NULL,
                        granted_by = EXCLUDED.granted_by,
                        granted_at = EXCLUDED.granted_at,
                        updated_at = now(),
                        updated_by = EXCLUDED.updated_by
                    """
                ),
                {"user_id": user_id, "role_id": role_id, "actor_id": current_user.id},
            )
        after = await self._assigned_role_ids(user_id)
        await self._write_audit(
            current_user=current_user,
            action_code="UPDATE_ROLES",
            resource_type="users",
            resource_id=str(user_id),
            resource_label=str(user_id),
            before_data={"role_ids": before},
            after_data={"role_ids": after},
        )
        return after

    async def get_user_roles(self, *, user_id: int, current_user: CurrentUser) -> List[int]:
        await self.get_record(entity_key="users", record_id=user_id, current_user=current_user)
        return await self._assigned_role_ids(user_id)

    async def set_role_permissions(
        self,
        *,
        role_id: int,
        permission_ids: List[int],
        current_user: CurrentUser,
    ) -> List[int]:
        role = await self._session.execute(
            text(
                """
                SELECT role_id
                FROM core.roles
                WHERE role_id = :role_id
                  AND tenant_id = :tenant_id
                  AND deleted_at IS NULL
                """
            ),
            {"role_id": role_id, "tenant_id": current_user.tenant.id},
        )
        if role.scalar_one_or_none() is None:
            raise ResourceNotFound("Role")

        valid_permission_ids = await self._valid_permission_ids(permission_ids)
        before = await self._assigned_permission_ids(role_id)
        await self._session.execute(
            text(
                """
                UPDATE core.role_permissions
                SET is_active = false,
                    deleted_at = now(),
                    deleted_by = :actor_id,
                    updated_at = now(),
                    updated_by = :actor_id
                WHERE role_id = :role_id
                  AND deleted_at IS NULL
                """
            ),
            {"role_id": role_id, "actor_id": current_user.id},
        )
        for permission_id in valid_permission_ids:
            await self._session.execute(
                text(
                    """
                    INSERT INTO core.role_permissions (
                        role_id,
                        permission_id,
                        is_active,
                        created_by,
                        updated_by
                    )
                    VALUES (
                        :role_id,
                        :permission_id,
                        true,
                        :actor_id,
                        :actor_id
                    )
                    ON CONFLICT (role_id, permission_id)
                    DO UPDATE SET
                        is_active = true,
                        deleted_at = NULL,
                        deleted_by = NULL,
                        updated_at = now(),
                        updated_by = EXCLUDED.updated_by
                    """
                ),
                {
                    "role_id": role_id,
                    "permission_id": permission_id,
                    "actor_id": current_user.id,
                },
            )
        after = await self._assigned_permission_ids(role_id)
        await self._write_audit(
            current_user=current_user,
            action_code="UPDATE_PERMISSIONS",
            resource_type="roles",
            resource_id=str(role_id),
            resource_label=str(role_id),
            before_data={"permission_ids": before},
            after_data={"permission_ids": after},
        )
        return after

    async def get_role_permissions(
        self,
        *,
        role_id: int,
        current_user: CurrentUser,
    ) -> List[int]:
        await self.get_record(entity_key="roles", record_id=role_id, current_user=current_user)
        return await self._assigned_permission_ids(role_id)

    def _get_config(self, entity_key: str) -> EntityConfig:
        config = ENTITY_CONFIGS.get(entity_key)
        if config is None:
            raise ResourceNotFound("Admin entity")
        return config

    def _definition(self, config: EntityConfig) -> AdminEntityDefinition:
        return AdminEntityDefinition(
            key=config.key,
            label=config.label,
            group=config.group,
            description=config.description,
            id_field=config.id_field,
            title_field=config.title_field,
            fields=[
                AdminEntityField(
                    key=field.key,
                    label=field.label,
                    field_type=field.field_type,
                    required=field.required,
                    read_only=field.read_only,
                    list_visible=field.list_visible,
                    form_visible=field.form_visible,
                    option_entity=field.option_entity,
                    help_text=field.help_text,
                )
                for field in config.fields
            ],
            supports_create=config.supports_create,
            supports_update=config.supports_update,
            supports_delete=config.supports_delete,
            supports_import=config.supports_import,
        )

    def _base_where(self, config: EntityConfig, *, active_only: bool) -> List[str]:
        where: List[str] = []
        if config.custom_tenant_filter:
            where.append(config.custom_tenant_filter)
        elif config.tenant_scoped:
            if config.tenant_nullable:
                where.append("(t.tenant_id = :tenant_id OR t.tenant_id IS NULL)")
            else:
                where.append("t.tenant_id = :tenant_id")
        if "deleted_at" in config.field_keys:
            where.append("t.deleted_at IS NULL")
        if active_only and "is_active" in config.field_keys:
            where.append("t.is_active = true")
        return where

    def _order_sql(self, config: EntityConfig) -> str:
        if "updated_at" in config.field_keys:
            return f"ORDER BY t.updated_at DESC, t.{config.id_field} DESC"
        return f"ORDER BY t.{config.id_field} DESC"

    async def _fetch_record(
        self,
        config: EntityConfig,
        record_id: int,
        current_user: CurrentUser,
    ) -> Optional[Dict[str, Any]]:
        params = {"record_id": record_id, "tenant_id": current_user.tenant.id}
        result = await self._session.execute(
            text(
                f"""
                SELECT t.*
                FROM {config.schema}.{config.table} t
                WHERE t.{config.id_field} = :record_id
                  AND {" AND ".join(self._base_where(config, active_only=False))}
                LIMIT 1
                """
            ),
            params,
        )
        row = result.mappings().one_or_none()
        return None if row is None else self._serialize_row(row)

    def _clean_mutation_values(
        self,
        config: EntityConfig,
        data: Dict[str, Any],
        *,
        creating: bool,
    ) -> Dict[str, Any]:
        mutable = set(config.mutable_fields)
        values: Dict[str, Any] = {}
        for key, value in data.items():
            if key not in mutable or key in AUDIT_COLUMNS or key == "tenant_id":
                continue
            field = next(field for field in config.fields if field.key == key)
            cleaned = self._clean_value(value, field.field_type)
            if cleaned is None and creating and field.required:
                continue
            values[key] = cleaned
        if creating and "auth_provider" in config.field_keys and config.key == "users":
            values.setdefault("auth_provider", "LOCAL")
        return values

    def _clean_value(self, value: Any, field_type: str) -> Any:
        if isinstance(value, str):
            value = value.strip()
            if value == "":
                return None
        if field_type == "boolean":
            if isinstance(value, bool):
                return value
            if isinstance(value, str):
                return value.lower() in {"true", "1", "yes", "y", "사용", "활성"}
            return bool(value) if value is not None else None
        if field_type == "number":
            if value is None:
                return None
            try:
                return Decimal(str(value))
            except Exception as exc:  # noqa: BLE001
                raise ValidationFailed(f"{value} is not a valid number.") from exc
        if field_type == "json":
            if value is None:
                return {}
            if isinstance(value, (dict, list)):
                return value
            if isinstance(value, str):
                try:
                    return json.loads(value)
                except json.JSONDecodeError as exc:
                    raise ValidationFailed("JSON field contains invalid JSON.") from exc
        return value

    def _validate_required(self, config: EntityConfig, values: Dict[str, Any]) -> None:
        missing = [
            field.label
            for field in config.fields
            if field.required and field.key not in values and not field.read_only
        ]
        if missing:
            raise ValidationFailed(f"Required fields are missing: {', '.join(missing)}")

    def _sql_params(self, config: EntityConfig, values: Dict[str, Any]) -> Dict[str, Any]:
        params: Dict[str, Any] = {}
        json_fields = {
            field.key for field in config.fields if field.field_type == "json"
        }
        for column, value in values.items():
            key = f"value_{column}"
            if column in json_fields:
                params[key] = json.dumps(self._json_safe(value), ensure_ascii=False)
            else:
                params[key] = value
        return params

    def _placeholder(self, config: EntityConfig, column: str, param_key: str) -> str:
        field = next((field for field in config.fields if field.key == column), None)
        if field and field.field_type == "json":
            return f"CAST(:{param_key} AS jsonb)"
        return f":{param_key}"

    async def _prepare_special_create(
        self,
        config: EntityConfig,
        values: Dict[str, Any],
        current_user: CurrentUser,
    ) -> None:
        if config.key == "customers" and values.get("partner_id") is None:
            values["partner_id"] = await self._create_partner(
                tenant_id=current_user.tenant.id,
                current_user_id=current_user.id,
                partner_code=str(values.get("customer_code") or ""),
                partner_name=str(values.get("customer_name") or ""),
                partner_type="CUSTOMER",
            )
        if config.key == "carriers" and values.get("partner_id") is None:
            values["partner_id"] = await self._create_partner(
                tenant_id=current_user.tenant.id,
                current_user_id=current_user.id,
                partner_code=str(values.get("carrier_code") or ""),
                partner_name=str(values.get("carrier_name") or ""),
                partner_type="CARRIER",
            )
        if config.key == "common_codes":
            group_id = values.get("code_group_id")
            if group_id is None:
                return
            result = await self._session.execute(
                text(
                    """
                    SELECT code_group_id
                    FROM core.common_code_groups
                    WHERE code_group_id = :code_group_id
                      AND (tenant_id = :tenant_id OR tenant_id IS NULL)
                      AND deleted_at IS NULL
                    """
                ),
                {"code_group_id": group_id, "tenant_id": current_user.tenant.id},
            )
            if result.scalar_one_or_none() is None:
                raise ResourceNotFound("Common code group")

    async def _create_partner(
        self,
        *,
        tenant_id: int,
        current_user_id: int,
        partner_code: str,
        partner_name: str,
        partner_type: str,
    ) -> int:
        if not partner_code or not partner_name:
            raise ValidationFailed("Partner code and name are required.")
        result = await self._session.execute(
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
                    :partner_type,
                    :user_id,
                    :user_id
                )
                RETURNING partner_id
                """
            ),
            {
                "tenant_id": tenant_id,
                "partner_code": partner_code,
                "partner_name": partner_name,
                "partner_type": partner_type,
                "user_id": current_user_id,
            },
        )
        return int(result.scalar_one())

    async def _write_audit(
        self,
        *,
        current_user: CurrentUser,
        action_code: str,
        resource_type: str,
        resource_id: Optional[str],
        resource_label: Optional[str],
        before_data: Dict[str, Any],
        after_data: Dict[str, Any],
        metadata: Optional[Dict[str, Any]] = None,
    ) -> None:
        await self._session.execute(
            text(
                """
                INSERT INTO core.audit_logs (
                    tenant_id,
                    actor_user_id,
                    action_code,
                    resource_type,
                    resource_id,
                    resource_label,
                    before_data,
                    after_data,
                    metadata
                )
                VALUES (
                    :tenant_id,
                    :actor_user_id,
                    :action_code,
                    :resource_type,
                    :resource_id,
                    :resource_label,
                    CAST(:before_data AS jsonb),
                    CAST(:after_data AS jsonb),
                    CAST(:metadata AS jsonb)
                )
                """
            ),
            {
                "tenant_id": current_user.tenant.id,
                "actor_user_id": current_user.id,
                "action_code": action_code,
                "resource_type": resource_type,
                "resource_id": resource_id,
                "resource_label": resource_label,
                "before_data": json.dumps(self._json_safe(before_data), ensure_ascii=False),
                "after_data": json.dumps(self._json_safe(after_data), ensure_ascii=False),
                "metadata": json.dumps(self._json_safe(metadata or {}), ensure_ascii=False),
            },
        )

    async def _create_import_job(
        self,
        *,
        entity_key: str,
        file_name: str,
        total_rows: int,
        current_user: CurrentUser,
    ) -> int:
        result = await self._session.execute(
            text(
                """
                INSERT INTO core.import_jobs (
                    tenant_id,
                    entity_key,
                    file_name,
                    status_code,
                    total_rows,
                    requested_by
                )
                VALUES (
                    :tenant_id,
                    :entity_key,
                    :file_name,
                    'RUNNING',
                    :total_rows,
                    :requested_by
                )
                RETURNING import_job_id
                """
            ),
            {
                "tenant_id": current_user.tenant.id,
                "entity_key": entity_key,
                "file_name": file_name,
                "total_rows": total_rows,
                "requested_by": current_user.id,
            },
        )
        return int(result.scalar_one())

    async def _insert_import_error(self, job_id: int, error: AdminImportError) -> None:
        await self._session.execute(
            text(
                """
                INSERT INTO core.import_job_errors (
                    import_job_id,
                    row_no,
                    field_name,
                    error_message,
                    raw_data
                )
                VALUES (
                    :import_job_id,
                    :row_no,
                    :field_name,
                    :error_message,
                    CAST(:raw_data AS jsonb)
                )
                """
            ),
            {
                "import_job_id": job_id,
                "row_no": error.row_no,
                "field_name": error.field_name,
                "error_message": error.error_message,
                "raw_data": json.dumps(self._json_safe(error.raw_data), ensure_ascii=False),
            },
        )

    async def _complete_import_job(
        self,
        *,
        job_id: int,
        status_code: str,
        success_rows: int,
        failed_rows: int,
    ) -> None:
        await self._session.execute(
            text(
                """
                UPDATE core.import_jobs
                SET status_code = :status_code,
                    success_rows = :success_rows,
                    failed_rows = :failed_rows,
                    completed_at = now(),
                    updated_at = now()
                WHERE import_job_id = :job_id
                """
            ),
            {
                "job_id": job_id,
                "status_code": status_code,
                "success_rows": success_rows,
                "failed_rows": failed_rows,
            },
        )

    async def _count_for_metric(self, key: str, current_user: CurrentUser) -> int:
        if key == "audit_logs":
            result = await self._session.execute(
                text("SELECT COUNT(*) FROM core.audit_logs WHERE tenant_id = :tenant_id"),
                {"tenant_id": current_user.tenant.id},
            )
            return int(result.scalar_one() or 0)
        config = self._get_config(key)
        where = self._base_where(config, active_only=True)
        result = await self._session.execute(
            text(
                f"""
                SELECT COUNT(*)
                FROM {config.schema}.{config.table} t
                WHERE {" AND ".join(where) if where else "TRUE"}
                """
            ),
            {"tenant_id": current_user.tenant.id},
        )
        return int(result.scalar_one() or 0)

    async def _assigned_role_ids(self, user_id: int) -> List[int]:
        result = await self._session.execute(
            text(
                """
                SELECT role_id
                FROM core.user_roles
                WHERE user_id = :user_id
                  AND is_active = true
                  AND deleted_at IS NULL
                ORDER BY role_id
                """
            ),
            {"user_id": user_id},
        )
        return [int(value) for value in result.scalars().all()]

    async def _assigned_permission_ids(self, role_id: int) -> List[int]:
        result = await self._session.execute(
            text(
                """
                SELECT permission_id
                FROM core.role_permissions
                WHERE role_id = :role_id
                  AND is_active = true
                  AND deleted_at IS NULL
                ORDER BY permission_id
                """
            ),
            {"role_id": role_id},
        )
        return [int(value) for value in result.scalars().all()]

    async def _valid_role_ids(self, role_ids: Iterable[int], tenant_id: int) -> List[int]:
        ids = sorted({int(role_id) for role_id in role_ids})
        if not ids:
            return []
        result = await self._session.execute(
            text(
                """
                SELECT role_id
                FROM core.roles
                WHERE tenant_id = :tenant_id
                  AND role_id = ANY(:role_ids)
                  AND is_active = true
                  AND deleted_at IS NULL
                ORDER BY role_id
                """
            ),
            {"tenant_id": tenant_id, "role_ids": ids},
        )
        return [int(value) for value in result.scalars().all()]

    async def _valid_permission_ids(self, permission_ids: Iterable[int]) -> List[int]:
        ids = sorted({int(permission_id) for permission_id in permission_ids})
        if not ids:
            return []
        result = await self._session.execute(
            text(
                """
                SELECT permission_id
                FROM core.permissions
                WHERE permission_id = ANY(:permission_ids)
                  AND is_active = true
                  AND deleted_at IS NULL
                ORDER BY permission_id
                """
            ),
            {"permission_ids": ids},
        )
        return [int(value) for value in result.scalars().all()]

    def _serialize_row(self, row: Any) -> Dict[str, Any]:
        return {key: self._json_safe(value) for key, value in dict(row).items()}

    def _json_safe(self, value: Any) -> Any:
        if isinstance(value, Decimal):
            return float(value)
        if isinstance(value, (datetime, date)):
            return value.isoformat()
        if isinstance(value, UUID):
            return str(value)
        if isinstance(value, dict):
            return {key: self._json_safe(item) for key, item in value.items()}
        if isinstance(value, list):
            return [self._json_safe(item) for item in value]
        return value

    def _json_dict(self, value: Any) -> Dict[str, Any]:
        if isinstance(value, dict):
            return value
        if isinstance(value, str):
            try:
                decoded = json.loads(value)
                if isinstance(decoded, dict):
                    return decoded
            except json.JSONDecodeError:
                return {}
        return {}
