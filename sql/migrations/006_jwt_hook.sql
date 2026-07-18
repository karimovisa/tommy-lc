-- ============================================================================
-- Migration 006 — Custom Access Token Hook (center_id in the JWT)
-- TASK 007 of the multi-tenant migration roadmap.
--
-- Adds two claims to every newly-minted access token:
--   center_id          -> the user's learning center (for fast RLS in TASK 008)
--   is_platform_admin  -> true for ISA OS owners (RLS bypass / platform UI)
--
-- Center is resolved by role: profiles (student/parent) -> teacher (by email)
-- -> center admin (by email). Platform admins may have no center; that's fine.
--
-- SAFETY: the function is wrapped in an exception handler that returns the
-- token UNCHANGED on ANY error, so a bug can never lock users out of login.
--
-- TWO-STEP ACTIVATION:
--   1) run this SQL  (creates + permissions the function; does NOTHING yet)
--   2) Dashboard -> Authentication -> Hooks -> "Custom Access Token" ->
--      enable and select  public.custom_access_token_hook
--   Claims appear only in tokens minted AFTER step 2 (re-login / refresh).
--
-- ROLLBACK: disable the hook in the Dashboard, then run 006_jwt_hook.down.sql
-- ============================================================================

create or replace function public.custom_access_token_hook(event jsonb)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  claims jsonb := coalesce(event -> 'claims', '{}'::jsonb);
  uid    uuid;
  cid    uuid;
  is_pa  boolean := false;
begin
  begin
    uid := (event ->> 'user_id')::uuid;

    -- platform admin?
    select exists(select 1 from platform_admins where user_id = uid) into is_pa;

    -- resolve center: student/parent -> teacher -> center admin
    select center_id into cid from profiles where id = uid limit 1;

    if cid is null then
      select g.center_id into cid
      from groups g
      join auth.users u on lower(u.email) = lower(g.teacher_email)
      where u.id = uid
      limit 1;
    end if;

    if cid is null then
      select a.center_id into cid
      from admins a
      join auth.users u on lower(u.email) = lower(a.email)
      where u.id = uid
      limit 1;
    end if;

    if cid is not null then
      claims := jsonb_set(claims, '{center_id}', to_jsonb(cid::text));
    end if;
    claims := jsonb_set(claims, '{is_platform_admin}', to_jsonb(is_pa));

    event := jsonb_set(event, '{claims}', claims);
  exception when others then
    -- never break authentication
    return event;
  end;

  return event;
end;
$$;

-- Only the auth system may call the hook.
grant execute on function public.custom_access_token_hook(jsonb) to supabase_auth_admin;
revoke execute on function public.custom_access_token_hook(jsonb) from authenticated, anon, public;
