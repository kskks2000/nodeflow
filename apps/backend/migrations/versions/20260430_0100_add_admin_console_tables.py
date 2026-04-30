"""Add admin console audit, settings, and import tables.

Revision ID: 20260430_0100
Revises: 20260429_0100
Create Date: 2026-04-30 01:00:00
"""

from alembic import op


revision = "20260430_0100"
down_revision = "20260429_0100"
branch_labels = None
depends_on = None


def _execute_each(statements: tuple[str, ...]) -> None:
    for statement in statements:
        op.execute(statement)


def upgrade() -> None:
    _execute_each(
        (
            """
        CREATE TABLE IF NOT EXISTS core.audit_logs (
            audit_log_id BIGSERIAL PRIMARY KEY,
            audit_log_uid uuid NOT NULL DEFAULT gen_random_uuid(),
            tenant_id bigint NULL REFERENCES core.tenants(tenant_id),
            actor_user_id bigint NULL REFERENCES core.users(user_id),
            action_code varchar(50) NOT NULL,
            resource_type varchar(80) NOT NULL,
            resource_id varchar(120) NULL,
            resource_label varchar(240) NULL,
            before_data jsonb NOT NULL DEFAULT '{}'::jsonb,
            after_data jsonb NOT NULL DEFAULT '{}'::jsonb,
            metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
            ip_address varchar(64) NULL,
            user_agent text NULL,
            created_at timestamptz NOT NULL DEFAULT now()
        )
        """,
            """
        CREATE UNIQUE INDEX IF NOT EXISTS ux_core_audit_logs_uid
            ON core.audit_logs (audit_log_uid)
        """,
            """
        CREATE INDEX IF NOT EXISTS ix_core_audit_logs_tenant_created
            ON core.audit_logs (tenant_id, created_at DESC)
        """,
            """
        CREATE INDEX IF NOT EXISTS ix_core_audit_logs_resource
            ON core.audit_logs (resource_type, resource_id)
        """,
        )
    )
    _execute_each(
        (
            """
        CREATE TABLE IF NOT EXISTS core.system_settings (
            setting_id BIGSERIAL PRIMARY KEY,
            setting_uid uuid NOT NULL DEFAULT gen_random_uuid(),
            tenant_id bigint NOT NULL REFERENCES core.tenants(tenant_id),
            category varchar(80) NOT NULL,
            setting_key varchar(120) NOT NULL,
            setting_name varchar(200) NOT NULL,
            setting_value jsonb NOT NULL DEFAULT '{}'::jsonb,
            value_type varchar(30) NOT NULL DEFAULT 'json',
            description text NULL,
            is_secret boolean NOT NULL DEFAULT false,
            is_active boolean NOT NULL DEFAULT true,
            created_at timestamptz NOT NULL DEFAULT now(),
            created_by bigint NULL REFERENCES core.users(user_id),
            updated_at timestamptz NOT NULL DEFAULT now(),
            updated_by bigint NULL REFERENCES core.users(user_id),
            deleted_at timestamptz NULL,
            deleted_by bigint NULL REFERENCES core.users(user_id),
            CONSTRAINT ux_core_system_settings_tenant_key UNIQUE (tenant_id, setting_key)
        )
        """,
            """
        CREATE UNIQUE INDEX IF NOT EXISTS ux_core_system_settings_uid
            ON core.system_settings (setting_uid)
        """,
            """
        CREATE INDEX IF NOT EXISTS ix_core_system_settings_tenant_category
            ON core.system_settings (tenant_id, category)
            WHERE deleted_at IS NULL
        """,
        )
    )
    _execute_each(
        (
            """
        CREATE TABLE IF NOT EXISTS core.import_jobs (
            import_job_id BIGSERIAL PRIMARY KEY,
            import_job_uid uuid NOT NULL DEFAULT gen_random_uuid(),
            tenant_id bigint NOT NULL REFERENCES core.tenants(tenant_id),
            entity_key varchar(80) NOT NULL,
            file_name varchar(240) NOT NULL,
            status_code varchar(40) NOT NULL,
            total_rows integer NOT NULL DEFAULT 0,
            success_rows integer NOT NULL DEFAULT 0,
            failed_rows integer NOT NULL DEFAULT 0,
            requested_by bigint NULL REFERENCES core.users(user_id),
            result_summary jsonb NOT NULL DEFAULT '{}'::jsonb,
            created_at timestamptz NOT NULL DEFAULT now(),
            updated_at timestamptz NOT NULL DEFAULT now(),
            completed_at timestamptz NULL
        )
        """,
            """
        CREATE UNIQUE INDEX IF NOT EXISTS ux_core_import_jobs_uid
            ON core.import_jobs (import_job_uid)
        """,
            """
        CREATE INDEX IF NOT EXISTS ix_core_import_jobs_tenant_created
            ON core.import_jobs (tenant_id, created_at DESC)
        """,
        )
    )
    _execute_each(
        (
            """
        CREATE TABLE IF NOT EXISTS core.import_job_errors (
            import_job_error_id BIGSERIAL PRIMARY KEY,
            import_job_id bigint NOT NULL REFERENCES core.import_jobs(import_job_id)
                ON DELETE CASCADE,
            row_no integer NOT NULL,
            field_name varchar(120) NULL,
            error_message text NOT NULL,
            raw_data jsonb NOT NULL DEFAULT '{}'::jsonb,
            created_at timestamptz NOT NULL DEFAULT now()
        )
        """,
            """
        CREATE INDEX IF NOT EXISTS ix_core_import_job_errors_job
            ON core.import_job_errors (import_job_id, row_no)
        """,
        )
    )
    op.execute(
        """
        INSERT INTO core.permissions (
            permission_code,
            permission_name,
            resource_type,
            action_code,
            is_active
        )
        VALUES
            ('ADMIN.CONSOLE.VIEW', '관리자 콘솔 조회', 'ADMIN_CONSOLE', 'VIEW', true),
            ('ADMIN.MASTER.MANAGE', '마스터 데이터 관리', 'MASTER_DATA', 'MANAGE', true),
            ('ADMIN.CODE.MANAGE', '공통코드 관리', 'COMMON_CODE', 'MANAGE', true),
            ('ADMIN.SECURITY.MANAGE', '권한 및 사용자 관리', 'SECURITY', 'MANAGE', true),
            ('ADMIN.AUDIT.VIEW', '감사로그 조회', 'AUDIT_LOG', 'VIEW', true),
            ('ADMIN.IMPORT.MANAGE', '일괄 업로드 관리', 'IMPORT', 'MANAGE', true)
        ON CONFLICT (permission_code)
        DO UPDATE SET
            permission_name = EXCLUDED.permission_name,
            resource_type = EXCLUDED.resource_type,
            action_code = EXCLUDED.action_code,
            is_active = true,
            updated_at = now();
        """
    )


def downgrade() -> None:
    op.execute("DROP TABLE IF EXISTS core.import_job_errors;")
    op.execute("DROP TABLE IF EXISTS core.import_jobs;")
    op.execute("DROP TABLE IF EXISTS core.system_settings;")
    op.execute("DROP TABLE IF EXISTS core.audit_logs;")
