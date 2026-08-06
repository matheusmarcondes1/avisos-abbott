# Andon para Produção: plataforma genérica e de código aberto

Plataforma **genérica de andon/pager para ambientes de produção**, criada por **iniciativa
própria** e distribuída como **software livre** (licença MIT). Reúne dois módulos que rodam
inteiramente no navegador, sem instalação e sem integração com sistemas corporativos:

1. **Painel de Avisos** (`index.html`): telas para projeção em TVs do piso: reuniões
   escalonadas (N1 e N2), busca por itens, avisos gerais, silêncio, microfone (push-to-talk) e
   relógio. Os horários das reuniões ficam no banco e valem para todas as TVs.
2. **Andon** (`andon/`): chamados de produção em tempo real (ex.: *falta de material*),
   **sem login** — a operadora é identificada por mesa/etapa e cada perfil (Material Handler,
   Coordenação Técnica, Inspeção, Assistente) acompanha e atende em um painel ao vivo. Usa
   [Supabase](https://supabase.com) (Postgres + Realtime).

> **Disclaimer.** Projeto pessoal, de código aberto, criado por iniciativa própria. É uma
> plataforma **genérica** de andon para produção, não é um produto oficial de nenhuma
> empresa e não se integra a sistemas corporativos. Guarda apenas os **horários das reuniões**
> cadastrados no próprio sistema e os **sinais operacionais de chamado** (tipo, mesa, etapa,
> horário) usados para coordenar o atendimento — **nenhuma informação pessoal**.

---

## Módulo 1: Painel de Avisos (`index.html`)

Arquivo estático único. Abre no **menu principal**, de onde se escolhe a função: Reuniões
Escalonadas, Busca por Válvulas/itens, Aviso Geral, Silêncio, Microfone e Relógio. O painel não
força tela cheia — use o **F11** do navegador quando quiser.

**Reuniões Escalonadas** reúne as duas reuniões do dia: **N1** (revisão do dia anterior) e
**N2** (cronograma escalonado por área). Ao abrir, escolhe-se qual acompanhar. Na tela de N2 dá
para escolher a **série** a projetar (manhã, tarde…) — com aviso quando o cronograma daquela série
está longe do horário atual.

**Planejamento** mostra a linha do tempo do dia: uma coluna proporcional ao horário com uma marca
que acompanha o relógio, indicando **em que momento cada tela entra nas TVs** — relógio, N1,
antecipação, reunião de N2 e deslocamento. Serve para conferir a programação antes que ela vá ao ar.
Ordem de prioridade: reunião de N2 (e seus deslocamentos) > reunião de N1 > antecipação de 5 min >
relógio; ou seja, a antecipação não interrompe uma reunião de N1 em andamento.

O card **Relógio** liga o **modo automático**: o relógio fica no piso e as telas entram sozinhas —
as **Reuniões Escalonadas** a partir de 5 min antes de cada janela (saindo quando ela acaba) e as
**Reuniões de N1** durante os períodos configurados. Se os dois coincidirem, as Escalonadas têm
prioridade. Dá para abrir direto nesse modo pela preferência em *Comportamento*.

### Onde ficam os dados

Os **horários das reuniões ficam no banco** (Supabase), não no HTML nem no armazenamento do
navegador: são cadastrados **uma vez** pela tela de Configurações e valem para **todas as TVs**,
que recebem as alterações **na hora** (Realtime). Se o banco ficar inacessível, a TV continua
exibindo a última programação recebida e avisa nas Configurações.

No navegador ficam apenas as **preferências daquele aparelho** (tamanho da fonte, fundo do
relógio, segundos/data), que podem variar de TV para TV.

### Configurações

- **Séries de reuniões** *(no banco)*: janelas editáveis (início, fim, área, supervisor, Cadeia
  de Ajuda) e **múltiplas séries** (ex.: *Turno da Manhã* e *Turno da Tarde*, com horários e
  supervisores próprios). Por padrão a série é escolhida **automaticamente pelo horário**; dá
  para fixar uma série específica.
- **Reuniões de N1** *(no banco)*: períodos editáveis (padrão **08:00–09:00** e **14:00–15:00**)
  com **título e mensagem personalizáveis** — por padrão *"Reuniões de N1 em andamento"* e
  *"Agora é a hora de rever o dia anterior."*, exibidos com barra de progresso do tempo restante.
- **Comportamento** *(local)*: abrir direto no modo automático (padrão: menu principal); retornar
  ao relógio ao encerrar uma projeção.
- **Exibição** *(local)*: tamanho das fontes (ampliado para TVs de ~50"), fundo do relógio,
  segundos, data e Cadeia de Ajuda.
- **Dados**: exportar o cronograma da série em **`.csv` que abre no Excel** e importar de volta —
  a importação **substitui** as janelas daquela série **no banco**, para todas as TVs. Útil para
  cadastrar muitas janelas de uma vez.

> **Como editar os horários.** As alterações ficam em rascunho enquanto você digita — a linha não
> muda de lugar e nada é gravado no meio do caminho. Ao terminar, clique em **Gravar alterações**
> (ou **Descartar**). Os campos de horário usam intervalos de **5 minutos**.

### Versão offline

Existe uma versão **100% offline** (arquivo único, sem rede) na branch
[`claude/versao-offline`](../../tree/claude/versao-offline) — **em hold**. Ela é incompatível com
o cronograma no banco, então mantém os horários no próprio aparelho (com importação por planilha).

## Módulo 2: Andon (`andon/`)

**Sem login.** Ao abrir, o app mostra uma seleção em três colunas (**Perfil → Etapa → Mesa**):
- **Operadora** escolhe a etapa (SVE, SVS, Anel Revestido, Sizing & Trimming, Revisão Final) e a
  mesa (1–25). É identificada apenas pelo número da mesa. Cada mesa pode ter vários tablets — todos
  compartilham o mesmo estado.
- **Material Handler, Coordenação Técnica, Inspeção, Assistente** entram direto no seu painel.

Tela de chamado da operadora (tablet Windows na horizontal, sem digitação/rolagem): quatro botões
retangulares grandes — **Falta de Material** (amarelo → Material Handler), **Qualidade** (roxo →
Coordenação Técnica), **Inspeção** (laranja → Inspetores), **Assistente** (verde → Assistentes).
Cada botão mostra se há chamado em aberto e permite cancelar num toque.

Cada perfil receptor vê, em tempo real, a **fila** dos seus chamados — um quadrado com o número da
mesa, no fundo da cor do tipo — com som ao chegar um novo e ✓ para concluir. O **Assistente** tem
ainda **Estatísticas** (com exportação CSV/Excel) e **Mesas** (define quais mesas ficam disponíveis
por etapa).

Segurança: ferramenta interna sem login; as tabelas expõem só dados operacionais (tipo, mesa,
etapa, horário), sem nomes. Ver [`supabase/README.md`](supabase/README.md) para o passo a passo.

---

## Publicar (GitHub Pages)

1. **Settings → Pages** → branch `main`, pasta `/root`.
2. Painel de Avisos: `https://avisos-abbott.marcondes.dev`
   Andon: `https://avisos-abbott.marcondes.dev/andon`

Os dois módulos usam o Supabase: o Painel para os horários das reuniões (e a fila de andon nas
TVs) e o Andon para os chamados. A chave *publishable* é pública por design — a proteção real é
o RLS. O Andon lê as credenciais de [`andon/config.js`](andon/config.js); o Painel usa as mesmas,
ajustáveis em Configurações.

## Estrutura

```
index.html                 Painel de Avisos (projeção nas TVs)
andon/
  index.html               App de andon (seleção + operadora + painéis)
  config.js                URL + chave publishable do Supabase (editável)
  config.example.js        Modelo de configuração
supabase/
  migrations/0003_andon_sem_login.sql    Andon sem login + Realtime
  migrations/0004_reunioes_no_banco.sql  Horários das reuniões no banco
  migrations/0005_serie_automatica_padrao.sql  Série de N2 automática por padrão
  README.md                Passo a passo de configuração
LICENSE                    MIT
```
