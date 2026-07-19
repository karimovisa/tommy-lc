-- ============================================================================
-- Migration 018 — Custom domains
-- TASK 019 of the multi-tenant migration roadmap.
--
-- Lets a center map its own domain (tommylc.uz) to itself, in addition to the
-- <slug>.isa-os.uz subdomain. get_center_theme() is extended to resolve a
-- verified custom domain first, then subdomain, then the default center.
--
-- SAFE / ADDITIVE. Reversible via 018_custom_domains.down.sql
-- APPLY: run in the Supabase SQL editor (idempotent).
-- ============================================================================

create table if not exists public.center_domains (
  id         uuid primary key default gen_random_uuid(),
  center_id  uuid not null references public.centers(id) on delete cascade,
  domain     text not null unique,
  verified   boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists idx_center_domains_center on public.center_domains(center_id);

-- Routing: custom domain (verified) -> subdomain of isa-os.uz -> default center
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

  -- 1) verified custom domain
  select cd.center_id into v_cid
  from public.center_domains cd
  where cd.domain = p_host and cd.verified = true;

  -- 2) subdomain of isa-os.uz
  if v_cid is null and p_host like '%.isa-os.uz' then
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

-- RLS: platform admin manages; a center reads its own domains.
alter table public.center_domains enable row level security;
drop policy if exists "read center_domains" on public.center_domains;
create policy "read center_domains" on public.center_domains for select to authenticated
  using (public.is_platform_admin() or center_id = public.current_center());
drop policy if exists "manage center_domains" on public.center_domains;
create policy "manage center_domains" on public.center_domains for all to authenticated
  using (public.is_platform_admin()) with check (public.is_platform_admin());
