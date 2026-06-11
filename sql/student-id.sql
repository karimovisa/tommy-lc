-- ============================================================
-- TOMMY LC — Student ID login uchun schema
-- Supabase > SQL Editor da bir marta ishga tushiring.
-- ============================================================

-- O'quvchiga Student ID (login_id) maydoni. Yashirin email:
--   <login_id (kichik harf)>@students.tommy.uz
-- Masalan: TOM-0001 -> tom-0001@students.tommy.uz
alter table public.students add column if not exists login_id text;

-- Bir xil ID ikki marta berilmasligi uchun (bo'sh qiymatlarga tegmaydi)
create unique index if not exists students_login_id_uniq
  on public.students (lower(login_id)) where login_id is not null;

-- ============================================================
-- Eslatma: auth akkountlar (auth.users) bulk-skript orqali
-- service_role bilan yaratiladi (har ID uchun yashirin email + parol).
-- Login: o'quvchi ID kiritadi -> sayt yashirin emailga aylantiradi -> kiradi.
-- ============================================================
