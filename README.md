# Andon para Produção — plataforma genérica e de código aberto

Plataforma **genérica de andon/pager para ambientes de produção**, criada por **iniciativa
própria** e distribuída como **software livre** (licença MIT). Reúne dois módulos que rodam
inteiramente no navegador, sem instalação e sem integração com sistemas corporativos:

1. **Painel de Avisos** (`index.html`) — telas para projeção em TVs do piso: reuniões
   escalonadas, busca por itens, avisos gerais, silêncio, microfone (push-to-talk) e relógio.
   Não usa servidor: as configurações ficam apenas no `localStorage` do navegador.
2. **Andon** (`andon/`) — chamados de produção em tempo real (ex.: *falta de material*):
   operadores registram por um login simples; o material handler acompanha e atende em um
   painel ao vivo. Usa [Supabase](https://supabase.com) (Postgres + Auth + Realtime).

> **Disclaimer.** Projeto pessoal, de código aberto, criado por iniciativa própria. É uma
> plataforma **genérica** de andon para produção — não é um produto oficial de nenhuma
> empresa e não se integra a sistemas corporativos. O Painel de Avisos não registra
> informação alguma (dados só no navegador). O módulo Andon registra apenas **sinais
> operacionais de chamado** (área, tipo, horário) para coordenar o atendimento.
> Desenvolvido por **Matheus Marcondes**.

---

## Módulo 1 — Painel de Avisos (`index.html`)

Arquivo estático único, **sem dependências externas**. Funções: Reuniões Escalonadas
(tela inicial), Busca por Válvulas/itens, Aviso Geral, Silêncio, Microfone e Relógio.

Tudo é inserido **manualmente** pela tela de **Configurações** e salvo no navegador:

- **Séries de reuniões** — janelas editáveis (início, fim, área, supervisor, Cadeia de Ajuda)
  e **múltiplas séries** (ex.: *Turno da Manhã* e *Turno da Tarde*, com horários e supervisores
  próprios), com seleção fixa ou **automática pelo horário**.
- **Comportamento** — abrir automaticamente nas Reuniões Escalonadas; retornar ao relógio ao
  encerrar uma projeção.
- **Exibição** — tamanho das fontes (ampliado para TVs de ~50"), fundo do relógio, segundos,
  data e Cadeia de Ajuda.

## Módulo 2 — Andon (`andon/`)

- **Login simples**: matrícula numérica + **PIN de 6 dígitos** (em quadradinhos separados,
  tolerantes a teclado físico, virtual, colagem e preenchimento automático — pensado para
  tablet). A autenticação é do **Supabase Auth**; o PIN é guardado apenas como **hash (bcrypt)**.
- Cada usuário tem **nome de exibição** e **área** (as mesmas supervisões das reuniões), usados
  para direcionar o chamado ao material handler.
- **Operador**: botões grandes por tipo de ocorrência; vê e cancela os próprios chamados;
  logout automático por inatividade (tablet compartilhado).
- **Material handler / admin**: painel ao vivo dos chamados ativos, com filtro por área e ações
  *Assumir* / *Resolver*.
- **Admin**: cadastro de usuários (via Edge Function, sem expor segredo no cliente).

Segurança: todo acesso a dados exige login válido — **Row Level Security** no banco garante
que a chave publishable, sozinha, não lê nem escreve nada. Nenhum segredo (service_role) vai
para o repositório. Ver [`supabase/README.md`](supabase/README.md) para o passo a passo.

---

## Publicar (GitHub Pages)

1. **Settings → Pages** → branch `main`, pasta `/root`.
2. Painel de Avisos: `https://<usuário>.github.io/<repo>/`
   Andon: `https://<usuário>.github.io/<repo>/andon/`

O Painel funciona offline. O Andon precisa das credenciais do Supabase em
[`andon/config.js`](andon/config.js) (a chave *publishable* é pública por design; a proteção
real é o RLS).

## Estrutura

```
index.html                 Painel de Avisos (projeção nas TVs)
andon/
  index.html               App de andon (operador + painel + admin)
  config.js                URL + chave publishable do Supabase (editável)
  config.example.js        Modelo de configuração
supabase/
  migrations/0001_andon_pager.sql   Esquema + RLS + Realtime
  functions/admin-manage-user/      Edge Function (gerência de usuários)
  README.md                Passo a passo de configuração
LICENSE                    MIT
```
