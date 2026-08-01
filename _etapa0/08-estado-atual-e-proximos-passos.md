# Estado atual e próximos passos — 31/07/2026

> Documento de handoff, escrito por estar perto do limite de contexto da conversa anterior. Continue a partir daqui numa conversa nova.

## Estrutura de pastas
| Pasta | Papel |
|---|---|
| `C:\Projetos\rg-gastro-dev` | **Pasta oficial de trabalho, atual.** Histórico Git sanitizado (sem `config.js` com valores reais em nenhum commit). `config.js` e `config.dev.js` reais restaurados como arquivos locais, não rastreados, ignorados pelo `.gitignore`. |
| `C:\Projetos\rg-gastro-dev-ARQUIVO-ANTES-SANITIZACAO-2026-07-31` | Pasta arquivada — histórico original, não sanitizado, intocada. Não apagar. |
| `C:\Projetos\backups\rg-gastro-original-antes-sanitizacao.bundle` | Salvaguarda externa (git bundle) do histórico original completo, validada. |
| `C:\Users\ronei\OneDrive\Área de Trabalho\rg-gastro-backup` | Pasta de origem original (a primeira fornecida). Intocada. |
| `C:\Users\ronei\OneDrive\Área de Trabalho\rg-gastro-backup-INTOCAVEL-2026-07-18` | Cópia intocável de referência. Intocada. |

## Estado do Git em `rg-gastro-dev` (a pasta oficial)
- Branch atual: `desenvolvimento`
- Branches locais: só `master` e `desenvolvimento`
- Tag: só `backup-original-2026-07-18` (aponta pro commit sanitizado)
- `git status`: limpo
- `git fsck`: sem erros
- Remote `origin`: `https://github.com/roneidegonzaga/rg-gastro.git` (repositório privado, **vazio** — nada foi enviado ainda)
- Último `git push --dry-run -u origin master` confirmado: enviaria só o commit sanitizado `114b375` ("docs: documentação completa do Painel RG Gastrô (config.js sanitizado)")

## O que já foi feito (histórico completo desta sessão)
1. Diagnóstico técnico completo do Painel RG Gastrô (arquitetura real vs. `docs/` aspiracional, 24 tópicos do Registro de Análise classificados)
2. Análise forense do CSV da Hotmart (causa raiz: status "Completo" não reconhecido como venda aprovada)
3. Plano revisado em etapas (Etapa 0 a 13), com Etapa 6 dividida em 6A-6D
4. **Etapa 0 executada:**
   - Ambiente seguro criado (cópias, branch, tag)
   - Inventário completo do schema (`_etapa0/01-inventario-schema-backup.md`)
   - Migrations versionadas (`_etapa0/migrations/0000, 0001, 0002*.sql`), endurecidas com `BEGIN`/`COMMIT` e `search_path=''`
   - Projeto Supabase `rg-gastro-DEV` (plano Free) criado por você; as 3 migrations aplicadas e validadas, uma a uma
   - `scripts/generate-config.js` criado e endurecido (só gera com `VERCEL_ENV=preview` ou `LOCAL_TEST_MODE=true`; `production` é no-op seguro; qualquer outro valor falha)
   - Faixa "AMBIENTE DE DESENVOLVIMENTO" implementada em `app.html`/`index.html`, só quando `APP_ENV==='development'`
5. **Descoberta importante:** o projeto Vercel legado (`rg-gastro`/`painel.roneidegonzaga.com`) **não corresponde** ao código atual — nunca deve ser conectado ao repositório novo
6. **Sanitização do histórico do Git:** o commit original tinha `config.js` com credenciais reais de produção (URL do Supabase, chave publishable, Google Client ID — nenhum `service_role`/secret/senha, confirmado). Reescrito com sucesso: histórico agora usa `config.example.js` (só placeholders); `config.js` passou a ser gerado localmente/por build, nunca commitado
7. Repositório GitHub privado `roneidegonzaga/rg-gastro` já criado (vazio)
8. `git push --dry-run -u origin master` executado e revisado — **nenhum push real feito ainda**

## Próximos passos (nenhum aprovado ainda — pedir aprovação explícita para cada um)
1. **Push real de `master`** (só o commit sanitizado)
2. Push de `desenvolvimento`
3. Push da tag `backup-original-2026-07-18`
4. Criar um projeto **novo e dedicado** na Vercel, exclusivamente para desenvolvimento (nunca o legado)
5. Conectar esse projeto novo ao repositório GitHub
6. Configurar variáveis de ambiente (Production e Preview — valores em `_etapa0/06-instrucoes-preview-vercel.md`)
7. Configurar Build Command (`node scripts/generate-config.js`) e Output Directory (raiz)
8. Testar o preview
9. Checkpoint 0.9 (teste de isolamento) — decidir antes qual e-mail de teste será o primeiro admin (o trigger `trg_first_admin` promove automaticamente a primeira conta criada)

## Regras que continuam valendo
- Nunca conectar/alterar o projeto Vercel legado ou o domínio `painel.roneidegonzaga.com`
- Nunca criar usuário no Supabase antes de decidir qual e-mail será o primeiro admin
- Sempre confirmar visualmente o projeto-alvo (DEV vs. legado/produção) antes de qualquer ação na Vercel ou no Supabase
- Nenhuma credencial deve ser colada na conversa — confirmar ações por nome/hash, nunca por valor
