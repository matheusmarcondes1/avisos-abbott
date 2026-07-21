-- ============================================================
-- Andon para Produção — esquema (Supabase / Postgres)
--
-- Plataforma genérica de andon/pager, de código aberto.
-- Autenticação: Supabase Auth (matrícula -> e-mail sintético + PIN).
-- O PIN NUNCA é armazenado em texto — o Supabase Auth guarda apenas o hash
-- (bcrypt). Todo acesso a dados é protegido por Row Level Security (RLS):
-- sem login válido, a chave publishable não lê nem escreve nada.
--
-- Como aplicar:  SQL Editor do Supabase > cole este arquivo > Run.
-- Depois de aplicar, siga o supabase/README.md para:
--   1) desativar a confirmação de e-mail (Auth > Providers > Email);
--   2) criar o primeiro usuário admin.
-- ============================================================

create extension if not exists pgcrypto;

-- ------------------------------------------------------------
-- Áreas / supervisões do piso (as mesmas usadas nas reuniões)
-- ------------------------------------------------------------
create table if not exists public.areas (
  name        text primary key,
  sort_order  int not null default 100,
  active      boolean not null default true
);

insert into public.areas (name, sort_order) values
  ('Material Biológico', 10),
  ('SVE',                20),
  ('SVS',                30),
  ('Anel Revestido',     40),
  ('Sizing & Trimming',  50),
  ('Revisão Final',      60)
on conflict (name) do nothing;

-- ------------------------------------------------------------
-- Perfis (1:1 com auth.users). A credencial (PIN) vive em auth.users.
-- ------------------------------------------------------------
create table if not exists public.profiles (
  id            uuid primary key references auth.users(id) on delete cascade,
  matricula     text unique not null,
  display_name  text not null,
  area          text references public.areas(name) on update cascade,
  role          text not null default 'operator'
                 check (role in ('operator','material_handler','admin')),
  active        boolean not null default true,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create index if not exists profiles_matricula_idx on public.profiles (matricula);
create index if not exists profiles_area_idx      on public.profiles (area);

-- ------------------------------------------------------------
-- Chamados (andon)
-- type:   tipo da ocorrência
-- status: aberto -> em_atendimento -> resolvido (ou cancelado)
-- Os campos display_name/area são desnormalizados no momento do chamado,
-- preservando o histórico mesmo que o perfil mude depois.
-- ------------------------------------------------------------
create table if not exists public.andon_events (
  id                 uuid primary key default gen_random_uuid(),
  raised_by          uuid references public.profiles(id) on delete set null,
  display_name       text,
  area               text,
  type               text not null default 'falta_material'
                      check (type in ('falta_material','qualidade','manutencao','seguranca','outro')),
  note               text check (note is null or char_length(note) <= 280),
  status             text not null default 'aberto'
                      check (status in ('aberto','em_atendimento','resolvido','cancelado')),
  acknowledged_by    uuid references public.profiles(id) on delete set null,
  acknowledged_name  text,
  acknowledged_at    timestamptz,
  resolved_at        timestamptz,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now()
);

create index if not exists andon_events_status_idx on public.andon_events (status, created_at desc);
create index if not exists andon_events_area_idx   on public.andon_events (area, status);
create index if not exists andon_events_raiser_idx on public.andon_events (raised_by, created_at desc);

-- ------------------------------------------------------------
-- updated_at automático
-- ------------------------------------------------------------
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

drop trigger if exists profiles_touch on public.profiles;
create trigger profiles_touch before update on public.profiles
  for each row execute function public.touch_updated_at();

drop trigger if exists andon_events_touch on public.andon_events;
create trigger andon_events_touch before update on public.andon_events
  for each row execute function public.touch_updated_at();

-- ------------------------------------------------------------
-- Funções auxiliares de papel (SECURITY DEFINER para evitar recursão de RLS)
-- ------------------------------------------------------------
create or replace function public.my_role()
returns text language sql stable security definer set search_path = public as $$
  select role from public.profiles where id = auth.uid() and active
$$;

create or replace function public.is_staff()
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce((select role in ('material_handler','admin')
                   from public.profiles where id = auth.uid() and active), false)
$$;

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce((select role = 'admin'
                   from public.profiles where id = auth.uid() and active), false)
$$;

-- ------------------------------------------------------------
-- Row Level Security
--   * anon (chave publishable sem login): NENHUM acesso.
--   * operator: vê/gerencia apenas os próprios chamados.
--   * material_handler/admin: veem tudo e atendem.
-- ------------------------------------------------------------
alter table public.areas        enable row level security;
alter table public.profiles     enable row level security;
alter table public.andon_events enable row level security;

-- Áreas: qualquer usuário autenticado lê; alteração só admin.
drop policy if exists areas_read on public.areas;
create policy areas_read on public.areas
  for select to authenticated using (true);

drop policy if exists areas_admin on public.areas;
create policy areas_admin on public.areas
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- Perfis: o próprio usuário lê o seu; staff lê todos.
drop policy if exists profiles_read on public.profiles;
create policy profiles_read on public.profiles
  for select to authenticated
  using (id = auth.uid() or public.is_staff());

-- Perfis: criação/edição são feitas por rotina administrativa (SECURITY DEFINER)
-- ou pelo painel do Supabase — não há política de escrita direta pelo cliente.

-- Chamados: operador vê os próprios; staff vê todos.
drop policy if exists andon_read on public.andon_events;
create policy andon_read on public.andon_events
  for select to authenticated
  using (raised_by = auth.uid() or public.is_staff());

-- Chamados: o usuário autenticado abre um chamado em seu próprio nome.
drop policy if exists andon_insert on public.andon_events;
create policy andon_insert on public.andon_events
  for insert to authenticated
  with check (raised_by = auth.uid() and status = 'aberto');

-- Chamados: staff atende (assume/resolve/cancela) qualquer chamado.
drop policy if exists andon_update_staff on public.andon_events;
create policy andon_update_staff on public.andon_events
  for update to authenticated
  using (public.is_staff()) with check (public.is_staff());

-- Chamados: o autor pode cancelar o próprio chamado ainda em aberto/atendimento.
drop policy if exists andon_cancel_own on public.andon_events;
create policy andon_cancel_own on public.andon_events
  for update to authenticated
  using (raised_by = auth.uid() and status in ('aberto','em_atendimento'))
  with check (raised_by = auth.uid() and status = 'cancelado');

-- ------------------------------------------------------------
-- Rotinas administrativas de perfil (guardadas por is_admin()).
-- Criam/editam o PERFIL. A credencial (usuário Auth) é criada pela
-- Edge Function admin-manage-user ou pelo painel do Supabase.
-- ------------------------------------------------------------
create or replace function public.admin_update_profile(
  p_id uuid, p_display_name text, p_area text, p_role text, p_active boolean)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then
    raise exception 'apenas administradores' using errcode = '42501';
  end if;
  if p_role not in ('operator','material_handler','admin') then
    raise exception 'papel inválido';
  end if;
  update public.profiles
     set display_name = coalesce(p_display_name, display_name),
         area         = p_area,
         role         = p_role,
         active       = coalesce(p_active, active)
   where id = p_id;
end $$;

revoke all on function public.admin_update_profile(uuid,text,text,text,boolean) from public;
grant execute on function public.admin_update_profile(uuid,text,text,text,boolean) to authenticated;

-- ------------------------------------------------------------
-- Realtime: os painéis (operador, material handler, TVs) assinam mudanças.
-- ------------------------------------------------------------
do $$
begin
  begin execute 'alter publication supabase_realtime add table public.andon_events';
  exception when duplicate_object then null; end;
end $$;
