-- ============================================================================
-- ROLLBACK for migration 013 — remove theme palette column
-- ============================================================================

alter table public.center_branding drop column if exists theme;
