-- ============================================================================
-- ROLLBACK for migration 020 — restore the single-sequence TLC generator
-- ============================================================================

drop function if exists public.next_student_id(uuid);

create or replace function public.next_student_id()
returns text
language plpgsql
as $$
declare n int; yy text;
begin
  n := nextval('public.student_id_seq');
  yy := to_char(current_date, 'YY');
  return 'TLC' || yy || lpad(n::text, 3, '0');
end $$;

drop table if exists public.student_id_counters;
