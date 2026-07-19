-- ============================================================================
-- Migration 015 — atomic center provisioning
-- TASK 017 of the multi-tenant migration roadmap.
--
-- create_center() builds a whole tenant in ONE transaction: centers + branding
-- + settings + first center-admin + default feature flags. If any step fails
-- (e.g. duplicate slug) the whole call rolls back -> never a half-created center.
--
-- AUTH: callable by platform admins via RPC. When there is no JWT (service_role
-- in the SQL editor), the check is skipped so you can provision directly.
--
-- SAFE / ADDITIVE (function only). Reversible via 015_create_center.down.sql
-- APPLY: run in the Supabase SQL editor.
-- ============================================================================

create or replace function public.create_center(
  p_slug              text,
  p_name              text,
  p_admin_email       text default null,
  p_display_name      text default null,
  p_brand_color       text default '#4f46e5',
  p_student_id_prefix text default null,
  p_email_domain      text default null,
  p_timezone          text default 'Asia/Tashkent',
  p_language          text default 'uz',
  p_plan              text default 'starter'
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
begin
  -- enforce platform-admin only when called with a real user token (RPC)
  if auth.uid() is not null and not public.is_platform_admin() then
    raise exception 'Only platform admins can create centers';
  end if;

  insert into public.centers (slug, name, status, subscription_plan, timezone, language)
  values (lower(p_slug), p_name, 'trial', p_plan, p_timezone, p_language)
  returning id into v_id;

  insert into public.center_branding (center_id, display_name, brand_color, student_id_prefix, login_email_domain)
  values (v_id, coalesce(p_display_name, p_name), p_brand_color, p_student_id_prefix, p_email_domain);

  insert into public.center_settings (center_id) values (v_id);

  if p_admin_email is not null then
    insert into public.admins (email, center_id)
    values (lower(p_admin_email), v_id)
    on conflict (email) do nothing;
  end if;

  insert into public.feature_flags (center_id, feature, enabled)
  select v_id, f, true
  from unnest(array[
    'ai', 'crm', 'website', 'analytics', 'telegram',
    'homework', 'attendance', 'exams', 'payments', 'messaging', 'mobile'
  ]) as f;

  return v_id;
end;
$$;

revoke execute on function public.create_center(text,text,text,text,text,text,text,text,text,text) from anon;
grant   execute on function public.create_center(text,text,text,text,text,text,text,text,text,text) to authenticated;
