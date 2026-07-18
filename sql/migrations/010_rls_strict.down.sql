-- ============================================================================
-- ROLLBACK for migration 010 — restore the PERMISSIVE center_isolation policies
-- (re-adds the `current_center() is null` transition escape). Use if strict mode
-- unexpectedly blocks legitimate users.
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
    execute format($p$
      create policy center_isolation on public.%I
        as restrictive
        for all
        to authenticated
        using (
          public.is_platform_admin()
          or public.current_center() is null
          or center_id = public.current_center()
        )
        with check (
          public.is_platform_admin()
          or public.current_center() is null
          or center_id = public.current_center()
        )
    $p$, t);
  end loop;
end $$;
