-- ============================================================
-- TOMMY LC — Tuzatishlar
-- Supabase > SQL Editor da ishga tushiring.
-- ============================================================

-- Bildirishnoma o'chirish: ustoz O'ZI yuborganini ham o'chira olsin
-- (oldin "hammaga" yuborilganini (group_id=null) faqat admin o'chira olardi)
drop policy if exists notif_delete on public.notifications;
create policy notif_delete on public.notifications for delete using (
  public.is_admin()
  or created_by = auth.uid()
  or public.teaches_group(group_id)
);

-- Bildirishnoma o'qish: ustoz FAQAT o'z guruhlari + umumiy + o'zi yuborganini ko'rsin
-- (oldin har qanday ustoz HAMMA bildirishnomani ko'rardi)
drop policy if exists notif_read on public.notifications;
create policy notif_read on public.notifications for select using (
  public.is_admin()
  or group_id is null
  or created_by = auth.uid()
  or public.teaches_group(group_id)
  or group_id in (select group_id from public.profiles where id = auth.uid())
);

-- ============================================================
-- TAYYOR.
-- ============================================================
