-- ============================================================================
-- Migration 014 — Feature Flags
-- TASK 016 of the multi-tenant migration roadmap.
--
-- Enable/disable modules per center (AI, CRM, Website, Analytics, Telegram,
-- Homework, Attendance, Exams, Payments, Messaging, Mobile...).
--
-- Model: one row per (center, feature). has_feature() defaults to TRUE when no
-- row exists (opt-out), so a center works fully unless a feature is explicitly
-- turned off. When subscriptions/plan_limits land (TASK 018), has_feature() will
-- be combined with the plan's allowance.
--
-- SAFE / ADDITIVE. Reversible via 014_feature_flags.down.sql
-- APPLY: run in the Supabase SQL editor (idempotent).
-- ============================================================================

create table if not exists public.feature_flags (
  center_id  uuid not null references public.centers(id) on delete cascade,
  feature    text not null,
  enabled    boolean not null default true,
  updated_at timestamptz not null default now(),
  primary key (center_id, feature)
);

drop trigger if exists trg_feature_flags_updated_at on public.feature_flags;
create trigger trg_feature_flags_updated_at
  before update on public.feature_flags
  for each row execute function public.set_updated_at();

-- Does the caller's center have this feature enabled? (default TRUE if unset)
create or replace function public.has_feature(p_feature text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select enabled from public.feature_flags
      where center_id = public.current_center() and feature = p_feature),
    true
  )
$$;

-- Seed Tommy (founder) with all known modules enabled.
insert into public.feature_flags (center_id, feature, enabled)
select '00000000-0000-0000-0000-000000000001', f, true
from unnest(array[
  'ai', 'crm', 'website', 'analytics', 'telegram',
  'homework', 'attendance', 'exams', 'payments', 'messaging', 'mobile'
]) as f
on conflict (center_id, feature) do nothing;

-- RLS: members read their center's flags (to show/hide UI); platform admin manages.
alter table public.feature_flags enable row level security;

drop policy if exists "read feature_flags" on public.feature_flags;
create policy "read feature_flags"
  on public.feature_flags
  for select
  to authenticated
  using (public.is_platform_admin() or center_id = public.current_center());

drop policy if exists "manage feature_flags" on public.feature_flags;
create policy "manage feature_flags"
  on public.feature_flags
  for all
  to authenticated
  using (public.is_platform_admin())
  with check (public.is_platform_admin());
