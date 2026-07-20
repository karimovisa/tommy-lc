-- ============================================================================
-- Migration 022 — center_id DEFAULT = current_center()  (app inserts center-aware)
--
-- Muammo: ilovadagi to'g'ridan-to'g'ri INSERT'lar (groups, daily_checks, payments,
-- homework, notifications, messages, materials...) center_id ni O'RNATMAYDI ->
-- hardcoded Tommy default'ni oladi. Tommy admini uchun to'g'ri, lekin boshqa
-- markaz admini uchun RLS center_isolation bloklaydi (Tommy != current_center).
--
-- Yechim: har 16 biznes jadvalda center_id DEFAULT'ini
--   coalesce(current_center(), Tommy) ga o'zgartirish.
-- Endi har insert avtomatik JORIY foydalanuvchi markazini oladi (JWT claim).
-- JWT/claim bo'lmasa (service_role, SQL) -> Tommy fallback.
-- Edge Function'lar center_id ni ANIQ o'rnatadi (explicit) -> ular ta'sirlanmaydi.
--
-- SAFE / ADDITIVE: faqat DEFAULT o'zgaradi, mavjud qatorlar tegilmaydi.
-- Tommy: current_center()=Tommy -> avvalgidek. Sirius: current_center()=Sirius.
-- ============================================================================

do $$
declare
  t text;
  tables text[] := array[
    'admins', 'groups', 'profiles', 'students', 'daily_checks',
    'assignments', 'assignment_grades', 'homework', 'homework_done',
    'notifications', 'messages', 'payments', 'materials',
    'parent_links', 'login_history', 'lesson_confirms'
  ];
begin
  foreach t in array tables loop
    execute format(
      'alter table public.%I alter column center_id set default coalesce(public.current_center(), ''00000000-0000-0000-0000-000000000001''::uuid)',
      t
    );
  end loop;
end $$;
