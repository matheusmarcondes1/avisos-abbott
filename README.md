# Andon para Produção: plataforma genérica e de código aberto

Plataforma **genérica de andon/pager para ambientes de produção**, criada por **iniciativa
própria** e distribuída como **software livre** (licença MIT). Reúne dois módulos que rodam
inteiramente no navegador, sem instalação e sem integração com sistemas corporativos:

1. **Painel de Avisos** (`index.html`): telas para projeção em TVs do piso: reuniões
   escalonadas, busca por itens, avisos gerais, silêncio, microfone (push-to-talk) e relógio.
   Não usa servidor: as configurações ficam apenas no `localStorage` do navegador.
2. **Andon** (`andon/`): chamados de produção em tempo real (ex.: *falta de material*),
   **sem login** — a operadora é identificada por mesa/etapa e cada perfil (Material Handler,
   Coordenação Técnica, Inspeção, Assistente) acompanha e atende em um painel ao vivo. Usa
   [Supabase](https://supabase.com) (Postgres + Realtime).

> **Disclaimer.** Projeto pessoal, de código aberto, criado por iniciativa própria. É uma
> plataforma **genérica** de andon para produção, não é um produto oficial de nenhuma
> empresa e não se integra a sistemas corporativos. O Painel de Avisos não registra
> informação alguma (dados só no navegador). O módulo Andon registra apenas **sinais
> operacionais de chamado** (tipo, mesa, etapa, horário) para coordenar o atendimento.

---

## Módulo 1: Painel de Avisos (`index.html`)

Arquivo estático único, **sem dependências externas**. Funções: Reuniões Escalonadas
(tela inicial), Busca por Válvulas/itens, Aviso Geral, Silêncio, Microfone e Relógio.

Tudo é inserido **manualmente** pela tela de **Configurações** e salvo no navegador:

- **Séries de reuniões**: janelas editáveis (início, fim, área, supervisor, Cadeia de Ajuda)
  e **múltiplas séries** (ex.: *Turno da Manhã* e *Turno da Tarde*, com horários e supervisores
  próprios), com seleção fixa ou **automática pelo horário**.
- **Comportamento**: abrir automaticamente nas Reuniões Escalonadas; retornar ao relógio ao
  encerrar uma projeção.
- **Exibição**: tamanho das fontes (ampliado para TVs de ~50"), fundo do relógio, segundos,
  data e Cadeia de Ajuda.

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

O Painel funciona offline. O Andon precisa das credenciais do Supabase em
[`andon/config.js`](andon/config.js) (a chave *publishable* é pública por design; a proteção
real é o RLS).

## Estrutura

```
index.html                 Painel de Avisos (projeção nas TVs)
andon/
  index.html               App de andon (seleção + operadora + painéis)
  config.js                URL + chave publishable do Supabase (editável)
  config.example.js        Modelo de configuração
supabase/
  migrations/0003_andon_sem_login.sql   Esquema atual (sem login) + Realtime
  README.md                Passo a passo de configuração
LICENSE                    MIT
```
