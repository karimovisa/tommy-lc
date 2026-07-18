-- ============================================================================
-- Migration 005 — lock center_id: NOT NULL + FK + index
-- TASK 006 of the multi-tenant migration roadmap.
--
-- Now that every business row has center_id = Tommy (TASK 005, verified 0 NULLs),
-- we enforce integrity:
--   * NOT NULL   -> a business row can never be tenant-less
--   * FK -> centers(id) (ON DELETE default = RESTRICT: a center with data
--                            cannot be accidentally deleted)
--   * index on center_id -> fast center-scoped RLS filtering (used from TASK 008)
--
-- The column KEEPS its DEFAULT = Tommy for now, so the still-center-unaware app
-- keeps inserting valid rows. The default is dropped later, once the app sets
-- center_id explicitly and JWT-based RLS enforces it.
--
-- SAFE: additive integrity only; no data changed. Reversible via down file.
-- Requires TASK 005 (004_center_id.sql) applied first.
--
-- APPLY:   run in the Supabase SQL editor (idempotent).
-- ROLLBACK: run 005_center_id_constraints.down.sql
-- ============================================================================

do $$
declare
  t text;
  tables text[] := array[
    'admins', 'groups', 'profiles', 'students',
    'daily_checks', 'assignments', 'assignment_grades',
    'homework', 'homework_done', 'notifications',
    'messages', 'payments', 'materials',
    'parent_links', 'login_history', 'lesson_confirms'
  ];
begin
  foreach t in array tables loop
    -- 1) NOT NULL (idempotent: no-op if already set)
    execute format('alter table public.%I alter column center_id set not null', t);

    -- 2) FK -> centers(id), guarded for idempotency
    if not exists (
      select 1 from pg_constraint
      where conname = format('fk_%s_center', t)
        and conrelid = format('public.%I', t)::regclass
    ) then
      execute format(
        'alter table public.%I add constraint %I foreign key (center_id) references public.centers(id)',
        t, format('fk_%s_center', t)
      );
    end if;

    -- 3) index for center-scoped queries / RLS
    execute format(
      'create index if not exists %I on public.%I(center_id)',
      format('idx_%s_center_id', t), t
    );
  end loop;
end $$;
