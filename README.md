# Screenplay 2.0 — versão em rede

**Screenplay** é uma plataforma **genérica e de código aberto** de avisos e reuniões para o piso
de produção. Esta branch é a **versão 2.0**: o mesmo sistema com **banco de dados**, alterações
ao vivo em todas as TVs e o **andon** integrado.

Continua sendo **um arquivo só**. Baixe `index.html`, abra na TV e no tablet, e os dois falam com
o mesmo banco.

> **Marca de demonstração.** A identidade visual desta versão é **S.T.A.R. Labs**, uma marca
> fictícia usada apenas como exemplo enquanto o sistema está em avaliação. Papéis, horários e
> agenda são os reais; nome, cores e unidade são placeholder.
>
> **Disclaimer.** Projeto pessoal, criado por iniciativa própria e distribuído sob licença MIT.
> Não é produto oficial de nenhuma empresa e **não se integra a sistemas corporativos**. Guarda
> os **horários das reuniões** e os **sinais operacionais de chamado** (tipo, mesa, etapa,
> horário) — **nenhuma informação pessoal**.

---

## O que muda em relação à 1.0

| | 1.0 — local | 2.0 — em rede |
| --- | --- | --- |
| Cronograma | no aparelho | no banco, igual em todas as TVs |
| Alterações | uma TV por vez | ao vivo, em todas (Realtime) |
| Andon | não tem | integrado, no mesmo arquivo |
| Internet | dispensa | necessária |

## Instalar

1. Prepare o banco: rode as migrações de [`supabase/`](supabase/) no seu projeto Supabase.
   O passo a passo está em [`supabase/README.md`](supabase/README.md).
2. Baixe [`index.html`](index.html) (**Download raw file**) e copie para as máquinas.
3. Nas TVs, abra o arquivo. No primeiro uso, informe URL e chave em
   **Configurações → Notificações de Andon**, se não quiser as padrão.
4. Nos tablets do piso, abra o mesmo arquivo com `#andon` no fim do endereço. O app entra direto
   na tela de seleção, sem passar pelo menu.

Também funciona publicado (GitHub Pages, `Settings → Pages`, branch desta versão): as TVs abrem a
URL e os tablets a mesma URL com `#andon`.

## Painel (nas TVs)

Abre no **menu principal**, de onde se escolhe a função:

- **Reuniões Escalonadas** — **N1** (revisão do dia anterior, com barra de progresso) e **N2**
  (cronograma escalonado por área, com escolha da série a projetar).
- **Planejamento** — a linha do tempo do dia, mostrando em que momento cada tela entra na TV.
  Ferramenta de conferência, para usar no computador.
- **Busca por Válvulas**, **Aviso Geral**, **Silêncio** e **Microfone** (push-to-talk).
- **Relógio** — modo automático: as telas entram sozinhas, as Escalonadas a partir de 5 minutos
  antes de cada janela e as de N1 nos períodos configurados.

Prioridade quando duas telas disputam o mesmo minuto: reunião de N2 (e seus deslocamentos) >
reunião de N1 > antecipação de 5 min > relógio.

Quando há **chamados de andon abertos**, a tela principal chega para o lado e a fila aparece numa
coluna própria — cor do tipo e número da mesa, em caixa alta, com os mais antigos no topo. Nada do
relógio é coberto.

## Andon (`index.html#andon`)

**Sem login.** A tela de entrada é uma seleção em três colunas — **Perfil → Etapa → Mesa**:

- **Operadora** escolhe a etapa (Anel Revestido, Sizing & Trimming, SVE, SVS, Revisão Final) e a
  mesa (1–25). É identificada só pelo número da mesa, e cada mesa pode ter vários tablets.
- **Material Handler, Coordenação Técnica, Inspeção, Assistente** entram direto no painel.

A tela da operadora é feita para tablet na horizontal, sem digitação nem rolagem: quatro botões
grandes — **Falta de Material** (bronze → Material Handler), **Qualidade** (azul → Coordenação
Técnica), **Inspeção** (teal → Inspeção) e **Assistente** (grafite → Assistentes). Cada botão
mostra se há chamado em aberto e cancela num toque.

Cada perfil receptor vê a **fila** dos seus chamados em tempo real, com som ao chegar um novo e ✓
para concluir. O **Assistente** tem ainda **Estatísticas** (com exportação CSV/Excel) e **Mesas**
(quais mesas ficam disponíveis em cada etapa).

## Configurações

- **Séries de reuniões** *(no banco)* — janelas editáveis e múltiplas séries, com a série do
  momento escolhida **automaticamente pelo horário**.
- **Reuniões de N1** *(no banco)* — períodos, título e mensagem.
- **Comportamento** e **Exibição** *(deste aparelho)* — modo automático, retorno ao relógio,
  tamanho das fontes, fundo do relógio, segundos, data, Cadeia de Ajuda.
- **Notificações de Andon** — liga a fila nas TVs e guarda URL e chave do Supabase.
- **Dados** — exportar e importar o cronograma da série em `.csv` que abre no Excel.

> **Como editar os horários.** As alterações ficam em rascunho enquanto você digita. Ao terminar,
> clique em **Gravar alterações** (ou **Descartar**). Os horários usam intervalos de 5 minutos.

## Paleta

| | | |
| --- | --- | --- |
| `#5F95E2` | Cornflower Blue | interação e progresso |
| `#DC9F6C` | Light Bronze | deslocamento e atenção |
| `#2E747B` | Stormy Teal | superfícies de destaque |
| `#FAFAF9` | Bright Snow | fundo |
| `#FDFDFE` | White | cartões e barras |

As demais cores do arquivo são derivações dessas — mesmo matiz, luminância ajustada — porque texto
sobre cor precisa de contraste e a leitura acontece a alguns metros da TV.

## Segurança

Ferramenta interna, sem login. A chave *publishable* é pública por design: a proteção real é o RLS
do Postgres. As tabelas guardam só dados operacionais (horários, tipo, mesa, etapa), sem nomes de
pessoas.

## Estrutura

```
index.html                 Painel + Andon, num arquivo só
supabase/
  migrations/*.sql         Tabelas, RLS e Realtime
  README.md                Passo a passo de configuração
LICENSE                    MIT
```

## Versões

- **1.0 — local** (branch [`screenplay-1.0`](../../tree/screenplay-1.0)): arquivo único, offline,
  cronograma no próprio aparelho. Roda a operação de hoje.
- **2.0 — em rede** *(esta branch)*: banco de dados, tempo real e andon.
