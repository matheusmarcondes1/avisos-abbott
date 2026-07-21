-- ============================================================
-- Notificações de andon nas TVs (painel de avisos)
--
-- O painel das TVs assina os chamados em tempo real usando apenas a chave
-- publishable (sem login), para exibir a notificação sobre o relógio. Para
-- isso, o papel anônimo precisa poder LER os chamados ATIVOS.
--
-- Escopo mínimo: apenas linhas com status 'aberto' ou 'em_atendimento', e
-- somente leitura. As demais operações continuam exigindo login (ver
-- 0001_andon_pager.sql). As informações expostas (área, tipo, nome, horário)
-- são as mesmas já exibidas publicamente nas TVs do piso.
--
-- Se preferir NÃO expor nada ao papel anônimo, não aplique esta migração e,
-- em vez disso, configure o painel para usar uma conta de exibição
-- (material_handler) — nesse caso, remova esta política.
--
-- Aplicar:  SQL Editor do Supabase > cole este arquivo > Run.
-- ============================================================

drop policy if exists andon_read_tv on public.andon_events;
create policy andon_read_tv on public.andon_events
  for select to anon
  using (status in ('aberto','em_atendimento'));
