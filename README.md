# Screenplay 1.0 — versão local

**Screenplay** é uma plataforma **genérica e de código aberto** de avisos e reuniões para o piso
de produção: as telas que vão para as TVs da linha. Esta é a **versão 1.0**, a versão **local**,
e é o que vive na `main`.

Um único arquivo. Sem internet, sem servidor, sem banco de dados e sem contas de usuário. Baixe
`index.html`, abra no navegador da TV e está funcionando.

> **Disclaimer.** Projeto pessoal, criado por iniciativa própria e distribuído sob licença MIT.
> Não é produto oficial de nenhuma empresa e **não se integra a sistemas corporativos**. Guarda
> apenas os **horários das reuniões** cadastrados no próprio sistema, no próprio aparelho —
> **nenhuma informação pessoal**.
>
> Desenvolvido por Matheus Marcondes.

---

## Instalar

1. Abra [`index.html`](index.html) e clique em **Download raw file**.
2. Copie o arquivo para a máquina da TV (pen drive, pasta de rede, e-mail — o que for permitido).
3. Dê um duplo clique. Ele abre no navegador padrão e já está pronto para uso.

Não há instalação, atalho de sistema nem permissão de administrador envolvida. Para tela cheia,
use o **F11** do navegador — o sistema não força tela cheia sozinho.

## O que ele faz

Abre no **menu principal**, de onde se escolhe a função:

- **Reuniões Escalonadas** — as duas reuniões do dia. **N1** (revisão do dia anterior, com
  barra de progresso do tempo restante) e **N2** (cronograma escalonado por área). Na tela de N2
  dá para escolher a **série** a projetar, com aviso quando o cronograma daquela série está longe
  do horário atual.
- **Planejamento** — a linha do tempo do dia, numa coluna proporcional ao horário com uma marca
  que acompanha o relógio. Mostra **em que momento cada tela entra na TV**: relógio, N1,
  antecipação, reunião de N2 e deslocamento. Ferramenta de conferência, para usar no computador.
- **Busca por Válvulas** — chamado de item, com entrega para o assistente ou supervisor.
- **Aviso Geral**, **Silêncio** e **Microfone** (push-to-talk).
- **Relógio** — liga o **modo automático**: o relógio fica no ar e as telas entram sozinhas, as
  Escalonadas a partir de **5 minutos** antes de cada janela (saindo quando ela acaba) e as de N1
  durante os períodos configurados.

Ordem de prioridade quando duas telas disputam o mesmo minuto: reunião de N2 (e seus
deslocamentos) > reunião de N1 > antecipação de 5 min > relógio. A antecipação **não** interrompe
uma reunião de N1 em andamento.

## Onde ficam os dados

Tudo fica **neste aparelho**, no armazenamento do próprio navegador. Nada é enviado para lugar
nenhum, nada é lido de fora. O arquivo já vem com um cronograma inicial embutido; a partir da
primeira alteração, vale o que estiver gravado na máquina.

Como não há banco, a configuração se propaga de três formas — use a que couber:

| Situação | Como |
| --- | --- |
| Dia a dia, na própria TV | Editar em **Configurações**. Fica gravado no aparelho. |
| Levar a configuração para outras TVs | **Baixar cópia configurada**: gera um `screenplay-AAAA-MM-DD.html` novo, com o cronograma já embutido. Copie esse arquivo para as outras telas — elas abrem prontas. |
| Cadastrar muitas janelas de uma vez | **Exportar / Importar `.csv`**, que abre no Excel. |

A **cópia configurada** é o próprio sistema se reescrevendo: o navegador não pode alterar o arquivo
que abriu, então ele gera um arquivo novo, idêntico, com a semente de configuração atualizada. A
cópia também sabe gerar cópias — não há um "arquivo original" a preservar.

**CSV**: colunas `Início; Fim; Área; Supervisor; Cadeia` (horários como `09:00`; Cadeia em branco
ou SEG…SÁB). A importação **substitui** as janelas da série selecionada.

## Configurações

- **Séries de reuniões** — janelas editáveis (início, fim, área, supervisor, Cadeia de Ajuda) e
  **múltiplas séries** (ex.: *Turno da Manhã* e *Turno da Tarde*, com horários e supervisores
  próprios). Por padrão a série é escolhida **automaticamente pelo horário**; dá para fixar uma.
- **Reuniões de N1** — períodos editáveis (padrão **08:00–09:00** e **14:00–15:00**) com título e
  mensagem personalizáveis.
- **Comportamento** — abrir direto no modo automático (padrão: menu principal); voltar ao relógio
  ao encerrar uma projeção.
- **Exibição** — tamanho das fontes (ampliado para TVs de ~50"), fundo do relógio, segundos, data
  e Cadeia de Ajuda.
- **Dados** — cópia configurada e CSV, acima.

> **Como editar os horários.** As alterações ficam em rascunho enquanto você digita — a linha não
> muda de lugar e nada é gravado no meio do caminho. Ao terminar, clique em **Gravar alterações**
> (ou **Descartar**). Os campos de horário usam intervalos de **5 minutos**.

## Versões

- **1.0 — local** *(`main`)*: arquivo único, offline. Roda a operação de hoje.
- **2.0 — em rede** (branch [`screenplay-2.0`](../../tree/screenplay-2.0)): banco de dados,
  alterações ao vivo em todas as TVs e o andon integrado, no mesmo arquivo.

## Estrutura

```
index.html   O sistema inteiro: telas, lógica, estilos e cronograma inicial
LICENSE      MIT
```
