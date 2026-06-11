-- ============================================================
-- TOMMY LC — O'quvchi o'z o'rnini (reyting) xavfsiz ko'rishi
-- Supabase > SQL Editor da bir marta ishga tushiring.
-- Bu funksiya FAQAT o'quvchining o'z o'rni + guruh o'rtachasini
-- qaytaradi. Sinfdoshlarning ism/baholari OCHILMAYDI.
-- ============================================================

create or replace function public.my_group_rank()
returns table(rank int, total int, group_avg int, my_overall int)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  myprof record;
  gid uuid;
  sid uuid;
begin
  select * into myprof from profiles where id = auth.uid();
  if myprof is null then return; end if;
  gid := myprof.group_id;
  sid := myprof.student_id;
  if gid is null then return; end if;

  return query
  with stud as (
    select s.id, coalesce(s.stats_since, date '1900-01-01') as since
    from students s
    where s.group_id = gid and coalesce(s.frozen, false) = false
  ),
  ov as (
    select st.id,
      coalesce(round(avg(dc.words)*30 + avg(dc.hw)*40 + avg(dc.extra)*30), 0)::int as overall
    from stud st
    left join daily_checks dc
      on dc.student_id = st.id
     and coalesce(dc.absent, false) = false
     and dc.date >= st.since
    group by st.id
  )
  select
    ((select count(*) from ov where overall > coalesce((select overall from ov where id = sid), 0)) + 1)::int as rank,
    (select count(*) from ov)::int as total,
    (select coalesce(round(avg(overall)), 0) from ov)::int as group_avg,
    coalesce((select overall from ov where id = sid), 0)::int as my_overall;
end;
$$;

-- Faqat tizimga kirgan foydalanuvchilar chaqira oladi
grant execute on function public.my_group_rank() to authenticated;

-- ============================================================
-- TAYYOR. Ishga tushgach, o'quvchi sayti avtomatik o'z o'rnini
-- ko'rsatadi. Sinab ko'rish (ixtiyoriy):
--   select * from public.my_group_rank();
-- ============================================================
