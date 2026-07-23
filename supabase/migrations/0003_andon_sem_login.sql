-- ============================================================
-- Andon sem login (reformulação)
--
-- Remove o modelo com autenticação (profiles/PIN) e recria o andon para uso
-- SEM login: a identificação da operadora é apenas o número da mesa + etapa.
-- Como é uma ferramenta interna de piso, o papel anônimo (chave publishable)
-- tem acesso completo — não há dados pessoais, apenas sinais operacionais.
--
-- Aplicar:  SQL Editor do Supabase > cole este arquivo > Run.
-- (Substitui 0001 e 0002. A Edge Function admin-manage-user deixa de ser usada.)
-- ============================================================

create extension if not exists pgcrypto;

-- Remove o modelo antigo (com login) --------------------------------------
drop table if exists public.andon_events cascade;
drop table if exists public.profiles    cascade;
drop table if exists public.areas       cascade;
drop function if exists public.my_role()   cascade;
drop function if exists public.is_staff()  cascade;
drop function if exists public.is_admin()  cascade;
drop function if exists public.admin_update_profile(uuid,text,text,text,boolean) cascade;

-- Chamados ----------------------------------------------------------------
-- type:  falta_material (Material Handler), qualidade (Coordenação Técnica),
--        inspecao (Inspeção), assistente (Assistente)
-- mesa:  1..25 (apenas para chamados abertos por operadoras)
-- etapa: supervisão da operadora (SVE, SVS, Anel Revestido, ...)
create table public.andon_events (
  id          uuid primary key default gen_random_uuid(),
  type        text not null check (type in ('falta_material','qualidade','inspecao','assistente')),
  mesa        int  check (mesa between 1 and 25),
  etapa       text,
  status      text not null default 'aberto' check (status in ('aberto','resolvido','cancelado')),
  created_at  timestamptz not null default now(),
  resolved_at timestamptz
);
create index andon_events_open_idx on public.andon_events (type, status, created_at);
create index andon_events_mesa_idx on public.andon_events (mesa, status);

-- Configuração de mesas disponíveis por etapa (editada pelo Assistente) -----
-- mesas vazio  -> todas as 25 disponíveis; caso contrário, apenas as listadas.
create table public.etapa_config (
  etapa       text primary key,
  mesas       int[] not null default '{}'::int[],
  updated_at  timestamptz not null default now()
);

-- Realtime ----------------------------------------------------------------
do $$
begin
  begin execute 'alter publication supabase_realtime add table public.andon_events';
  exception when duplicate_object then null; end;
  begin execute 'alter publication supabase_realtime add table public.etapa_config';
  exception when duplicate_object then null; end;
end $$;

-- RLS: ferramenta interna sem login -> papel anônimo tem acesso completo -----
alter table public.andon_events enable row level security;
alter table public.etapa_config enable row level security;

drop policy if exists andon_anon_all on public.andon_events;
create policy andon_anon_all on public.andon_events
  for all to anon, authenticated using (true) with check (true);

drop policy if exists etapa_anon_all on public.etapa_config;
create policy etapa_anon_all on public.etapa_config
  for all to anon, authenticated using (true) with check (true);
