-- ============================================================================
-- Migration 008 — Demo LC (TEMPORARY test tenant for the isolation gate)
-- TASK 009 (stage 1) of the multi-tenant migration roadmap.
--
-- Creates a second center + minimal data so we can prove that Demo cannot see
-- Tommy's data and vice-versa. This is TEST data: remove it with the .down.sql
-- once the gate passes (before onboarding real second customers).
--
-- Demo center id = 00000000-0000-0000-0000-000000000002 (Tommy = ...0001)
--
-- APPLY:   run in the Supabase SQL editor (idempotent).
-- ROLLBACK: run 008_demo_center.down.sql
-- ============================================================================

-- Demo center
insert into public.centers (id, slug, name, status, subscription_plan, timezone, language)
values ('00000000-0000-0000-0000-000000000002', 'demo', 'Demo Learning Center', 'trial', 'starter', 'Asia/Tashkent', 'uz')
on conflict (id) do nothing;

insert into public.center_branding (center_id, display_name, brand_color, font_family, student_id_prefix, login_email_domain)
values ('00000000-0000-0000-0000-000000000002', 'Demo LC', '#2563eb', 'Plus Jakarta Sans', 'DLC', 'students.demo.test')
on conflict (center_id) do nothing;

insert into public.center_settings (center_id)
values ('00000000-0000-0000-0000-000000000002')
on conflict (center_id) do nothing;

-- Demo center admin (email in admins, scoped to Demo). NOT a platform admin.
insert into public.admins (email, center_id)
values ('demo-admin@demo.test', '00000000-0000-0000-0000-000000000002')
on conflict (email) do nothing;

-- Demo group (so the Demo admin has 1 own row to see)
insert into public.groups (name, teacher_name, teacher_email, center_id)
select 'Demo Group A', 'Demo Teacher', 'demo-teacher@demo.test', '00000000-0000-0000-0000-000000000002'
where not exists (
  select 1 from public.groups
  where name = 'Demo Group A' and center_id = '00000000-0000-0000-0000-000000000002'
);
