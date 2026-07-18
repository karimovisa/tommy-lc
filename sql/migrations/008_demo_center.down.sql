-- ============================================================================
-- ROLLBACK for migration 008 — remove Demo LC test tenant and all its data.
-- Run this once the isolation gate has passed and you no longer need the demo.
-- Order matters: business rows -> config -> center.
-- ============================================================================

delete from public.groups         where center_id = '00000000-0000-0000-0000-000000000002';
delete from public.admins         where center_id = '00000000-0000-0000-0000-000000000002';
delete from public.center_settings where center_id = '00000000-0000-0000-0000-000000000002';
delete from public.center_branding where center_id = '00000000-0000-0000-0000-000000000002';
delete from public.centers        where id = '00000000-0000-0000-0000-000000000002';
