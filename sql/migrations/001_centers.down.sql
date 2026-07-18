-- ============================================================================
-- ROLLBACK for migration 001 — centers
-- Run only if you need to fully undo TASK 002. Safe: nothing else depends on
-- centers yet (center_id columns arrive later in TASK 005).
-- ============================================================================

drop table if exists public.centers cascade;

-- set_updated_at() is introduced by 001; drop it too on a full rollback.
-- (Re-created by later migrations via "create or replace" if needed.)
drop function if exists public.set_updated_at();
