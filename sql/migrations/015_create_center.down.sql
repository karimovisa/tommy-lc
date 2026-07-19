-- ============================================================================
-- ROLLBACK for migration 015 — atomic center provisioning
-- ============================================================================

drop function if exists public.create_center(text,text,text,text,text,text,text,text,text,text);
