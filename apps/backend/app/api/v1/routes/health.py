from fastapi import APIRouter, Depends
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies.db import get_db_session
from app.schemas.health import DatabaseHealthResponse, HealthResponse

router = APIRouter()


@router.get("", response_model=HealthResponse)
async def health() -> HealthResponse:
    return HealthResponse(status="ok", service="nodeflow-backend")


@router.get("/db", response_model=DatabaseHealthResponse)
async def database_health(session: AsyncSession = Depends(get_db_session)) -> DatabaseHealthResponse:
    result = await session.execute(text("select current_database(), current_schema(), 1"))
    database, schema, value = result.one()
    return DatabaseHealthResponse(
        status="ok",
        database=database,
        schema_name=schema,
        probe=value,
    )

