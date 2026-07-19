-- ============================================================================
-- ROLLBACK for migration 017 — Subscriptions + plan limits
-- ============================================================================

drop policy if exists "public read plans"   on public.plans;
drop policy if exists "read subscription"   on public.subscriptions;
drop policy if exists "manage subscription" on public.subscriptions;
drop function if exists public.plan_limit(text);
drop function if exists public.current_plan();
drop table if exists public.subscriptions;
drop table if exists public.plans;
