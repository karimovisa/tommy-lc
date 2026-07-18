-- ============================================================================
-- ROLLBACK for migration 012 — Event System
-- ============================================================================

do $$
declare
  t text;
  tables text[] := array['payments', 'homework', 'assignment_grades', 'students', 'daily_checks'];
begin
  foreach t in array tables loop
    execute format('drop trigger if exists trg_event on public.%I', t);
  end loop;
end $$;

drop function if exists public.emit_event(text, jsonb);
drop function if exists public.event_emit_trigger();
drop table if exists public.events;
