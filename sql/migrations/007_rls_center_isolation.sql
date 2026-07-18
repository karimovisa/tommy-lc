-- ============================================================================
-- Migration 007 — center isolation via RLS (PERMISSIVE stage)
-- TASK 008 of the multi-tenant migration roadmap.
--
-- Adds a RESTRICTIVE "center_isolation" policy to every client-facing business
-- table. Restrictive = ANDed with the existing permissive policies, so all
-- current rules (owns_student, teaches_group, is_admin...) still apply AND the
-- row must belong to the user's center.
--
-- PERMISSIVE STAGE (safe rollout): if the caller's token has no center_id claim
-- yet (users logged in before the JWT hook), current_center() is NULL and the
-- isolation check is SKIPPED -> nobody is locked out during the transition.
-- Platform admins always bypass. The STRICT stage (removing the NULL escape)
-- lands in TASK 009, once all tokens carry the claim and Demo LC proves isolation.
--
-- 'admins' is intentionally excluded: it has 0 client policies (read only via the
-- is_admin() security-definer function), so isolation there is a no-op.
--
-- SAFE: only policies + one helper function. No data touched. Reversible.
-- Requires TASK 006 (center_id NOT NULL) and TASK 007 (JWT hook) applied.
--
-- APPLY:   run in the Supabase SQL editor (idempotent).
-- ROLLBACK: run 007_rls_center_isolation.down.sql
-- ============================================================================

-- ---------------------------------------------------------------------------
-- current_center() — the caller's center, read from the JWT center_id claim.
-- NULL when the token has no claim (old sessions) -> used as the transition escape.
-- ---------------------------------------------------------------------------
create or replace function public.current_center()
returns uuid
language sql
stable
as $$
  select nullif(auth.jwt() ->> 'center_id', '')::uuid
$$;

-- ---------------------------------------------------------------------------
-- Restrictive center-isolation overlay on the 15 client-facing tables.
-- ---------------------------------------------------------------------------
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
          or public.current_center() is null          -- transition escape
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

-- ---------------------------------------------------------------------------
-- center_settings: let members read their own center's settings (was platform-only).
-- ---------------------------------------------------------------------------
drop policy if exists "members read center_settings" on public.center_settings;
create policy "members read center_settings"
  on public.center_settings
  for select
  to authenticated
  using (public.is_platform_admin() or center_id = public.current_center());
