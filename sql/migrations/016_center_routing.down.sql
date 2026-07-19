-- ============================================================================
-- ROLLBACK for migration 016 — host -> center resolution
-- ============================================================================

drop function if exists public.get_center_theme(text);
