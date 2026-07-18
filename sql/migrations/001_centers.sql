-- ============================================================================
-- Migration 001 — centers (ISA Learning Center OS foundation)
-- TASK 002 of the multi-tenant migration roadmap.
--
-- SAFE / ADDITIVE: introduces a brand-new table only. Touches NO existing
-- table, column, policy, or data. Tommy LC keeps working unchanged.
--
-- APPLY:   run this whole file in the Supabase SQL editor.
-- ROLLBACK: run 001_centers.down.sql
-- ============================================================================

-- gen_random_uuid() lives in pgcrypto (already enabled on Supabase, kept for safety)
create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- Shared helper: keep updated_at fresh on every UPDATE.
-- Reused by future migrations (create or replace, so it is idempotent).
-- ---------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- centers — the platform tenant registry. One row per learning center.
-- Every business row will eventually carry a center_id -> centers.id.
-- ---------------------------------------------------------------------------
create table if not exists public.centers (
  id                uuid primary key default gen_random_uuid(),
  slug              text not null unique,                       -- subdomain: <slug>.isa-os.uz
  name              text not null,
  status            text not null default 'active'
                      check (status in ('active', 'trial', 'suspended')),

  -- reserved for later phases (kept nullable so they never block anything now)
  subscription_plan text,                                       -- founder / starter / professional / enterprise
  timezone          text not null default 'Asia/Tashkent',
  language           text not null default 'uz',

  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

drop trigger if exists trg_centers_updated_at on public.centers;
create trigger trg_centers_updated_at
  before update on public.centers
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Seed Tommy LC as center #1 with a FIXED, memorable UUID.
-- This exact id becomes the DEFAULT for center_id backfill in TASK 005,
-- so it must stay stable forever.
-- ---------------------------------------------------------------------------
insert into public.centers (id, slug, name, status, subscription_plan, timezone, language)
values (
  '00000000-0000-0000-0000-000000000001',
  'tommy',
  'Tommy Learning Center',
  'active',
  'founder',
  'Asia/Tashkent',
  'uz'
)
on conflict (id) do nothing;

-- ---------------------------------------------------------------------------
-- Security: RLS ON, but NO permissive policies yet (default-deny).
-- Only service_role (Edge Functions) can touch this table for now.
-- Real read/write policies arrive in TASK 003 (platform_admins) and are
-- refined after TASK 005 links profiles.center_id. This is intentional:
-- an unlinked centers table must not leak the tenant list to any user.
-- ---------------------------------------------------------------------------
alter table public.centers enable row level security;
