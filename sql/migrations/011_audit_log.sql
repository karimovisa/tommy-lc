-- ============================================================================
-- Migration 011 — Audit Logs
-- TASK 010 of the multi-tenant migration roadmap.
--
-- Records who changed what, when, in which center. One generic trigger captures
-- INSERT/UPDATE/DELETE on the sensitive tables (financial, academic, structural,
-- platform config). High-frequency marking tables (daily_checks, homework_done,
-- notifications, messages, login_history, lesson_confirms) are intentionally NOT
-- audited to avoid bloat.
--
-- SAFE / ADDITIVE: new table + trigger function + triggers. The audit insert is
-- wrapped in an exception handler, so a logging failure can never break the real
-- write. No existing data changed.
--
-- APPLY:   run in the Supabase SQL editor (idempotent).
-- ROLLBACK: run 011_audit_log.down.sql
-- ============================================================================

-- ---------------------------------------------------------------------------
-- audit_log — append-only history. Written only by the trigger (security definer).
-- ---------------------------------------------------------------------------
create table if not exists public.audit_log (
  id          bigint generated always as identity primary key,
  center_id   uuid,
  actor_id    uuid,
  actor_email text,
  action      text not null,          -- INSERT | UPDATE | DELETE
  table_name  text not null,
  row_id      text,
  old_data    jsonb,
  new_data    jsonb,
  created_at  timestamptz not null default now()
);

create index if not exists idx_audit_center_time on public.audit_log(center_id, created_at desc);
create index if not exists idx_audit_table_row   on public.audit_log(table_name, row_id);

-- ---------------------------------------------------------------------------
-- Generic audit trigger. SECURITY DEFINER so it can always write the log row.
-- ---------------------------------------------------------------------------
create or replace function public.audit_trigger()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_old    jsonb;
  v_new    jsonb;
  v_rec    jsonb;
  v_center uuid;
  v_rowid  text;
begin
  if tg_op = 'DELETE' then
    v_old := to_jsonb(old); v_new := null; v_rec := v_old;
  elsif tg_op = 'UPDATE' then
    v_old := to_jsonb(old); v_new := to_jsonb(new); v_rec := v_new;
  else
    v_old := null; v_new := to_jsonb(new); v_rec := v_new;
  end if;

  -- center from center_id, or (for platform tables) the row's own id
  v_center := nullif(coalesce(v_rec->>'center_id', v_rec->>'id'), '')::uuid;
  v_rowid  := coalesce(v_rec->>'id', v_rec->>'email', v_rec->>'user_id', v_rec->>'center_id');

  begin
    insert into public.audit_log(center_id, actor_id, actor_email, action, table_name, row_id, old_data, new_data)
    values (v_center, auth.uid(), nullif(auth.jwt() ->> 'email', ''), tg_op, tg_table_name, v_rowid, v_old, v_new);
  exception when others then
    null;   -- never break the real write because of logging
  end;

  if tg_op = 'DELETE' then return old; else return new; end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- Attach the trigger to the audited tables.
-- ---------------------------------------------------------------------------
do $$
declare
  t text;
  tables text[] := array[
    'students', 'profiles', 'groups', 'payments',
    'assignments', 'assignment_grades', 'admins',
    'centers', 'center_branding', 'center_settings', 'platform_admins'
  ];
begin
  foreach t in array tables loop
    execute format('drop trigger if exists trg_audit on public.%I', t);
    execute format(
      'create trigger trg_audit after insert or update or delete on public.%I
         for each row execute function public.audit_trigger()', t);
  end loop;
end $$;

-- ---------------------------------------------------------------------------
-- RLS: audit_log is read-only to platform admins (all) and center admins (own
-- center). No write policy -> only the security-definer trigger writes it.
-- ---------------------------------------------------------------------------
alter table public.audit_log enable row level security;

drop policy if exists "read audit_log" on public.audit_log;
create policy "read audit_log"
  on public.audit_log
  for select
  to authenticated
  using (
    public.is_platform_admin()
    or (public.is_admin() and center_id = public.current_center())
  );
