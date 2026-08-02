-- ============================================================================
-- Migration 024 — get_center_theme also returns telegram_bot_username
-- WHITE-LABEL FAZA 2.
--
-- The parent-panel Telegram "connect" link was hardcoded to tommy_lc_bot.
-- For a white-label (multi-center) template each center has its own bot, so the
-- app must read the per-center @username from the DB. center_branding already
-- has telegram_bot_username (migration 003); this just surfaces it through the
-- host-resolver so loadBranding() can pick it up (same pattern as 021 did for
-- logo_url / favicon_url).
--
-- SAFE / ADDITIVE. Reversible via 024_theme_telegram_bot.down.sql
-- APPLY: run in the Supabase SQL editor.
-- ============================================================================

drop function if exists public.get_center_theme(text);

create function public.get_center_theme(p_host text)
returns table(
  center_id             uuid,
  slug                  text,
  display_name          text,
  brand_color           text,
  student_id_prefix     text,
  login_email_domain    text,
  theme                 jsonb,
  logo_url              text,
  favicon_url           text,
  telegram_bot_username text
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_slug text;
  v_cid  uuid;
  v_base text;
begin
  p_host := lower(coalesce(p_host, ''));
  v_base := lower(coalesce(
    (select value from public.platform_settings where key = 'base_domain'),
    'lcos.uz'
  ));

  -- 1) verified custom domain
  select cd.center_id into v_cid
  from public.center_domains cd
  where cd.domain = p_host and cd.verified = true;

  -- 2) subdomain of the configured base domain
  if v_cid is null and p_host like ('%.' || v_base) then
    v_slug := split_part(p_host, '.', 1);
    if v_slug <> '' then
      select c.id into v_cid
      from public.centers c
      where c.slug = v_slug and c.status <> 'suspended';
    end if;
  end if;

  -- 3) default / founder center
  if v_cid is null then
    v_cid := '00000000-0000-0000-0000-000000000001';
  end if;

  return query
    select cb.center_id, c.slug, cb.display_name, cb.brand_color,
           cb.student_id_prefix, cb.login_email_domain, cb.theme,
           cb.logo_url, cb.favicon_url, cb.telegram_bot_username
    from public.center_branding cb
    join public.centers c on c.id = cb.center_id
    where cb.center_id = v_cid;
end;
$$;

revoke execute on function public.get_center_theme(text) from public;
grant   execute on function public.get_center_theme(text) to anon, authenticated;
