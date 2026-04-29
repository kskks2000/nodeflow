"""Synchronize generated ids for TMS workflow tables.

Revision ID: 20260429_0100
Revises:
Create Date: 2026-04-29 01:00:00
"""

from alembic import op


revision = "20260429_0100"
down_revision = None
branch_labels = None
depends_on = None


ID_COLUMNS = (
    ("mdm", "business_partners", "partner_id"),
    ("mdm", "customers", "customer_id"),
    ("ord", "orders", "order_id"),
    ("ord", "order_stops", "order_stop_id"),
    ("ord", "order_items", "order_item_id"),
    ("ord", "order_status_history", "order_status_history_id"),
    ("plan", "transport_plans", "transport_plan_id"),
    ("plan", "plan_orders", "plan_order_id"),
    ("plan", "plan_stops", "plan_stop_id"),
    ("dsp", "assignments", "assignment_id"),
    ("dsp", "assignment_candidates", "assignment_candidate_id"),
    ("dsp", "dispatches", "dispatch_id"),
    ("dsp", "dispatch_events", "dispatch_event_id"),
)


def upgrade() -> None:
    for schema_name, table_name, column_name in ID_COLUMNS:
        op.execute(
            f"""
            DO $$
            DECLARE
                sequence_name text;
                next_value bigint;
            BEGIN
                SELECT pg_get_serial_sequence('"{schema_name}"."{table_name}"', '{column_name}')
                INTO sequence_name;

                IF sequence_name IS NOT NULL THEN
                    EXECUTE format(
                        'SELECT COALESCE(MAX(%I), 0) + 1 FROM %I.%I',
                        '{column_name}',
                        '{schema_name}',
                        '{table_name}'
                    )
                    INTO next_value;

                    EXECUTE format(
                        'SELECT setval(%L::regclass, %s, false)',
                        sequence_name,
                        GREATEST(next_value, 1)
                    );
                END IF;
            END $$;
            """
        )


def downgrade() -> None:
    pass
