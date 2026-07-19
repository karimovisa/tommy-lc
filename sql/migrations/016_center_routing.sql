-- ============================================================================
-- Migration 016 — host -> center resolution (routing)
-- TASK 015 of the multi-tenant migration roadmap.
--
-- get_center_theme(host) resolves a hostname to the right center and returns its
-- PUBLIC branding. The app calls this (instead of "first branding row") so that
-- with many centers each subdomain loads its own theme/email-domain.
--
-- Resolution:
--   <slug>.isa-os.uz          -> center with that slug
--   anything else / no match  -> the default (founder) center = Tommy
-- Custom domains (TASK 019) extend this later.
--
-- SECURITY DEFINER so it can read the RLS-protected centers table, but it only
-- ever returns public branding columns. Callable by anon (pre-login theming).
--
-- SAFE / ADDITIVE (function only). Reversible via 016_center_routing.down.sql
-- APPLY: run in the Supabase SQL editor.
-- ============================================================================

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
begin
  p_host := lower(coalesce(p_host, ''));

  -- subdomain of isa-os.uz -> slug
  if p_host like '%.isa-os.uz' then
    v_slug := split_part(p_host, '.', 1);
  end if;

  if v_slug is not null and v_slug <> '' then
    select c.id into v_cid
    from public.centers c
    where c.slug = v_slug and c.status <> 'suspended';
  end if;

  -- default / founder center when nothing matched
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
