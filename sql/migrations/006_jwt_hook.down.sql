-- ============================================================================
-- ROLLBACK for migration 006 — Custom Access Token Hook
-- IMPORTANT: first DISABLE the hook in the Dashboard
--   (Authentication -> Hooks -> Custom Access Token -> disable),
-- otherwise auth will reference a missing function. Then run this.
-- ============================================================================

drop function if exists public.custom_access_token_hook(jsonb);
