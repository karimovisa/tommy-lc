-- ============================================================================
-- Migration 003 — center_branding + center_settings
-- TASK 004 of the multi-tenant migration roadmap.
--
-- Splits per-center config into two tables by nature:
--   center_branding  -> stable brand identity (logo, name, colors, prefix...)
--   center_settings  -> volatile operational rules (grading, assessment...)
-- Both are 1:1 with centers (center_id PK/FK).
--
-- This migration only CREATES the tables and SEEDS Tommy's known values.
-- Wiring the app to read them (theme engine) is TASK 012; extracting the full
-- grading/assessment logic out of code is TASK 013. Nothing is wired yet.
--
-- SAFE / ADDITIVE / IDEMPOTENT. No existing table/column/policy/data changes.
--
-- APPLY:   run this whole file in the Supabase SQL editor.
-- ROLLBACK: run 003_center_config.down.sql
-- ============================================================================

-- ---------------------------------------------------------------------------
-- center_branding — public-facing brand identity. Rarely changes.
-- NOTE: no secrets here. The Telegram BOT TOKEN stays in Supabase secrets /
-- Edge Function env, never in the database. Only the public bot username lives here.
-- ---------------------------------------------------------------------------
create table if not exists public.center_branding (
  center_id             uuid primary key references public.centers(id) on delete cascade,
  display_name          text,                       -- short label, e.g. "Tommy LC"
  logo_url              text,
  favicon_url           text,
  brand_color           text,                       -- primary hex, e.g. "#e5242b"
  font_family           text,
  student_id_prefix     text,                       -- e.g. "TLC"
  login_email_domain    text,                       -- hidden student-id email domain
  telegram_bot_username text,                       -- public @username, NOT the token
  social_links          jsonb not null default '{}'::jsonb,
  updated_at            timestamptz not null default now()
);

drop trigger if exists trg_center_branding_updated_at on public.center_branding;
create trigger trg_center_branding_updated_at
  before update on public.center_branding
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- center_settings — operational business rules. Changes often.
-- Kept as jsonb blobs now; full extraction from code happens in TASK 013.
-- ---------------------------------------------------------------------------
create table if not exists public.center_settings (
  center_id             uuid primary key references public.centers(id) on delete cascade,
  grading_weights       jsonb not null default '{}'::jsonb,   -- daily/test weighting
  assessment_config     jsonb not null default '{}'::jsonb,   -- levels, pass scores
  notification_settings jsonb not null default '{}'::jsonb,
  updated_at            timestamptz not null default now()
);

drop trigger if exists trg_center_settings_updated_at on public.center_settings;
create trigger trg_center_settings_updated_at
  before update on public.center_settings
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Seed Tommy's current (hardcoded-in-code) values as the first rows.
-- ---------------------------------------------------------------------------
insert into public.center_branding (
  center_id, display_name, brand_color, font_family,
  student_id_prefix, login_email_domain, telegram_bot_username, social_links
) values (
  '00000000-0000-0000-0000-000000000001',
  'Tommy LC',
  '#e5242b',
  'Plus Jakarta Sans',
  'TLC',
  'students.tommy.uz',
  'tommy_lc_bot',
  '{}'::jsonb
)
on conflict (center_id) do nothing;

insert into public.center_settings (
  center_id, grading_weights, assessment_config
) values (
  '00000000-0000-0000-0000-000000000001',
  -- current default daily/test weighting (vocab 30 / workbook-hw 40 / extra 30)
  '{"default": {"vocab": 30, "workbook": 40, "extra": 30}}'::jsonb,
  -- known pass thresholds; full unit configs migrate in TASK 013
  '{"levels": {"pre_intermediate": {"unit_total": 75, "unit_pass": 55}, "middle": {"total": 125, "pass": 80}}}'::jsonb
)
on conflict (center_id) do nothing;

-- ---------------------------------------------------------------------------
-- RLS.
-- center_branding: PUBLIC read (logo/name/color are shown on the pre-login
--   page per subdomain -> anon must read). Writes: platform admin (center
--   admin write is added after TASK 005 links profiles.center_id).
-- center_settings: NOT public. Platform admin only for now; center members
--   read theirs after TASK 005.
-- ---------------------------------------------------------------------------
alter table public.center_branding enable row level security;

drop policy if exists "public read center_branding" on public.center_branding;
create policy "public read center_branding"
  on public.center_branding
  for select
  to anon, authenticated
  using (true);

drop policy if exists "platform admins manage center_branding" on public.center_branding;
create policy "platform admins manage center_branding"
  on public.center_branding
  for all
  to authenticated
  using (public.is_platform_admin())
  with check (public.is_platform_admin());

alter table public.center_settings enable row level security;

drop policy if exists "platform admins manage center_settings" on public.center_settings;
create policy "platform admins manage center_settings"
  on public.center_settings
  for all
  to authenticated
  using (public.is_platform_admin())
  with check (public.is_platform_admin());
