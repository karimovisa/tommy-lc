-- ============================================================
-- TOMMY LC — Materiallar (havola + fayl)
-- Supabase > SQL Editor da bir marta ishga tushiring.
-- (tommy-rls-setup.sql dan keyin — is_admin/is_teacher/teaches_group kerak)
-- ============================================================

-- 1) Materiallar jadvali
create table if not exists public.materials(
  id              uuid primary key default gen_random_uuid(),
  group_id        uuid references public.groups(id) on delete cascade,
  title           text not null,
  kind            text not null default 'link',   -- 'link' | 'file' | 'words'
  url             text,                            -- havola yoki fayl public URL
  file_path       text,                            -- storage yo'li (faylни o'chirish uchun)
  content         text,                            -- 'words' uchun: lug'at ro'yxati (har qatorda: word - tarjima)
  created_by      uuid,
  created_by_name text,
  created_at      timestamptz default now()
);
alter table public.materials enable row level security;

-- O'quvchi o'z guruhi materiallarini o'qiydi; admin/ustoz hammasini
drop policy if exists mat_read on public.materials;
create policy mat_read on public.materials for select using (
  public.is_admin() or public.is_teacher()
  or group_id in (select group_id from public.profiles where id = auth.uid())
);

-- Admin yoki guruh ustozi qo'shadi/o'chiradi
drop policy if exists mat_write on public.materials;
create policy mat_write on public.materials for all
  using (public.is_admin() or public.teaches_group(group_id))
  with check (public.is_admin() or public.teaches_group(group_id));

create index if not exists materials_group_idx on public.materials (group_id, created_at desc);

-- 2) Storage bucket (ommaviy — fayllar havola orqali ochiladi)
insert into storage.buckets (id, name, public)
  values ('materials','materials',true)
  on conflict (id) do nothing;

-- 3) Storage ruxsatlari (faqat admin/ustoz yuklaydi/o'chiradi; o'qish ommaviy)
drop policy if exists mat_obj_read on storage.objects;
create policy mat_obj_read on storage.objects for select
  using (bucket_id = 'materials');

drop policy if exists mat_obj_write on storage.objects;
create policy mat_obj_write on storage.objects for insert to authenticated
  with check (bucket_id = 'materials' and (public.is_admin() or public.is_teacher()));

drop policy if exists mat_obj_del on storage.objects;
create policy mat_obj_del on storage.objects for delete to authenticated
  using (bucket_id = 'materials' and (public.is_admin() or public.is_teacher()));

-- ============================================================
-- TAYYOR.
-- ============================================================
