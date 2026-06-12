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

-- ============================================================
-- TAYYOR.
-- ============================================================
