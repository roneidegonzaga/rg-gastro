#!/usr/bin/env node
// ============================================================
// generate-config.js
// Gera config.js a partir de variaveis de ambiente no momento
// do build (Vercel). NAO le config.js existente. NAO le
// config.dev.js. NUNCA imprime valores completos no log.
//
// Lista de permissao EXPLICITA para geracao (qualquer coisa
// fora dela falha com seguranca, exit 1, nenhum arquivo escrito):
//   - VERCEL_ENV=preview        -> gera, usando as variaveis de
//     ambiente de Preview configuradas na Vercel.
//   - LOCAL_TEST_MODE=true      -> modo de teste local deliberado,
//     usado só para validar o script fora da Vercel, nunca em
//     producao real.
//
// Caso especial, nao e "geracao" nem "falha" — e um no-op seguro:
//   - VERCEL_ENV=production     -> nao faz nada; o config.js ja
//     commitado no repositorio (o de producao) e servido como
//     esta, sem build. Producao nao muda de comportamento.
//
// Qualquer outro valor de VERCEL_ENV (vazio, 'development' do
// `vercel dev`, erro de digitacao, etc.), sem LOCAL_TEST_MODE=true
// explicito, FALHA — nunca gera silenciosamente nem fica em
// silencio sem avisar.
// ============================================================

const fs = require('fs');
const path = require('path');

const VERCEL_ENV = process.env.VERCEL_ENV || '';
const LOCAL_TEST_MODE = process.env.LOCAL_TEST_MODE === 'true';
const CONFIG_OUTPUT_PATH = process.env.CONFIG_OUTPUT_PATH
  || path.join(__dirname, '..', 'config.js');

function fail(msg) {
  console.error('generate-config: ERRO — ' + msg);
  process.exit(1);
}

function required(name) {
  const v = process.env[name];
  if (!v || !String(v).trim()) {
    fail('variavel de ambiente obrigatoria ausente: ' + name);
  }
  return String(v).trim();
}

function optional(name, fallback) {
  const v = process.env[name];
  return (v && String(v).trim()) ? String(v).trim() : fallback;
}

// escapa com seguranca qualquer valor para uso como string literal JS
function jsString(v) {
  return JSON.stringify(v);
}

function main() {
  if (VERCEL_ENV === 'production') {
    console.log('generate-config: VERCEL_ENV=production — config.js do repositorio preservado; build nao gera nada.');
    return;
  }

  const isPreview = VERCEL_ENV === 'preview';
  if (!isPreview && !LOCAL_TEST_MODE) {
    fail(
      'valor nao permitido para gerar config.js. VERCEL_ENV="' + (VERCEL_ENV || '(vazio)') + '", ' +
      'LOCAL_TEST_MODE=' + (LOCAL_TEST_MODE ? 'true' : 'false') + '. ' +
      'Este script so gera config.js quando VERCEL_ENV=preview ou quando LOCAL_TEST_MODE=true ' +
      'e definido deliberadamente para teste local. Nenhum arquivo foi escrito.'
    );
  }

  const SUPABASE_URL = required('SUPABASE_URL');
  const SUPABASE_PUBLISHABLE_KEY = required('SUPABASE_PUBLISHABLE_KEY');
  const APP_ENV = required('APP_ENV');
  const GOOGLE_CLIENT_ID = optional('GOOGLE_CLIENT_ID', '');

  const geradoEm = new Date().toISOString();

  const output = [
    '// ============================================================',
    '// CONFIGURACAO GERADA AUTOMATICAMENTE NO BUILD — NAO EDITAR A MAO',
    '// Gerado em ' + geradoEm + ' a partir de variaveis de ambiente.',
    '// Este arquivo e sobrescrito a cada build (exceto em producao).',
    '// ============================================================',
    '',
    'window.RG_CONFIG = {',
    '  MODO_DEMO: false,',
    '',
    '  SUPABASE_URL: ' + jsString(SUPABASE_URL) + ',',
    '  SUPABASE_ANON_KEY: ' + jsString(SUPABASE_PUBLISHABLE_KEY) + ',',
    '',
    '  GOOGLE_CLIENT_ID: ' + jsString(GOOGLE_CLIENT_ID) + ',',
    '',
    '  APP_ENV: ' + jsString(APP_ENV) + ',',
    '',
    "  NOME_SISTEMA: \"RG Gastrô\",",
    "  NOME_SUB: \"Painel de gestão\"",
    '};',
    ''
  ].join('\n');

  fs.writeFileSync(CONFIG_OUTPUT_PATH, output, 'utf8');
  console.log('generate-config: config.js gerado para APP_ENV=' + APP_ENV + ' em ' + CONFIG_OUTPUT_PATH + ' (valores nao exibidos).');
}

main();
