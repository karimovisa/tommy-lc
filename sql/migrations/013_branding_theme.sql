-- ============================================================================
-- Migration 013 — full theme palette in center_branding
-- TASK 012 (part 1) of the multi-tenant migration roadmap.
--
-- center_branding.brand_color holds a single primary color, but the app themes
-- light AND dark modes with different brand shades. This adds a `theme` jsonb
-- holding the complete per-mode palette so the app can drive both from the DB.
--
-- Tommy is seeded with its EXACT current hardcoded values, so applying the theme
-- engine produces ZERO visible change for Tommy.
--
-- SAFE / ADDITIVE. Reversible via 013_branding_theme.down.sql
-- APPLY: run in the Supabase SQL editor (idempotent).
-- ============================================================================

alter table public.center_branding add column if not exists theme jsonb;

update public.center_branding
set theme = '{
  "light": {"brand": "#e5242b", "brandDark": "#c41a23", "brandLight": "#fdecec"},
  "dark":  {"brand": "#ff4d54", "brandDark": "#ff6b71", "brandLight": "#2a1416"}
}'::jsonb
where center_id = '00000000-0000-0000-0000-000000000001'
  and theme is null;
