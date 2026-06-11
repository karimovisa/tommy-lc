# TOMMY Learning Centre

O'quv markazi uchun o'quvchi natijalarini kuzatuvchi web ilova (interfeys o'zbekcha).

## Tuzilma

| Yo'l | Tavsif |
|------|--------|
| `index.html` | Butun ilova — bitta self-contained fayl (HTML + CSS + JS, build yo'q) |
| `sql/` | Supabase SQL skriptlari (sxema, RLS, RPC) |
| `supabase/functions/admin-student/index.ts` | Edge Function — o'quvchi akkountini yaratish/parol tiklash (service_role server tomonda) |
| `docs/` | Dizayn tizimi hujjati |

## Stack

- **Frontend:** Vanilla JS, single-file HTML (framework yo'q, build yo'q)
- **Backend:** Supabase (Auth + REST + RLS + RPC + Edge Functions)
- **Deploy:** Netlify

## Rollar

- **Admin** — barcha guruhlarga to'liq kirish
- **O'qituvchi** — `groups.teacher_email` bo'yicha o'z guruhlari
- **O'quvchi / Ota-ona** — Student ID + parol bilan kirish

## SQL ishga tushirish tartibi (Supabase > SQL Editor)

1. `sql/rls-setup.sql` — RLS va helper funksiyalar
2. `sql/auth-schema.sql` — Student ID, status, generator, login tarixi
3. `sql/viewer-rank.sql` — o'quvchi reytingi RPC

So'ng `supabase/functions/admin-student/index.ts` ni Edge Function sifatida deploy qiling.

## Xavfsizlik

- `index.html` ichida faqat **anon key** bor (ommaviy, xavfsiz).
- `service_role` kaliti HECH QACHON kodga yozilmaydi — faqat Edge Function muhit o'zgaruvchisi (`SUPABASE_SERVICE_ROLE_KEY`) sifatida.
