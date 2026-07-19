-- ============================================================================
-- Migration 021 — brand asset storage (logo / favicon)
-- TASK 024 (part A) of the roadmap.
--
-- Creates a PUBLIC storage bucket "branding" for per-center logo/favicon, with
-- path convention  <center_id>/logo.<ext> , <center_id>/favicon.<ext>.
-- Public read (logos are public-facing); writes by platform admin (center-admin
-- self-upload can be added later with the admin UI).
--
-- Also extends get_center_theme() to return logo_url + favicon_url so the app
-- can load them. (columns already exist on center_branding.)
--
-- SAFE / ADDITIVE. Reversible via 021_brand_storage.down.sql
-- APPLY: run in the Supabase SQL editor.
-- ============================================================================

-- 1) Public bucket for brand assets
insert into storage.buckets (id, name, public)
values ('branding', 'branding', true)
on conflict (id) do nothing;

-- 2) Storage policies on the branding bucket
drop policy if exists "branding public read" on storage.objects;
create policy "branding public read"
  on storage.objects for select
  to anon, authenticated
  using (bucket_id = 'branding');

drop policy if exists "branding admin write" on storage.objects;
create policy "branding admin write"
  on storage.objects for all
  to authenticated
  using (bucket_id = 'branding' and public.is_platform_admin())
  with check (bucket_id = 'branding' and public.is_platform_admin());

-- 3) get_center_theme now also returns logo_url + favicon_url.
--    (RETURNS TABLE signature changes -> must drop then create.)
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
           cb.logo_url, cb.favicon_url
    from public.center_branding cb
    join public.centers c on c.id = cb.center_id
    where cb.center_id = v_cid;
end;
$$;

revoke execute on function public.get_center_theme(text) from public;
grant   execute on function public.get_center_theme(text) to anon, authenticated;
