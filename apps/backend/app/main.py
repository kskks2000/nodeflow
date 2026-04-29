from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse

from app.api.router import api_router
from app.core.config import get_settings
from app.core.exception_handlers import register_exception_handlers


def create_app() -> FastAPI:
    settings = get_settings()

    app = FastAPI(
        title=settings.app_name,
        debug=settings.debug,
        version="0.1.0",
        openapi_url=f"{settings.api_v1_prefix}/openapi.json",
        docs_url="/docs",
        redoc_url="/redoc",
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_origin_regex=settings.cors_origin_regex,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    register_exception_handlers(app)
    app.include_router(api_router, prefix=settings.api_v1_prefix)

    frontend_dir = Path(__file__).resolve().parents[1] / "frontend_web"
    index_file = frontend_dir / "index.html"

    if index_file.exists():
        @app.get("/{full_path:path}", include_in_schema=False)
        async def frontend(full_path: str) -> FileResponse:
            requested_path = (frontend_dir / full_path).resolve()
            try:
                requested_path.relative_to(frontend_dir)
            except ValueError:
                return FileResponse(index_file)
            if requested_path.is_file():
                return FileResponse(requested_path)
            return FileResponse(index_file)
    else:
        @app.get("/", tags=["system"])
        async def root() -> dict[str, str]:
            return {"name": settings.app_name, "status": "ok"}

    return app


app = create_app()
