# Andon — configuração do Supabase

Backend do módulo de andon: **Postgres + Auth + Realtime**, com **Row Level Security** em
todas as tabelas. Segue o passo a passo para deixar tudo pronto.

## 1. Aplicar o esquema

**SQL Editor → New query →** cole [`migrations/0001_andon_pager.sql`](migrations/0001_andon_pager.sql)
**→ Run**. Cria: `areas`, `profiles`, `andon_events`, funções de papel, políticas RLS e o Realtime.

## 2. Ajustar o Auth (login por matrícula + PIN)

O login usa um **e-mail sintético** `matricula@andon.local` (não é um e-mail real) com o PIN
como senha. Em **Authentication → Providers → Email**:

- **Desative** "Confirm email" (senão o login não funciona sem caixa de entrada).
- Mantenha o provedor **Email** habilitado.
- Opcional: em **Authentication → Rate limits**, ajuste o limite de tentativas.

> O domínio `andon.local` deve ser o mesmo em `andon/config.js` (`EMAIL_DOMAIN`) e, se usar a
> Edge Function, na variável `ANDON_EMAIL_DOMAIN`.

## 3. Criar o primeiro admin

Ainda não há usuários. Crie o primeiro admin manualmente:

1. **Authentication → Users → Add user**
   - Email: `SUA_MATRICULA@andon.local`  ·  Password: seu PIN de 6 dígitos  ·  **Auto Confirm: on**
2. Copie o **User UID** gerado e rode no SQL Editor:

```sql
insert into public.profiles (id, matricula, display_name, area, role)
values ('COLE_O_USER_UID', 'SUA_MATRICULA', 'Seu Nome', null, 'admin');
```

Pronto: entre no app `andon/` com essa matrícula + PIN. Como admin, você cria os demais
usuários pela própria tela **Usuários**.

## 4. (Opcional) Edge Function para gerenciar usuários

A tela de admin cria/edita usuários chamando a função `admin-manage-user`, que roda no
servidor com a `service_role` (nunca exposta ao cliente) e só aceita chamadas de um admin.

```bash
# Requer o Supabase CLI e login (supabase login)
supabase link --project-ref SEU_PROJECT_REF
supabase functions deploy admin-manage-user
# defina o domínio (o mesmo do config.js), se diferente do padrão:
supabase secrets set ANDON_EMAIL_DOMAIN=andon.local
```

Sem a função, você ainda pode cadastrar usuários manualmente (passo 3 repetido). A URL, a
anon key e a service_role key são injetadas automaticamente no ambiente da função — **não
comite nenhuma delas**.

## 5. (Opcional) Notificações de andon nas TVs

Para o **Painel de Avisos** mostrar, sobre o relógio, uma notificação quando um chamado é
aberto (com som), aplique também `migrations/0002_andon_tv_notify.sql`. Ele permite ao papel
**anônimo** apenas **ler os chamados ativos** (status `aberto`/`em_atendimento`), para o painel
assinar em tempo real usando só a chave publishable — sem login na TV.

As informações expostas (área, tipo, nome, horário) são as mesmas já exibidas publicamente nas
TVs do piso. Se preferir não expor nada ao papel anônimo, **não** aplique o 0002 e use uma conta
de exibição (material_handler) — posso ajustar o painel para esse modo se quiser.

O painel já vem com a URL e a chave publishable padrão; dá para trocá-las em
**Configurações → Notificações de Andon**.

## 6. Conferir a segurança (checklist)

- [ ] RLS **habilitado** em `areas`, `profiles` e `andon_events` (o SQL já faz isso).
- [ ] `service_role` **nunca** aparece em `andon/config.js` nem no front-end.
- [ ] Confirmação de e-mail **desativada**; Auto Confirm ligado ao criar usuários.
- [ ] `EMAIL_DOMAIN` igual em `config.js` e na Edge Function.
- [ ] Sem o 0002: sem login, a chave publishable **não** lê `andon_events`.
      Com o 0002: o papel anônimo lê apenas os chamados **ativos** (para as TVs).

## Modelo de dados

| Tabela         | Papel                                                                 |
|----------------|-----------------------------------------------------------------------|
| `areas`        | supervisões do piso (as mesmas das reuniões)                          |
| `profiles`     | matrícula, nome de exibição, área, papel (operator/handler/admin)     |
| `andon_events` | chamados: tipo, status, autor, quem assumiu, horários                 |

Fluxo de status: `aberto → em_atendimento → resolvido` (ou `cancelado`).

Papéis:
- **operator** — abre e cancela os próprios chamados; vê só os seus.
- **material_handler** — vê todos os chamados e atende (assume/resolve).
- **admin** — tudo do material handler + gerência de usuários.
