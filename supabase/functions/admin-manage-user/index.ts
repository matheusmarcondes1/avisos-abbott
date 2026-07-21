// ============================================================
// Edge Function: admin-manage-user
//
// Gerência de usuários do andon (criar / redefinir PIN / ativar-desativar).
// Roda no servidor com a service_role key (NUNCA exposta ao cliente).
// Só executa se o CHAMADOR estiver autenticado e for 'admin' — a verificação
// é feita server-side lendo o perfil do próprio JWT do chamador.
//
// Deploy:
//   supabase functions deploy admin-manage-user
// (a SUPABASE_URL e a SERVICE_ROLE_KEY são injetadas automaticamente pelo
//  ambiente da função; nada de segredo vai para o repositório.)
//
// Ações (JSON no corpo):
//   { action: "create",     matricula, pin, display_name, area, role }
//   { action: "reset_pin",  id | matricula, pin }
//   { action: "set_active", id | matricula, active }
// ============================================================
import { createClient } from "jsr:@supabase/supabase-js@2";

const EMAIL_DOMAIN = Deno.env.get("ANDON_EMAIL_DOMAIN") ?? "andon.local";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });

const emailFor = (matricula: string) => `${String(matricula).trim()}@${EMAIL_DOMAIN}`;
const validMatricula = (m: string) => /^[0-9]{1,20}$/.test(String(m ?? "").trim());
const validPin = (p: string) => /^[0-9]{6}$/.test(String(p ?? ""));
const validRole = (r: string) => ["operator", "material_handler", "admin"].includes(r);

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "método não suportado" }, 405);

  const url = Deno.env.get("SUPABASE_URL")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const authHeader = req.headers.get("Authorization") ?? "";

  // Cliente no contexto do CHAMADOR (para descobrir quem é e checar se é admin)
  const asCaller = createClient(url, Deno.env.get("SUPABASE_ANON_KEY")!, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: userData } = await asCaller.auth.getUser();
  const caller = userData?.user;
  if (!caller) return json({ error: "não autenticado" }, 401);

  const { data: callerProfile } = await asCaller
    .from("profiles").select("role, active").eq("id", caller.id).maybeSingle();
  if (!callerProfile || callerProfile.active !== true || callerProfile.role !== "admin") {
    return json({ error: "apenas administradores" }, 403);
  }

  // Cliente com service_role para operações administrativas
  const admin = createClient(url, serviceKey, { auth: { persistSession: false } });

  let body: Record<string, unknown>;
  try { body = await req.json(); } catch { return json({ error: "JSON inválido" }, 400); }
  const action = String(body.action ?? "");

  // resolve o id do alvo a partir de id ou matrícula
  async function resolveId(): Promise<string | null> {
    if (body.id) return String(body.id);
    if (body.matricula) {
      const { data } = await admin.from("profiles").select("id")
        .eq("matricula", String(body.matricula).trim()).maybeSingle();
      return data?.id ?? null;
    }
    return null;
  }

  try {
    if (action === "create") {
      const matricula = String(body.matricula ?? "").trim();
      const pin = String(body.pin ?? "");
      const display_name = String(body.display_name ?? "").trim();
      const area = body.area ? String(body.area).trim() : null;
      const role = String(body.role ?? "operator");
      if (!validMatricula(matricula)) return json({ error: "matrícula inválida (apenas dígitos)" }, 400);
      if (!validPin(pin)) return json({ error: "PIN deve ter 6 dígitos" }, 400);
      if (!display_name) return json({ error: "nome de exibição obrigatório" }, 400);
      if (!validRole(role)) return json({ error: "papel inválido" }, 400);

      const { data: created, error: cErr } = await admin.auth.admin.createUser({
        email: emailFor(matricula),
        password: pin,
        email_confirm: true,
        user_metadata: { matricula, display_name },
      });
      if (cErr || !created?.user) return json({ error: cErr?.message ?? "falha ao criar usuário" }, 400);

      const { error: pErr } = await admin.from("profiles").insert({
        id: created.user.id, matricula, display_name, area, role, active: true,
      });
      if (pErr) {
        // desfaz o usuário Auth se o perfil falhar (mantém consistência)
        await admin.auth.admin.deleteUser(created.user.id);
        return json({ error: pErr.message }, 400);
      }
      return json({ ok: true, id: created.user.id });
    }

    if (action === "reset_pin") {
      const pin = String(body.pin ?? "");
      if (!validPin(pin)) return json({ error: "PIN deve ter 6 dígitos" }, 400);
      const id = await resolveId();
      if (!id) return json({ error: "usuário não encontrado" }, 404);
      const { error } = await admin.auth.admin.updateUserById(id, { password: pin });
      if (error) return json({ error: error.message }, 400);
      return json({ ok: true });
    }

    if (action === "set_active") {
      const id = await resolveId();
      if (!id) return json({ error: "usuário não encontrado" }, 404);
      const active = body.active !== false;
      const { error } = await admin.from("profiles").update({ active }).eq("id", id);
      if (error) return json({ error: error.message }, 400);
      // bloqueia/reabilita o login banindo o usuário Auth
      await admin.auth.admin.updateUserById(id, { ban_duration: active ? "none" : "876000h" });
      return json({ ok: true });
    }

    return json({ error: "ação desconhecida" }, 400);
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
