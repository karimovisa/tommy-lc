-- ============================================================================
-- ROLLBACK for migration 007 — remove center isolation overlay
-- Returns access rules to their pre-TASK-008 state.
-- ============================================================================

do $$
declare
  t text;
  tables text[] := array[
    'groups', 'profiles', 'students', 'daily_checks',
    'assignments', 'assignment_grades', 'homework', 'homework_done',
    'notifications', 'messages', 'payments', 'materials',
    'parent_links', 'login_history', 'lesson_confirms'
  ];
begin
  foreach t in array tables loop
    execute format('drop policy if exists center_isolation on public.%I', t);
  end loop;
end $$;

drop policy if exists "members read center_settings" on public.center_settings;
drop function if exists public.current_center();
