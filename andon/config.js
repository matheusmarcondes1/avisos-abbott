/* ============================================================
   Configuração do Andon.
   Valores PUBLICÁVEIS por design — a plataforma não tem login e é uma
   ferramenta interna de piso; o acesso é feito com a chave publishable.
   Para outro ambiente, troque os valores abaixo.
   ============================================================ */
window.ANDON_CONFIG = Object.assign({
  SUPABASE_URL: "https://swcflnemmjnrvbqbrguw.supabase.co",
  SUPABASE_KEY: "sb_publishable_cT0lJ0L1ZtXTy8XPsgFFRA_TfMb6YwA",
}, window.ANDON_CONFIG || {});
