-- ============================================================
-- Série das Reuniões de N2: seleção automática como padrão
--
-- Passa o painel a escolher a série (turno) pelo horário atual, em vez de
-- ficar fixo numa série. Vale para todas as TVs.
--
-- Aplicar:  SQL Editor do Supabase > cole este arquivo > Run.
-- (A escolha continua editável em Configurações › Comportamento.)
-- ============================================================

insert into public.panel_settings (id, auto_series, active_series_id)
values (1, true, null)
on conflict (id) do update
  set auto_series = true,
      active_series_id = null,
      updated_at = now();
