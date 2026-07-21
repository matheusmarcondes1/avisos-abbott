/* ============================================================
   Configuração do Andon.
   Estes valores são PUBLICÁVEIS por design (a chave "publishable" só
   funciona junto com um login válido — todo o acesso é protegido por
   Row Level Security no Supabase). Podem ficar no repositório.

   Para outro ambiente, basta trocar os valores abaixo (ou definir
   window.ANDON_CONFIG antes de carregar este arquivo).
   ============================================================ */
window.ANDON_CONFIG = Object.assign({
  SUPABASE_URL:  "https://swcflnemmjnrvbqbrguw.supabase.co",
  SUPABASE_KEY:  "sb_publishable_cT0lJ0L1ZtXTy8XPsgFFRA_TfMb6YwA",
  // Domínio do e-mail sintético (matrícula -> matricula@DOMÍNIO). Deve ser o
  // MESMO configurado na Edge Function (ANDON_EMAIL_DOMAIN). Não é um e-mail real.
  EMAIL_DOMAIN:  "andon.local",
  // Logout automático do operador por inatividade (segundos) — tablet compartilhado.
  IDLE_LOGOUT_SECONDS: 120,
}, window.ANDON_CONFIG || {});
