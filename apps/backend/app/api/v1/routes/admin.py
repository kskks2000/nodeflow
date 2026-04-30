from typing import Optional

from fastapi import APIRouter, Depends, Query, Response, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies.auth import require_admin_user
from app.dependencies.db import get_db_session
from app.repositories.admin_repository import AdminRepository
from app.schemas.admin import (
    AdminAuditLogListResponse,
    AdminEntityDefinition,
    AdminEntityDefinitionList,
    AdminIdListRequest,
    AdminIdListResponse,
    AdminImportRequest,
    AdminImportResponse,
    AdminOverviewResponse,
    AdminRecordListResponse,
    AdminRecordMutationRequest,
    AdminRecordResponse,
)
from app.schemas.user import CurrentUser

router = APIRouter()


@router.get("/overview", response_model=AdminOverviewResponse)
async def overview(
    current_user: CurrentUser = Depends(require_admin_user),
    session: AsyncSession = Depends(get_db_session),
) -> AdminOverviewResponse:
    return await AdminRepository(session).overview(current_user)


@router.get("/entities", response_model=AdminEntityDefinitionList)
async def list_entities(
    _current_user: CurrentUser = Depends(require_admin_user),
    session: AsyncSession = Depends(get_db_session),
) -> AdminEntityDefinitionList:
    repository = AdminRepository(session)
    return AdminEntityDefinitionList(entities=repository.list_definitions())


@router.get("/entities/{entity_key}", response_model=AdminEntityDefinition)
async def get_entity(
    entity_key: str,
    _current_user: CurrentUser = Depends(require_admin_user),
    session: AsyncSession = Depends(get_db_session),
) -> AdminEntityDefinition:
    return AdminRepository(session).get_definition(entity_key)


@router.get("/entities/{entity_key}/records", response_model=AdminRecordListResponse)
async def list_records(
    entity_key: str,
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=25, ge=1, le=200),
    search: Optional[str] = Query(default=None),
    active_only: bool = Query(default=False),
    current_user: CurrentUser = Depends(require_admin_user),
    session: AsyncSession = Depends(get_db_session),
) -> AdminRecordListResponse:
    repository = AdminRepository(session)
    rows, total = await repository.list_records(
        entity_key=entity_key,
        current_user=current_user,
        page=page,
        page_size=page_size,
        search=search,
        active_only=active_only,
    )
    return AdminRecordListResponse(
        entity=repository.get_definition(entity_key),
        rows=rows,
        total=total,
        page=page,
        page_size=page_size,
    )


@router.post(
    "/entities/{entity_key}/records",
    response_model=AdminRecordResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_record(
    entity_key: str,
    request: AdminRecordMutationRequest,
    current_user: CurrentUser = Depends(require_admin_user),
    session: AsyncSession = Depends(get_db_session),
) -> AdminRecordResponse:
    repository = AdminRepository(session)
    record = await repository.create_record(
        entity_key=entity_key,
        data=request.data,
        current_user=current_user,
    )
    await session.commit()
    return AdminRecordResponse(entity=repository.get_definition(entity_key), record=record)


@router.get("/entities/{entity_key}/records/{record_id}", response_model=AdminRecordResponse)
async def get_record(
    entity_key: str,
    record_id: int,
    current_user: CurrentUser = Depends(require_admin_user),
    session: AsyncSession = Depends(get_db_session),
) -> AdminRecordResponse:
    repository = AdminRepository(session)
    record = await repository.get_record(
        entity_key=entity_key,
        record_id=record_id,
        current_user=current_user,
    )
    return AdminRecordResponse(entity=repository.get_definition(entity_key), record=record)


@router.put("/entities/{entity_key}/records/{record_id}", response_model=AdminRecordResponse)
async def update_record(
    entity_key: str,
    record_id: int,
    request: AdminRecordMutationRequest,
    current_user: CurrentUser = Depends(require_admin_user),
    session: AsyncSession = Depends(get_db_session),
) -> AdminRecordResponse:
    repository = AdminRepository(session)
    record = await repository.update_record(
        entity_key=entity_key,
        record_id=record_id,
        data=request.data,
        current_user=current_user,
    )
    await session.commit()
    return AdminRecordResponse(entity=repository.get_definition(entity_key), record=record)


@router.delete("/entities/{entity_key}/records/{record_id}", response_model=AdminRecordResponse)
async def delete_record(
    entity_key: str,
    record_id: int,
    current_user: CurrentUser = Depends(require_admin_user),
    session: AsyncSession = Depends(get_db_session),
) -> AdminRecordResponse:
    repository = AdminRepository(session)
    record = await repository.delete_record(
        entity_key=entity_key,
        record_id=record_id,
        current_user=current_user,
    )
    await session.commit()
    return AdminRecordResponse(entity=repository.get_definition(entity_key), record=record)


@router.get("/entities/{entity_key}/export")
async def export_records(
    entity_key: str,
    search: Optional[str] = Query(default=None),
    active_only: bool = Query(default=False),
    current_user: CurrentUser = Depends(require_admin_user),
    session: AsyncSession = Depends(get_db_session),
) -> Response:
    csv_body = await AdminRepository(session).export_csv(
        entity_key=entity_key,
        current_user=current_user,
        search=search,
        active_only=active_only,
    )
    return Response(
        content=csv_body,
        media_type="text/csv; charset=utf-8",
        headers={"Content-Disposition": f'attachment; filename="{entity_key}.csv"'},
    )


@router.post("/entities/{entity_key}/import", response_model=AdminImportResponse)
async def import_records(
    entity_key: str,
    request: AdminImportRequest,
    current_user: CurrentUser = Depends(require_admin_user),
    session: AsyncSession = Depends(get_db_session),
) -> AdminImportResponse:
    response = await AdminRepository(session).import_records(
        entity_key=entity_key,
        file_name=request.file_name,
        rows=request.rows,
        current_user=current_user,
    )
    await session.commit()
    return response


@router.get("/audit-logs", response_model=AdminAuditLogListResponse)
async def list_audit_logs(
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=25, ge=1, le=200),
    search: Optional[str] = Query(default=None),
    current_user: CurrentUser = Depends(require_admin_user),
    session: AsyncSession = Depends(get_db_session),
) -> AdminAuditLogListResponse:
    rows, total = await AdminRepository(session).list_audit_logs(
        current_user=current_user,
        page=page,
        page_size=page_size,
        search=search,
    )
    return AdminAuditLogListResponse(
        rows=rows,
        total=total,
        page=page,
        page_size=page_size,
    )


@router.get("/users/{user_id}/roles", response_model=AdminIdListResponse)
async def get_user_roles(
    user_id: int,
    current_user: CurrentUser = Depends(require_admin_user),
    session: AsyncSession = Depends(get_db_session),
) -> AdminIdListResponse:
    ids = await AdminRepository(session).get_user_roles(
        user_id=user_id,
        current_user=current_user,
    )
    return AdminIdListResponse(ids=ids)


@router.put("/users/{user_id}/roles", response_model=AdminIdListResponse)
async def set_user_roles(
    user_id: int,
    request: AdminIdListRequest,
    current_user: CurrentUser = Depends(require_admin_user),
    session: AsyncSession = Depends(get_db_session),
) -> AdminIdListResponse:
    ids = await AdminRepository(session).set_user_roles(
        user_id=user_id,
        role_ids=request.ids,
        current_user=current_user,
    )
    await session.commit()
    return AdminIdListResponse(ids=ids)


@router.get("/roles/{role_id}/permissions", response_model=AdminIdListResponse)
async def get_role_permissions(
    role_id: int,
    current_user: CurrentUser = Depends(require_admin_user),
    session: AsyncSession = Depends(get_db_session),
) -> AdminIdListResponse:
    ids = await AdminRepository(session).get_role_permissions(
        role_id=role_id,
        current_user=current_user,
    )
    return AdminIdListResponse(ids=ids)


@router.put("/roles/{role_id}/permissions", response_model=AdminIdListResponse)
async def set_role_permissions(
    role_id: int,
    request: AdminIdListRequest,
    current_user: CurrentUser = Depends(require_admin_user),
    session: AsyncSession = Depends(get_db_session),
) -> AdminIdListResponse:
    ids = await AdminRepository(session).set_role_permissions(
        role_id=role_id,
        permission_ids=request.ids,
        current_user=current_user,
    )
    await session.commit()
    return AdminIdListResponse(ids=ids)
