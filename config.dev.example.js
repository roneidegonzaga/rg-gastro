// ============================================================
// EXEMPLO de configuracao de DESENVOLVIMENTO — Painel RG Gastro
// ============================================================
// Este arquivo NAO contem credenciais reais. Copie-o para
// "config.dev.js" (que deve permanecer fora do controle de
// versao) e preencha os valores do SEU projeto Supabase de
// desenvolvimento, criado separadamente do de producao.
//
// Nunca preencha este exemplo com valores reais.
// Nunca commite config.dev.js.
// ============================================================

window.RG_CONFIG = {
  MODO_DEMO: true,

  // Projeto Supabase de DESENVOLVIMENTO (nunca o de producao)
  SUPABASE_URL: "SUPABASE_DEV_URL_A_PREENCHER",
  SUPABASE_ANON_KEY: "SUPABASE_DEV_ANON_KEY_A_PREENCHER",

  // Google Cloud OAuth Client ID de DESENVOLVIMENTO (opcional nesta fase)
  GOOGLE_CLIENT_ID: "GOOGLE_CLIENT_ID_DEV_A_PREENCHER",

  NOME_SISTEMA: "RG Gastro (DEV)",
  NOME_SUB: "Ambiente de desenvolvimento — NAO E PRODUCAO"
};
