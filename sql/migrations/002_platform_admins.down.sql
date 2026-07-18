-- ============================================================================
-- ROLLBACK for migration 002 — platform_admins
-- Safe: nothing else depends on these yet.
-- ============================================================================

drop policy if exists "platform admins manage centers" on public.centers;
drop policy if exists "platform admins read platform_admins" on public.platform_admins;
drop function if exists public.is_platform_admin();
drop table if exists public.platform_admins;
