-- ============================================================================
-- Migration 020 — center-aware Student ID generator
-- TASK 021 of the roadmap (M1).
--
-- Problem: next_student_id() hardcodes 'TLC' and draws from ONE global sequence
-- shared by all centers. Each center needs its own prefix + its own counter.
--
-- Fix: per-center counter table + next_student_id(center) that reads the prefix
-- from center_branding.student_id_prefix. Tommy's counter is seeded from the
-- current global sequence so numbering CONTINUES with no collisions.
--
-- Backward compatible: the old no-arg next_student_id() is kept and now defaults
-- to Tommy, so the current Edge Function keeps working until TASK 022 passes the
-- center explicitly.
--
-- SAFE / ADDITIVE. Reversible via 020_center_student_ids.down.sql
-- APPLY: run in the Supabase SQL editor (idempotent).
-- ============================================================================

create table if not exists public.student_id_counters (
  center_id  uuid primary key references public.centers(id) on delete cascade,
  last_n     integer not null default 0,
  updated_at timestamptz not null default now()
);

-- backend-only table: RLS on, no client policies (service_role bypasses).
alter table public.student_id_counters enable row level security;

-- Seed Tommy's counter from the existing global sequence (continuity).
insert into public.student_id_counters (center_id, last_n)
select '00000000-0000-0000-0000-000000000001',
       coalesce((select last_value from public.student_id_seq), 0)
on conflict (center_id) do nothing;

-- Center-aware generator: atomic per-center increment + per-center prefix.
create or replace function public.next_student_id(p_center uuid)
returns text
language plpgsql
as $$
declare
  n   integer;
  pfx text;
begin
  insert into public.student_id_counters (center_id, last_n)
  values (p_center, 1)
  on conflict (center_id) do update
    set last_n = public.student_id_counters.last_n + 1, updated_at = now()
  returning last_n into n;

  select coalesce(nullif(student_id_prefix, ''), 'TLC') into pfx
  from public.center_branding where center_id = p_center;

  return coalesce(pfx, 'TLC') || to_char(current_date, 'YY') || lpad(n::text, 3, '0');
end $$;

-- Backward-compatible no-arg version -> defaults to Tommy (keeps Edge Function
-- working until TASK 022). Uses the SAME per-center counter, so no divergence.
create or replace function public.next_student_id()
returns text
language sql
as $$
  select public.next_student_id('00000000-0000-0000-0000-000000000001'::uuid)
$$;

-- Only the backend (service_role) generates IDs; block abuse from clients.
revoke execute on function public.next_student_id()     from public;
revoke execute on function public.next_student_id(uuid) from public;
grant  execute on function public.next_student_id()     to service_role;
grant  execute on function public.next_student_id(uuid) to service_role;
