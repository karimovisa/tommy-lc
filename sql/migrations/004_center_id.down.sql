-- ============================================================================
-- ROLLBACK for migration 004 — remove center_id from all business tables
-- Safe: TASK 006 (NOT NULL / FK) has NOT run yet, so nothing depends on it.
-- If you already ran TASK 006, roll that back first.
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
    execute format('alter table public.%I drop column if exists center_id', t);
  end loop;
end $$;
