-- ============================================================
-- TOMMY LC — Test o'quvchi: Djurayeva Aziza (801-guruh)
-- Student ID: TOM-0001  |  Yashirin email: tom-0001@students.tommy.uz
-- ============================================================
-- TARTIB:
-- 1) Avval tommy-student-id.sql ni ishga tushiring (login_id ustuni).
-- 2) Supabase > Authentication > Users > "Add user":
--      Email:    tom-0001@students.tommy.uz
--      Password: (masalan) Aziza2025!
--      "Auto Confirm User" -> YOQ (belgilang)
-- 3) Shu pastdagi blokni SQL Editor da ishga tushiring.
-- 4) Saytda: O'quvchi tab -> ID: TOM-0001 -> Parol: Aziza2025! -> Kirish
-- ============================================================

do $$
declare gid uuid; uid uuid; sid uuid;
begin
  -- Guruh (yo'q bo'lsa yaratamiz)
  select id into gid from public.groups where name = '801-guruh' limit 1;
  if gid is null then
    insert into public.groups(name) values ('801-guruh') returning id into gid;
  end if;

  -- O'quvchi yozuvi
  select id into sid from public.students where lower(login_id) = 'tom-0001' limit 1;
  if sid is null then
    insert into public.students(name, group_id, group_name, login_id)
    values ('Djurayeva Aziza', gid, '801-guruh', 'TOM-0001')
    returning id into sid;
  end if;

  -- Auth user (dashboardda yaratilgan) ni emaildan topamiz
  select id into uid from auth.users where email = 'tom-0001@students.tommy.uz' limit 1;
  if uid is null then
    raise exception 'Avval Authentication > Add user da tom-0001@students.tommy.uz yarating';
  end if;

  -- Profil (o'quvchi roli, tasdiqlangan, o'quvchiga bog'langan)
  insert into public.profiles(id, full_name, role, group_id, student_id, approved)
  values (uid, 'Djurayeva Aziza', 'student', gid, sid, true)
  on conflict (id) do update
    set student_id = excluded.student_id, group_id = excluded.group_id,
        approved = true, role = 'student', full_name = excluded.full_name;

  raise notice 'Tayyor: Djurayeva Aziza (TOM-0001) faollashtirildi.';
end $$;
