-- ============================================================================
-- Migration 019 — platform_settings (configurable base domain)
-- Refinement on TASK 015/019: the subdomain base is no longer hardcoded.
--
-- Instead of matching a literal ".isa-os.uz", get_center_theme() reads the base
-- domain from platform_settings. Change one row to rebrand the whole platform's
-- subdomain space (e.g. lcos.uz -> anything) without touching code.
--
-- SAFE / ADDITIVE. Reversible via 019_platform_settings.down.sql
-- APPLY: run in the Supabase SQL editor (idempotent).
-- ============================================================================

-- key/value platform config (single source for platform-wide settings)
create table if not exists public.platform_settings (
  key   text primary key,
  value text
);

insert into public.platform_settings (key, value)
values ('base_domain', 'lcos.uz')
on conflict (key) do nothing;

-- RLS: platform admins only (the routing function is security definer and
-- reads it regardless of RLS).
alter table public.platform_settings enable row level security;
drop policy if exists "platform admins manage platform_settings" on public.platform_settings;
create policy "platform admins manage platform_settings"
  on public.platform_settings for all to authenticated
  using (public.is_platform_admin()) with check (public.is_platform_admin());

-- Routing: verified custom domain -> subdomain of <base_domain> -> default center
create or replace function public.get_center_theme(p_host text)
returns table(
  center_id          uuid,
  slug               text,
  display_name       text,
  brand_color        text,
  student_id_prefix  text,
  login_email_domain text,
  theme              jsonb
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
           cb.student_id_prefix, cb.login_email_domain, cb.theme
    from public.center_branding cb
    join public.centers c on c.id = cb.center_id
    where cb.center_id = v_cid;
end;
$$;

revoke execute on function public.get_center_theme(text) from public;
grant   execute on function public.get_center_theme(text) to anon, authenticated;
