-- ============================================================
-- TOMMY LC — Ota-ona tizimi + O'qituvchi izohlari + Test ball
-- Supabase > SQL Editor da ishga tushiring.
-- (tommy-rls-setup.sql dan keyin)
-- ============================================================

-- 1) Ota-ona <-> farzand bog'lamasi (bitta ota-ona -> ko'p farzand)
create table if not exists public.parent_links(
  parent_uid uuid not null,
  student_id uuid not null references public.students(id) on delete cascade,
  created_at timestamptz default now(),
  primary key (parent_uid, student_id)
);
alter table public.parent_links enable row level security;
drop policy if exists pl_read on public.parent_links;
create policy pl_read on public.parent_links for select
  using (parent_uid = auth.uid() or public.is_admin() or public.is_teacher());
drop policy if exists pl_admin on public.parent_links;
create policy pl_admin on public.parent_links for all
  using (public.is_admin()) with check (public.is_admin());

-- 2) owns_student: ota-onani ham qamrasin (farzandi ma'lumotini o'qiydi)
create or replace function public.owns_student(sid uuid) returns boolean
  language sql stable security definer set search_path = public as $$
  select exists(select 1 from profiles where id = auth.uid() and student_id = sid)
      or exists(select 1 from parent_links where parent_uid = auth.uid() and student_id = sid)
$$;

-- 3) in_my_group: ota-ona farzandi guruhini ham (uy ishi ro'yxati uchun)
create or replace function public.in_my_group(gid uuid) returns boolean
  language sql stable security definer set search_path = public as $$
  select exists(select 1 from profiles where id = auth.uid() and group_id = gid)
      or exists(select 1 from parent_links pl join students s on s.id = pl.student_id
                where pl.parent_uid = auth.uid() and s.group_id = gid)
$$;

-- 4) O'qituvchi izohlari (har o'quvchi uchun)
create table if not exists public.teacher_comments(
  id              uuid primary key default gen_random_uuid(),
  student_id      uuid references public.students(id) on delete cascade,
  body            text not null,
  created_by      uuid,
  created_by_name text,
  created_at      timestamptz default now()
);
alter table public.teacher_comments enable row level security;
-- O'quvchi/ota-ona o'qiydi; ustoz/admin o'qiydi+yozadi
drop policy if exists tc_read on public.teacher_comments;
create policy tc_read on public.teacher_comments for select
  using (public.owns_student(student_id) or public.scope_student(student_id));
drop policy if exists tc_write on public.teacher_comments;
create policy tc_write on public.teacher_comments for all
  using (public.scope_student(student_id)) with check (public.scope_student(student_id));
create index if not exists tc_student_idx on public.teacher_comments(student_id, created_at desc);

-- 4b) Ota-onaning login ID si (bog'lash uchun qidiriladi)
alter table public.profiles add column if not exists parent_login_id text;

-- 5) Test ball (foiz + xom ball)
alter table public.assignments       add column if not exists max_score int;     -- maksimal ball (masalan 75)
alter table public.assignment_grades add column if not exists score numeric;     -- olingan ball (masalan 55)

-- 6) Guruh o'rtacha solishtirish (ota-ona peer ma'lumotini ko'rolmaydi -> definer RPC)
create or replace function public.child_compare(sid uuid)
returns json language plpgsql security definer set search_path = public as $$
declare gid uuid; r json;
begin
  if not (public.owns_student(sid) or public.scope_student(sid)) then return null; end if;
  select group_id into gid from students where id = sid;
  select json_build_object(
    'test_child', (select round(avg(grade)) from assignment_grades where student_id = sid),
    'test_group', (select round(avg(ag.grade)) from assignment_grades ag
                     join students s on s.id = ag.student_id where s.group_id = gid),
    'hw_total',   (select count(*) from homework where group_id = gid),
    'hw_child',   (select count(*) from homework h where h.group_id = gid
                     and exists(select 1 from homework_done hd
                                where hd.homework_id = h.id and hd.student_id = sid and hd.done)),
    'hw_group_pct', (select case when sc = 0 then 0 else round(100.0*dn/sc) end from (
        select count(*) sc, count(*) filter (where hd.done) dn
        from homework h join students s on s.group_id = h.group_id
        left join homework_done hd on hd.homework_id = h.id and hd.student_id = s.id
        where h.group_id = gid) t)
  ) into r;
  return r;
end $$;
grant execute on function public.child_compare(uuid) to authenticated;

-- ============================================================
-- TAYYOR. Keyingisi: Edge Function (ota-ona akkounti) + frontend.
-- ============================================================
