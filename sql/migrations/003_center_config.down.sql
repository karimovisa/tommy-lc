-- ============================================================================
-- ROLLBACK for migration 003 — center_branding + center_settings
-- Safe: nothing else depends on these yet.
-- ============================================================================

drop policy if exists "public read center_branding"           on public.center_branding;
drop policy if exists "platform admins manage center_branding" on public.center_branding;
drop policy if exists "platform admins manage center_settings" on public.center_settings;

drop table if exists public.center_settings;
drop table if exists public.center_branding;
