-- ============================================================================
-- TASK 009 (stage 2) — ISOLATION GATE TEST  (read-only, rolls back)
--
-- Simulates a DEMO center-admin session (via request.jwt.claims) and checks that
-- it can see its OWN center's rows but ZERO of Tommy's rows.
-- Every "LEAK if > 0" row MUST return 0. If any is > 0 -> STOP the roadmap.
--
-- Safe: wrapped in a transaction that ROLLS BACK; changes nothing.
-- Run AFTER 008_demo_center.sql.
-- ============================================================================

begin;

set local role authenticated;
set local "request.jwt.claims" =
  '{"role":"authenticated","email":"demo-admin@demo.test","center_id":"00000000-0000-0000-0000-000000000002"}';

select 'demo: OWN groups visible (expect 1)'          as test, count(*) as cnt from public.groups
union all
select 'demo: TOMMY groups visible (LEAK if >0)',      count(*) from public.groups   where center_id = '00000000-0000-0000-0000-000000000001'
union all
select 'demo: TOMMY students visible (LEAK if >0)',    count(*) from public.students  where center_id = '00000000-0000-0000-0000-000000000001'
union all
select 'demo: TOMMY payments visible (LEAK if >0)',    count(*) from public.payments  where center_id = '00000000-0000-0000-0000-000000000001'
union all
select 'demo: TOMMY messages visible (LEAK if >0)',    count(*) from public.messages  where center_id = '00000000-0000-0000-0000-000000000001'
union all
select 'demo: TOMMY daily_checks visible (LEAK if >0)',count(*) from public.daily_checks where center_id = '00000000-0000-0000-0000-000000000001'
order by test;

rollback;
