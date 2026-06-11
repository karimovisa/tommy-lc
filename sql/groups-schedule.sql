-- ============================================================
-- TOMMY LC — Guruh jadvali: dars kunlari va vaqti
-- Supabase > SQL Editor da bir marta ishga tushiring.
-- ============================================================

alter table public.groups add column if not exists lesson_days  text;   -- 'odd' (toq) | 'even' (juft) | null
alter table public.groups add column if not exists lesson_start text;   -- 'HH:MM' (masalan 14:00)
alter table public.groups add column if not exists lesson_end   text;   -- 'HH:MM' (masalan 15:30)

-- ============================================================
-- TAYYOR. (RLS o'zgarmaydi — groups jadvali allaqachon himoyalangan)
-- ============================================================
