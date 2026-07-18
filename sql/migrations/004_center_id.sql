-- ============================================================================
-- Migration 004 — add center_id to every business table (+ backfill Tommy)
-- TASK 005 of the multi-tenant migration roadmap.
--
-- FIRST migration that touches EXISTING production tables. Still SAFE:
--   * only ADDS a nullable column (no data deleted or modified)
--   * DEFAULT = Tommy's fixed center id -> every existing row is backfilled to
--     Tommy automatically, and any new row written by the (still center-unaware)
--     app also gets Tommy. This keeps Tommy working unchanged during transition.
--   * NOT NULL + FK come later in TASK 006 (after we confirm zero NULLs).
--   * fully reversible (drop column) via 004_center_id.down.sql
--
-- The 16 business tables were confirmed to exist live (anon REST probe).
-- Platform tables (centers/center_branding/center_settings/platform_admins)
-- are intentionally excluded — they are not tenant-owned business data.
--
-- APPLY:   run this whole file in the Supabase SQL editor (idempotent).
-- ROLLBACK: run 004_center_id.down.sql
-- ============================================================================

do $$
declare
  t     text;
  tommy constant uuid := '00000000-0000-0000-0000-000000000001';
  tables text[] := array[
    'admins', 'groups', 'profiles', 'students',
    'daily_checks', 'assignments', 'assignment_grades',
    'homework', 'homework_done', 'notifications',
    'messages', 'payments', 'materials',
    'parent_links', 'login_history', 'lesson_confirms'
  ];
begin
  foreach t in array tables loop
    -- nullable + DEFAULT Tommy: existing rows are backfilled instantly,
    -- new rows keep working. NOT NULL is deferred to TASK 006.
    execute format(
      'alter table public.%I add column if not exists center_id uuid default %L::uuid',
      t, tommy
    );
  end loop;
end $$;
