-- ============================================================================
-- Migration 012 — Event System
-- TASK 011 of the multi-tenant migration roadmap.
--
-- Records semantic DOMAIN events (not raw row changes — that's audit_log). Each
-- meaningful action becomes an event row; future consumers (AI, Analytics,
-- Automation) read from here. Emitted automatically by thin triggers, and also
-- callable by the app later via the emit_event() RPC.
--
-- Events (on INSERT):
--   payments          -> PaymentReceived
--   homework          -> HomeworkCreated
--   assignment_grades -> TestGraded
--   students          -> StudentEnrolled
--   daily_checks      -> AttendanceMarked
--
-- SAFE / ADDITIVE: emission is wrapped in an exception handler, so it can never
-- break the real write. No existing data changed.
--
-- APPLY:   run in the Supabase SQL editor (idempotent).
-- ROLLBACK: run 012_event_system.down.sql
-- ============================================================================

-- ---------------------------------------------------------------------------
-- events — append-only domain event stream. processed_at = null means a
-- consumer hasn't handled it yet (queue semantics for later automation).
-- ---------------------------------------------------------------------------
create table if not exists public.events (
  id           bigint generated always as identity primary key,
  center_id    uuid,
  type         text not null,          -- PascalCase domain event name
  payload      jsonb,
  actor_id     uuid,
  occurred_at  timestamptz not null default now(),
  processed_at timestamptz
);

create index if not exists idx_events_center_time on public.events(center_id, occurred_at desc);
create index if not exists idx_events_type        on public.events(type);
create index if not exists idx_events_unprocessed on public.events(occurred_at) where processed_at is null;

-- ---------------------------------------------------------------------------
-- Trigger emitter: event type is passed as a trigger argument.
-- ---------------------------------------------------------------------------
create or replace function public.event_emit_trigger()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_type   text := tg_argv[0];
  v_new    jsonb := to_jsonb(new);
  v_center uuid := nullif(v_new ->> 'center_id', '')::uuid;
begin
  begin
    insert into public.events(center_id, type, payload, actor_id)
    values (v_center, v_type, v_new, auth.uid());
  exception when others then
    null;   -- never break the real write because of event emission
  end;
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- App-facing emitter (for later, once the app is center-aware). Derives center
-- from the caller's JWT; use for events that aren't a simple row insert.
-- ---------------------------------------------------------------------------
create or replace function public.emit_event(p_type text, p_payload jsonb default '{}'::jsonb)
returns bigint
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id bigint;
begin
  insert into public.events(center_id, type, payload, actor_id)
  values (public.current_center(), p_type, p_payload, auth.uid())
  returning id into v_id;
  return v_id;
end;
$$;

revoke execute on function public.emit_event(text, jsonb) from anon;
grant   execute on function public.emit_event(text, jsonb) to authenticated;

-- ---------------------------------------------------------------------------
-- Attach domain-event triggers.
-- ---------------------------------------------------------------------------
do $$
declare
  r record;
  maps text[][] := array[
    ['payments',          'PaymentReceived'],
    ['homework',          'HomeworkCreated'],
    ['assignment_grades', 'TestGraded'],
    ['students',          'StudentEnrolled'],
    ['daily_checks',      'AttendanceMarked']
  ];
  i int;
begin
  for i in 1 .. array_length(maps, 1) loop
    execute format('drop trigger if exists trg_event on public.%I', maps[i][1]);
    execute format(
      'create trigger trg_event after insert on public.%I
         for each row execute function public.event_emit_trigger(%L)',
      maps[i][1], maps[i][2]);
  end loop;
end $$;

-- ---------------------------------------------------------------------------
-- RLS: platform admins (all) and center admins (own center) may read events.
-- No write policy -> only the triggers / emit_event (security definer) write.
-- ---------------------------------------------------------------------------
alter table public.events enable row level security;

drop policy if exists "read events" on public.events;
create policy "read events"
  on public.events
  for select
  to authenticated
  using (
    public.is_platform_admin()
    or (public.is_admin() and center_id = public.current_center())
  );
