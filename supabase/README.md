# Andon — configuração do Supabase (sem login)

Backend do módulo de andon: **Postgres + Realtime**, sem autenticação. A plataforma é uma
ferramenta interna de piso; a identificação da operadora é apenas **número da mesa + etapa**.
O acesso é feito com a **chave publishable** e as tabelas ficam abertas ao papel anônimo via RLS
(não há dados pessoais — apenas sinais operacionais de chamado).

## 1. Aplicar o esquema

**SQL Editor → New query →** cole [`migrations/0003_andon_sem_login.sql`](migrations/0003_andon_sem_login.sql)
**→ Run**.

Esse arquivo **substitui** os anteriores (0001 e 0002): remove o modelo com login (profiles/PIN) e
recria `andon_events` e `etapa_config` para uso anônimo, com Realtime habilitado. Se você já tinha
aplicado o 0001/0002, tudo bem — o 0003 dá `drop` no que for necessário e recria.

> Os arquivos `0001_*` e `0002_*` ficam no histórico apenas como referência; **não** precisam ser
> aplicados. A Edge Function `admin-manage-user` foi removida (não há mais usuários).

## 2. Conectar o app

A URL e a chave publishable já estão em [`andon/config.js`](../andon/config.js). Para outro projeto,
troque os valores lá (ou use a tela de configuração do próprio app na primeira abertura).

## 3. Pronto

Abra o `andon/` e siga o fluxo:
- **Operadora** → escolhe a etapa e a mesa → tela de chamados (Falta de Material, Qualidade,
  Inspeção, Assistente).
- **Material Handler / Coordenação Técnica / Inspeção / Assistente** → veem a fila de chamados do
  seu tipo, em tempo real, e concluem no ✓.
- **Assistente** → além da fila, tem **Estatísticas** (com exportação CSV/Excel) e **Mesas**
  (define quais mesas ficam disponíveis por etapa).

## Modelo de dados

| Tabela          | Papel                                                                   |
|-----------------|-------------------------------------------------------------------------|
| `andon_events`  | chamados: tipo, mesa, etapa, status, horários                           |
| `etapa_config`  | mesas disponíveis por etapa (vazio = todas as 25)                       |

Tipos de chamado e destino:

| Tipo             | Aciona               | Cor      |
|------------------|----------------------|----------|
| `falta_material` | Material Handler     | amarelo  |
| `qualidade`      | Coordenação Técnica  | roxo     |
| `inspecao`       | Inspeção             | laranja  |
| `assistente`     | Assistentes          | verde    |

Fluxo de status: `aberto → resolvido` (concluído pelo receptor) ou `cancelado` (pela operadora).

## Segurança

Sem login por decisão de uso (piso). As tabelas expõem apenas dados operacionais (tipo, mesa,
etapa, horário) — sem nomes ou informação pessoal. Se no futuro quiser restringir escrita/leitura,
dá para reintroduzir uma camada de autenticação leve; me avise.
