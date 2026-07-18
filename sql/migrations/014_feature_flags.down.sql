-- ============================================================================
-- ROLLBACK for migration 014 — Feature Flags
-- ============================================================================

drop policy if exists "read feature_flags"   on public.feature_flags;
drop policy if exists "manage feature_flags" on public.feature_flags;
drop function if exists public.has_feature(text);
drop table if exists public.feature_flags;
