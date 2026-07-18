-- ============================================================================
-- Migration 010 — center isolation: STRICT stage
-- TASK 009 (stage 3) of the multi-tenant migration roadmap.
--
-- Removes the transition escape (`current_center() is null`) from every
-- center_isolation policy. From now on a token WITHOUT a center_id claim is
-- treated as belonging to no center and sees no business rows.
--
-- WHY NOW: the isolation gate passed, and the JWT hook is live so every fresh
-- login carries the claim.
--
-- STALE TOKENS: platform admins bypass via is_platform_admin() (table-based),
-- so the owner is never locked out. A student/teacher still holding a pre-hook
-- token is blocked until their token refreshes (Supabase auto-refresh, ~1h) or
-- they log in again. Apply at a quiet moment; a re-login fixes it instantly.
--
-- SAFE: policies only, no data. Reversible via 010_rls_strict.down.sql
-- (which restores the permissive/escape version).
--
-- APPLY:   run in the Supabase SQL editor (idempotent).
-- ROLLBACK: run 010_rls_strict.down.sql
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
          or center_id = public.current_center()
        )
        with check (
          public.is_platform_admin()
          or center_id = public.current_center()
        )
    $p$, t);
  end loop;
end $$;
