-- ============================================================
-- TOMMY LC — Seriya (streak): dars tasdiqlash
-- Supabase > SQL Editor da bir marta ishga tushiring.
-- (tommy-rls-setup.sql dan keyin — owns_student/is_admin/is_teacher kerak)
-- ============================================================

create table if not exists public.lesson_confirms(
  student_id   uuid not null,
  lesson_date  date not null,
  was_absent   boolean default false,   -- o'sha kuni "kelmadi" belgilanganmidi
  confirmed_at timestamptz default now(),
  primary key (student_id, lesson_date)
);

alter table public.lesson_confirms enable row level security;

-- O'quvchi faqat O'ZINIKINI qo'shadi/o'qiydi/o'chiradi
drop policy if exists lc_own on public.lesson_confirms;
create policy lc_own on public.lesson_confirms for all
  using (public.owns_student(student_id))
  with check (public.owns_student(student_id));

-- Admin/ustoz o'qiy oladi (kuzatish uchun)
drop policy if exists lc_staff_read on public.lesson_confirms;
create policy lc_staff_read on public.lesson_confirms for select
  using (public.is_admin() or public.is_teacher());

-- ============================================================
-- TAYYOR.
-- ============================================================
