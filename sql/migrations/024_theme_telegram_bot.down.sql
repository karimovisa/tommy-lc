-- ============================================================================
-- ROLLBACK for migration 024 — reverts get_center_theme to the 021 signature
-- (drops telegram_bot_username from the returned columns).
-- ============================================================================

drop function if exists public.get_center_theme(text);

create function public.get_center_theme(p_host text)
returns table(
  center_id          uuid,
  slug               text,
  display_name       text,
  brand_color        text,
  student_id_prefix  text,
  login_email_domain text,
  theme              jsonb,
  logo_url           text,
  favicon_url        text
)
language plpgsql stable security definer set search_path = public
as $$
declare v_slug text; v_cid uuid; v_base text;
begin
  p_host := lower(coalesce(p_host, ''));
  v_base := lower(coalesce((select value from public.platform_settings where key='base_domain'), 'lcos.uz'));
  select cd.center_id into v_cid from public.center_domains cd where cd.domain = p_host and cd.verified = true;
  if v_cid is null and p_host like ('%.' || v_base) then
    v_slug := split_part(p_host, '.', 1);
    if v_slug <> '' then
      select c.id into v_cid from public.centers c where c.slug = v_slug and c.status <> 'suspended';
    end if;
  end if;
  if v_cid is null then v_cid := '00000000-0000-0000-0000-000000000001'; end if;
  return query
    select cb.center_id, c.slug, cb.display_name, cb.brand_color,
           cb.student_id_prefix, cb.login_email_domain, cb.theme,
           cb.logo_url, cb.favicon_url
    from public.center_branding cb join public.centers c on c.id = cb.center_id
    where cb.center_id = v_cid;
end;
$$;

revoke execute on function public.get_center_theme(text) from public;
grant execute on function public.get_center_theme(text) to anon, authenticated;
