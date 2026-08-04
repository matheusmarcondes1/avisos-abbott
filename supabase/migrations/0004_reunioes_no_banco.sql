-- ============================================================
-- Horários das reuniões no banco
--
-- Move o cronograma das reuniões (séries/janelas das Escalonadas e períodos
-- de N1) do navegador para o banco. Assim a informação não fica no HTML nem
-- no armazenamento local: é cadastrada uma vez e vale para todas as TVs, que
-- recebem as alterações na hora (Realtime).
--
-- Sem login, como o restante da plataforma: o papel anônimo tem acesso via
-- RLS (dados operacionais, sem informação pessoal).
--
-- Aplicar:  SQL Editor do Supabase > cole este arquivo > Run.
-- ============================================================

create extension if not exists pgcrypto;

-- ------------------------------------------------------------
-- Séries (turnos): ex. "Turno da Manhã", "Turno da Tarde"
-- ------------------------------------------------------------
create table if not exists public.meeting_series (
  id          uuid primary key default gen_random_uuid(),
  nome        text not null,
  sort_order  int  not null default 100,
  created_at  timestamptz not null default now()
);

-- ------------------------------------------------------------
-- Janelas das Reuniões Escalonadas
-- inicio/fim: minutos desde 00:00 (ex.: 9h00 = 540)
-- cadeia: 0=DOM … 6=SÁB (dia da Cadeia de Ajuda) ou NULL
-- ------------------------------------------------------------
create table if not exists public.meeting_windows (
  id          uuid primary key default gen_random_uuid(),
  series_id   uuid not null references public.meeting_series(id) on delete cascade,
  inicio      int  not null check (inicio between 0 and 1439),
  fim         int  not null check (fim between 1 and 1440),
  area        text not null default '',
  supervisor  text not null default '',
  cadeia      int  check (cadeia between 0 and 6),
  created_at  timestamptz not null default now(),
  check (fim > inicio)
);
create index if not exists meeting_windows_series_idx on public.meeting_windows (series_id, inicio);

-- ------------------------------------------------------------
-- Períodos das Reuniões de N1
-- ------------------------------------------------------------
create table if not exists public.n1_periods (
  id          uuid primary key default gen_random_uuid(),
  inicio      int not null check (inicio between 0 and 1439),
  fim         int not null check (fim between 1 and 1440),
  created_at  timestamptz not null default now(),
  check (fim > inicio)
);

-- ------------------------------------------------------------
-- Ajustes compartilhados do painel (linha única)
-- active_series_id NULL + auto_series true  -> série escolhida pelo horário
-- ------------------------------------------------------------
create table if not exists public.panel_settings (
  id                int primary key default 1 check (id = 1),
  active_series_id  uuid references public.meeting_series(id) on delete set null,
  auto_series       boolean not null default false,
  n1_enabled        boolean not null default true,
  n1_titulo         text not null default 'Reuniões de N1 em andamento',
  n1_mensagem       text not null default 'Agora é a hora de rever o dia anterior.',
  updated_at        timestamptz not null default now()
);

-- ------------------------------------------------------------
-- Realtime: as TVs recebem as alterações na hora
-- ------------------------------------------------------------
do $$
declare t text;
begin
  foreach t in array array['meeting_series','meeting_windows','n1_periods','panel_settings'] loop
    begin execute format('alter publication supabase_realtime add table public.%I', t);
    exception when duplicate_object then null; end;
  end loop;
end $$;

-- ------------------------------------------------------------
-- RLS: ferramenta interna sem login (mesmo critério do andon)
-- ------------------------------------------------------------
alter table public.meeting_series  enable row level security;
alter table public.meeting_windows enable row level security;
alter table public.n1_periods      enable row level security;
alter table public.panel_settings  enable row level security;

drop policy if exists series_anon_all on public.meeting_series;
create policy series_anon_all on public.meeting_series
  for all to anon, authenticated using (true) with check (true);

drop policy if exists windows_anon_all on public.meeting_windows;
create policy windows_anon_all on public.meeting_windows
  for all to anon, authenticated using (true) with check (true);

drop policy if exists n1_anon_all on public.n1_periods;
create policy n1_anon_all on public.n1_periods
  for all to anon, authenticated using (true) with check (true);

drop policy if exists settings_anon_all on public.panel_settings;
create policy settings_anon_all on public.panel_settings
  for all to anon, authenticated using (true) with check (true);

-- ------------------------------------------------------------
-- Carga inicial (só roda se ainda não houver séries cadastradas)
-- ------------------------------------------------------------
do $$
declare manha uuid; tarde uuid;
begin
  if exists (select 1 from public.meeting_series) then return; end if;

  insert into public.meeting_series (nome, sort_order) values ('Turno da Manhã', 10)
    returning id into manha;
  insert into public.meeting_series (nome, sort_order) values ('Turno da Tarde', 20)
    returning id into tarde;

  insert into public.meeting_windows (series_id, inicio, fim, area, supervisor, cadeia) values
    (manha, 540, 555, 'Material Biológico', 'Márcia',    2),
    (manha, 540, 555, 'SVE',                'Deivid',    4),
    (manha, 560, 575, 'Anel Revestido',     'Henrique',  2),
    (manha, 560, 575, 'SVE',                'Julia',     4),
    (manha, 560, 575, 'SVS',                'Silvia',    5),
    (manha, 580, 595, 'Sizing & Trimming',  'Guilherme', 2),
    (manha, 580, 595, 'SVE',                'Inês',      4),
    (manha, 580, 595, 'Revisão Final',      'Regina',    5);

  -- a série da tarde começa como cópia da manhã, para ser ajustada na tela
  insert into public.meeting_windows (series_id, inicio, fim, area, supervisor, cadeia)
    select tarde, inicio, fim, area, supervisor, cadeia
      from public.meeting_windows where series_id = manha;

  insert into public.n1_periods (inicio, fim) values (480, 540), (840, 900);

  insert into public.panel_settings (id, active_series_id, auto_series)
    values (1, manha, false)
    on conflict (id) do nothing;
end $$;
