-- ============================================================================
-- ROLLBACK for migration 018 — Custom domains
-- NOTE: this restores get_center_theme WITHOUT custom-domain matching
-- (the TASK 015 version). Subdomain + default resolution stay intact.
-- ============================================================================

drop policy if exists "read center_domains"   on public.center_domains;
drop policy if exists "manage center_domains" on public.center_domains;
drop table if exists public.center_domains;

create or replace function public.get_center_theme(p_host text)
returns table(
  center_id uuid, slug text, display_name text, brand_color text,
  student_id_prefix text, login_email_domain text, theme jsonb
)
language plpgsql stable security definer set search_path = public
as $$
declare v_slug text; v_cid uuid;
begin
  p_host := lower(coalesce(p_host, ''));
  if p_host like '%.isa-os.uz' then
    v_slug := split_part(p_host, '.', 1);
  end if;
  if v_slug is not null and v_slug <> '' then
    select c.id into v_cid from public.centers c
    where c.slug = v_slug and c.status <> 'suspended';
  end if;
  if v_cid is null then
    v_cid := '00000000-0000-0000-0000-000000000001';
  end if;
  return query
    select cb.center_id, c.slug, cb.display_name, cb.brand_color,
           cb.student_id_prefix, cb.login_email_domain, cb.theme
    from public.center_branding cb join public.centers c on c.id = cb.center_id
    where cb.center_id = v_cid;
end;
$$;
