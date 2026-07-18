-- ============================================================================
-- Migration 002 — platform_admins (ISA OS owner layer)
-- TASK 003 of the multi-tenant migration roadmap.
--
-- Introduces the PLATFORM admin role (ISA OS owner) — completely separate from
-- a Center Admin. A platform admin sees/manages ALL centers and bypasses
-- center-level isolation. A Center Admin (existing Tommy `admins`) is untouched.
--
-- Also adds the FIRST real RLS policy on centers (platform admins manage it).
--
-- SAFE / ADDITIVE: new table + helper function + new policies only. No existing
-- table, column, policy, or data is modified. Tommy keeps working unchanged.
--
-- APPLY:   run this whole file in the Supabase SQL editor (re-runnable).
-- ROLLBACK: run 002_platform_admins.down.sql
-- ============================================================================

-- ---------------------------------------------------------------------------
-- platform_admins — one row per ISA OS owner/operator.
-- ---------------------------------------------------------------------------
create table if not exists public.platform_admins (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  email      text,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Helper: is the current user a platform admin?
-- SECURITY DEFINER so it can read platform_admins regardless of RLS
-- (prevents recursion when used inside RLS policies). STABLE + fixed search_path.
-- ---------------------------------------------------------------------------
create or replace function public.is_platform_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.platform_admins where user_id = auth.uid()
  );
$$;

-- ---------------------------------------------------------------------------
-- Seed the founder as the first platform admin (looked up by email).
-- If the email is not found, this inserts nothing — verify after running.
-- ---------------------------------------------------------------------------
insert into public.platform_admins (user_id, email)
select id, email from auth.users
where email = 'karimov.islom7@icloud.com'
on conflict (user_id) do nothing;

-- ---------------------------------------------------------------------------
-- RLS on platform_admins: only platform admins may READ the table.
-- No write policy on purpose -> only service_role (SQL editor / Edge Functions)
-- can add/remove platform admins. Prevents privilege-escalation surface.
-- ---------------------------------------------------------------------------
alter table public.platform_admins enable row level security;

drop policy if exists "platform admins read platform_admins" on public.platform_admins;
create policy "platform admins read platform_admins"
  on public.platform_admins
  for select
  to authenticated
  using (public.is_platform_admin());

-- ---------------------------------------------------------------------------
-- First real policy on centers: platform admins get full access.
-- (Regular center members reading their own center comes after TASK 005,
--  once profiles.center_id exists. Until then centers stays platform-only.)
-- ---------------------------------------------------------------------------
drop policy if exists "platform admins manage centers" on public.centers;
create policy "platform admins manage centers"
  on public.centers
  for all
  to authenticated
  using (public.is_platform_admin())
  with check (public.is_platform_admin());
