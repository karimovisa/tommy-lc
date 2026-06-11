-- ============================================================
-- TOMMY LC — RLS (Row-Level Security) sozlamasi
-- Supabase > SQL Editor da bir marta ishga tushiring.
-- Maqsad: ma'lumotlarni rol bo'yicha himoyalash
--   admin     -> hammasi
--   o'qituvchi -> faqat o'z guruhlari
--   o'quvchi/ota-ona -> faqat o'z natijasi
-- ============================================================

-- ---------- 0) YORDAMCHI FUNKSIYALAR ----------

-- Joriy foydalanuvchining emaili (kichik harflarda)
create or replace function public.auth_email() returns text
  language sql stable as $$
  select lower(coalesce((auth.jwt() ->> 'email'), ''))
$$;

-- Adminlar ro'yxati (JS dagi ADMIN_EMAILS o'rniga — bazada)
create table if not exists public.admins(email text primary key);
insert into public.admins(email) values ('karimov.islom7@icloud.com')
  on conflict (email) do nothing;
alter table public.admins enable row level security;  -- faqat funksiyalar ko'radi

create or replace function public.is_admin() returns boolean
  language sql stable security definer set search_path = public as $$
  select exists(select 1 from admins where email = public.auth_email())
$$;

create or replace function public.is_teacher() returns boolean
  language sql stable security definer set search_path = public as $$
  select exists(select 1 from groups where lower(teacher_email) = public.auth_email())
$$;

-- Shu guruhga shu foydalanuvchi o'qituvchimi (yoki admin)?
create or replace function public.teaches_group(gid uuid) returns boolean
  language sql stable security definer set search_path = public as $$
  select public.is_admin() or exists(
    select 1 from groups where id = gid and lower(teacher_email) = public.auth_email())
$$;

-- Shu o'quvchi shu foydalanuvchining o'zinikimi (o'quvchi/ota-ona)?
create or replace function public.owns_student(sid uuid) returns boolean
  language sql stable security definer set search_path = public as $$
  select exists(select 1 from profiles where id = auth.uid() and student_id = sid)
$$;

-- Shu o'quvchi joriy foydalanuvchi qamrovidami (admin yoki uning o'qituvchisi)?
create or replace function public.scope_student(sid uuid) returns boolean
  language sql stable security definer set search_path = public as $$
  select public.is_admin() or exists(
    select 1 from students s join groups g on g.id = s.group_id
    where s.id = sid and lower(g.teacher_email) = public.auth_email())
$$;

-- Shu guruh foydalanuvchining (o'quvchi/ota-ona) guruhimi?
create or replace function public.in_my_group(gid uuid) returns boolean
  language sql stable security definer set search_path = public as $$
  select exists(select 1 from profiles where id = auth.uid() and group_id = gid)
$$;


-- ---------- 1) GROUPS ----------
-- Ro'yxatdan o'tishda guruh/ustoz ro'yxati hammaga ko'rinishi kerak (anon ham).
alter table public.groups enable row level security;
create policy groups_read  on public.groups for select using (true);
create policy groups_write on public.groups for all
  using (public.is_admin()) with check (public.is_admin());


-- ---------- 2) PROFILES ----------
alter table public.profiles enable row level security;
-- O'z yozuvi
create policy profiles_self_sel on public.profiles for select using (id = auth.uid());
create policy profiles_self_ins on public.profiles for insert with check (id = auth.uid());
create policy profiles_self_upd on public.profiles for update using (id = auth.uid()) with check (id = auth.uid());
-- Admin — hammasi
create policy profiles_admin on public.profiles for all
  using (public.is_admin()) with check (public.is_admin());
-- O'qituvchi — o'z guruhidagilarni ko'radi/tasdiqlaydi/rad etadi
create policy profiles_teacher_sel on public.profiles for select using (public.teaches_group(group_id));
create policy profiles_teacher_upd on public.profiles for update using (public.teaches_group(group_id)) with check (true);
create policy profiles_teacher_del on public.profiles for delete using (public.teaches_group(group_id));


-- ---------- 3) STUDENTS ----------
alter table public.students enable row level security;
-- Admin/o'qituvchi — o'z qamrovidagilar
create policy students_scope on public.students for all
  using (public.teaches_group(group_id)) with check (public.teaches_group(group_id));
-- O'quvchi/ota-ona — faqat o'zini ko'radi
create policy students_own_sel on public.students for select using (public.owns_student(id));
-- Ro'yxatdan o'tishda yangi o'quvchi yozuvini yaratish (faqat guruh ko'rsatilgan bo'lsa)
create policy students_signup_ins on public.students for insert to authenticated
  with check (group_id is not null);


-- ---------- 4) DAILY_CHECKS ----------
alter table public.daily_checks enable row level security;
create policy checks_scope on public.daily_checks for all
  using (public.scope_student(student_id)) with check (public.scope_student(student_id));
create policy checks_own_sel on public.daily_checks for select using (public.owns_student(student_id));


-- ---------- 5) ASSIGNMENTS ----------
alter table public.assignments enable row level security;
-- O'qituvchi/admin — yaratish/ko'rish
create policy assign_teacher on public.assignments for all
  using (public.is_teacher() or public.is_admin())
  with check (public.is_teacher() or public.is_admin());
-- O'quvchi — faqat o'ziga baho qo'yilgan vazifani ko'radi
create policy assign_student_sel on public.assignments for select using (
  exists(select 1 from assignment_grades ag
         where ag.assignment_id = assignments.id and public.owns_student(ag.student_id)));


-- ---------- 6) ASSIGNMENT_GRADES ----------
alter table public.assignment_grades enable row level security;
create policy grades_scope on public.assignment_grades for all
  using (public.scope_student(student_id)) with check (public.scope_student(student_id));
create policy grades_own_sel on public.assignment_grades for select using (public.owns_student(student_id));


-- ---------- 7) HOMEWORK ----------
alter table public.homework enable row level security;
create policy hw_scope on public.homework for all
  using (public.teaches_group(group_id)) with check (public.teaches_group(group_id));
create policy hw_student_sel on public.homework for select using (public.in_my_group(group_id));


-- ---------- 8) HOMEWORK_DONE ----------
alter table public.homework_done enable row level security;
-- O'quvchi — o'z belgilashlari
create policy hwd_own on public.homework_done for all
  using (public.owns_student(student_id)) with check (public.owns_student(student_id));
-- O'qituvchi/admin — sanash uchun ko'radi
create policy hwd_scope_sel on public.homework_done for select using (public.scope_student(student_id));


-- ============================================================
-- TAYYOR. Endi quyidagilarni TEKSHIRING (juda muhim):
--   1) Admin bilan kiring  -> hamma guruh/o'quvchi ko'rinadimi
--   2) O'qituvchi bilan kiring -> faqat o'z guruhi ko'rinadimi, saqlash ishlaydimi
--   3) O'quvchi bilan kiring  -> faqat o'z natijasi, uy ishi belgilash ishlaydimi
--   4) Yangi ro'yxatdan o'tish -> ustoz/guruh tanlash, ro'yxatdan o'tish ishlaydimi
-- Agar biror joy ishlamay qolsa — pastdagi ROLLBACK bilan vaqtincha o'chiring.
-- ============================================================

-- ---------- ROLLBACK (agar ilova buzilsa, vaqtincha o'chirish) ----------
-- alter table public.groups            disable row level security;
-- alter table public.profiles          disable row level security;
-- alter table public.students          disable row level security;
-- alter table public.daily_checks      disable row level security;
-- alter table public.assignments       disable row level security;
-- alter table public.assignment_grades disable row level security;
-- alter table public.homework          disable row level security;
-- alter table public.homework_done     disable row level security;
