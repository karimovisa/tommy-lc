-- ============================================================
-- TOMMY LC — Student auth tizimi: SCHEMA
-- Supabase > SQL Editor da bir marta ishga tushiring.
-- ============================================================

-- 1) students jadvaliga yangi maydonlar
alter table public.students add column if not exists student_id      text;
alter table public.students add column if not exists course_name     text;
alter table public.students add column if not exists start_date      date;
alter table public.students add column if not exists password_changed boolean default false;
alter table public.students add column if not exists status          text default 'ACTIVE';
alter table public.students add column if not exists updated_at      timestamptz default now();

-- Student ID noyob bo'lishi shart
create unique index if not exists students_student_id_uniq
  on public.students (lower(student_id)) where student_id is not null;

-- status faqat ruxsat etilgan qiymatlar
alter table public.students drop constraint if exists students_status_chk;
alter table public.students add constraint students_status_chk
  check (status in ('ACTIVE','INACTIVE','GRADUATED'));

-- 2) Student ID generatori: TLC + 2 raqamli yil + 3 raqamli tartib
--    Masalan 2025-yil -> TLC25001, TLC25002, ...
create sequence if not exists public.student_id_seq;

create or replace function public.next_student_id() returns text
language plpgsql as $$
declare n int; yy text;
begin
  n := nextval('public.student_id_seq');
  yy := to_char(current_date, 'YY');
  return 'TLC' || yy || lpad(n::text, 3, '0');
end $$;

-- 3) Login tarixi (kim, qachon, qaysi natija)
create table if not exists public.login_history(
  id          uuid primary key default gen_random_uuid(),
  student_id  text,
  user_id     uuid,
  status      text,            -- 'success' | 'failed' | 'blocked'
  ip          text,
  created_at  timestamptz default now()
);
alter table public.login_history enable row level security;
-- O'quvchi o'z yozuvini qo'sha oladi; admin/o'qituvchi o'qiy oladi
create policy lh_insert_self on public.login_history for insert
  with check (user_id = auth.uid());
create policy lh_admin_read on public.login_history for select
  using (public.is_admin() or public.is_teacher());

-- 4) O'quvchi o'z parolini o'zgartirgach chaqiradi (first-login)
create or replace function public.mark_my_password_changed() returns void
language plpgsql security definer set search_path = public as $$
declare sid uuid;
begin
  select student_id into sid from profiles where id = auth.uid();
  if sid is not null then
    update students set password_changed = true, updated_at = now() where id = sid;
  end if;
end $$;
grant execute on function public.mark_my_password_changed() to authenticated;

-- ============================================================
-- TAYYOR. Keyingisi: Edge Function (akkount yaratish/tiklash).
-- ============================================================
