-- ============================================================================
-- ROLLBACK for migration 005 — drop FK, index, and NOT NULL on center_id
-- Returns tables to their post-TASK-005 state (nullable center_id, default Tommy).
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
    execute format('alter table public.%I drop constraint if exists %I', t, format('fk_%s_center', t));
    execute format('drop index if exists public.%I', format('idx_%s_center_id', t));
    execute format('alter table public.%I alter column center_id drop not null', t);
  end loop;
end $$;
