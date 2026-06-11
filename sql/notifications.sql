-- ============================================================
-- TOMMY LC — Bildirishnomalar (notifications)
-- Supabase > SQL Editor da bir marta ishga tushiring.
-- (tommy-rls-setup.sql dan keyin — is_admin/is_teacher/teaches_group kerak)
-- ============================================================

create table if not exists public.notifications(
  id              uuid primary key default gen_random_uuid(),
  title           text not null,
  body            text,
  group_id        uuid references public.groups(id) on delete cascade,  -- null = BARCHA o'quvchilarga
  created_by      uuid,
  created_by_name text,
  created_at      timestamptz default now()
);

alter table public.notifications enable row level security;

-- O'qish: o'quvchi hammaga (group_id null) yoki o'z guruhiga; admin/ustoz hammasini
drop policy if exists notif_read on public.notifications;
create policy notif_read on public.notifications for select using (
  public.is_admin() or public.is_teacher()
  or group_id is null
  or group_id in (select group_id from public.profiles where id = auth.uid())
);

-- Yozish: admin hammaga; ustoz hammaga yoki o'z guruhiga
drop policy if exists notif_insert on public.notifications;
create policy notif_insert on public.notifications for insert with check (
  public.is_admin() or (public.is_teacher() and (group_id is null or public.teaches_group(group_id)))
);

-- O'chirish: admin yoki guruh ustozi
drop policy if exists notif_delete on public.notifications;
create policy notif_delete on public.notifications for delete using (
  public.is_admin() or public.teaches_group(group_id)
);

-- Tez tartiblash uchun indeks
create index if not exists notifications_created_idx on public.notifications (created_at desc);

-- ============================================================
-- TAYYOR.
-- ============================================================
