-- ============================================================
-- TOMMY LC — Materiallar STORAGE ruxsatlari
-- AVVAL: Supabase > Storage > "New bucket" > nomi: materials > Public ✓ > Create
-- KEYIN: shu SQL ni SQL Editor da ishga tushiring.
-- ============================================================

-- O'qish: ommaviy (hamma ochadi)
drop policy if exists mat_obj_read on storage.objects;
create policy mat_obj_read on storage.objects for select
  using (bucket_id = 'materials');

-- Yuklash: faqat admin yoki ustoz
drop policy if exists mat_obj_write on storage.objects;
create policy mat_obj_write on storage.objects for insert to authenticated
  with check (bucket_id = 'materials' and (public.is_admin() or public.is_teacher()));

-- O'chirish: faqat admin yoki ustoz
drop policy if exists mat_obj_del on storage.objects;
create policy mat_obj_del on storage.objects for delete to authenticated
  using (bucket_id = 'materials' and (public.is_admin() or public.is_teacher()));

-- ============================================================
-- TAYYOR.
-- ============================================================
