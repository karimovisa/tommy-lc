-- ============================================================================
-- Migration 017 — Subscriptions + plan limits
-- TASK 018 of the multi-tenant migration roadmap.
--
-- Plans (Starter / Professional / Enterprise / Founder) with jsonb limits, and
-- one subscription per center. Tommy = Founder / Unlimited / active / no expiry,
-- so Tommy is never limited. Expiry/suspension is stored here; ENFORCEMENT
-- (read-only when past_due/suspended) is a later, opt-in step — no data is ever
-- deleted.
--
-- SAFE / ADDITIVE. Reversible via 017_subscriptions.down.sql
-- APPLY: run in the Supabase SQL editor (idempotent).
-- ============================================================================

-- ---------------------------------------------------------------------------
-- plans — the public plan catalog. limits: null value = unlimited.
-- ---------------------------------------------------------------------------
create table if not exists public.plans (
  code          text primary key,
  name          text not null,
  price_monthly integer not null default 0,
  limits        jsonb not null default '{}'::jsonb,   -- {"students":100,"groups":10,"teachers":5}
  sort          integer not null default 0
);

insert into public.plans (code, name, price_monthly, limits, sort) values
  ('founder',      'Founder',      0, '{"students": null, "groups": null, "teachers": null}', 0),
  ('starter',      'Starter',      0, '{"students": 100,  "groups": 10,   "teachers": 5}',    1),
  ('professional', 'Professional', 0, '{"students": 500,  "groups": 50,   "teachers": 25}',   2),
  ('enterprise',   'Enterprise',   0, '{"students": null, "groups": null, "teachers": null}', 3)
on conflict (code) do nothing;

-- ---------------------------------------------------------------------------
-- subscriptions — one per center.
-- ---------------------------------------------------------------------------
create table if not exists public.subscriptions (
  id                 uuid primary key default gen_random_uuid(),
  center_id          uuid not null unique references public.centers(id) on delete cascade,
  plan_code          text not null references public.plans(code),
  status             text not null default 'active'
                       check (status in ('active','trialing','past_due','suspended','canceled')),
  started_at         timestamptz not null default now(),
  current_period_end timestamptz,                     -- null = no expiry (founder)
  updated_at         timestamptz not null default now()
);

drop trigger if exists trg_subscriptions_updated_at on public.subscriptions;
create trigger trg_subscriptions_updated_at
  before update on public.subscriptions
  for each row execute function public.set_updated_at();

-- Tommy = Founder / Unlimited / active / never expires
insert into public.subscriptions (center_id, plan_code, status, current_period_end)
values ('00000000-0000-0000-0000-000000000001', 'founder', 'active', null)
on conflict (center_id) do nothing;

-- ---------------------------------------------------------------------------
-- Helpers.
-- ---------------------------------------------------------------------------
create or replace function public.current_plan()
returns text
language sql stable security definer set search_path = public
as $$
  select coalesce(
    (select plan_code from public.subscriptions where center_id = public.current_center()),
    'starter'
  )
$$;

-- limit for the caller's center plan; NULL = unlimited
create or replace function public.plan_limit(p_key text)
returns integer
language sql stable security definer set search_path = public
as $$
  select nullif(p.limits ->> p_key, '')::integer
  from public.plans p
  where p.code = public.current_plan()
$$;

-- ---------------------------------------------------------------------------
-- RLS: plans are public (pricing page). subscriptions: own center + platform admin.
-- ---------------------------------------------------------------------------
alter table public.plans enable row level security;
drop policy if exists "public read plans" on public.plans;
create policy "public read plans" on public.plans for select to anon, authenticated using (true);

alter table public.subscriptions enable row level security;
drop policy if exists "read subscription" on public.subscriptions;
create policy "read subscription" on public.subscriptions for select to authenticated
  using (public.is_platform_admin() or center_id = public.current_center());
drop policy if exists "manage subscription" on public.subscriptions;
create policy "manage subscription" on public.subscriptions for all to authenticated
  using (public.is_platform_admin()) with check (public.is_platform_admin());
