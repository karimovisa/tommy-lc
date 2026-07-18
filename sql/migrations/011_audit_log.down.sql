-- ============================================================================
-- ROLLBACK for migration 011 — Audit Logs
-- ============================================================================

do $$
declare
  t text;
  tables text[] := array[
    'students', 'profiles', 'groups', 'payments',
    'assignments', 'assignment_grades', 'admins',
    'centers', 'center_branding', 'center_settings', 'platform_admins'
  ];
begin
  foreach t in array tables loop
    execute format('drop trigger if exists trg_audit on public.%I', t);
  end loop;
end $$;

drop function if exists public.audit_trigger();
drop table if exists public.audit_log;
