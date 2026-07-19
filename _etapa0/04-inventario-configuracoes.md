# Inventário de configurações e credenciais (Checkpoint 0.3)

Varredura completa da cópia de desenvolvimento em busca de URLs do Supabase, chaves anônimas, Client ID do Google, tokens, connection strings, variáveis de ambiente, configuração da Vercel e identificadores de projeto. Nenhum valor completo é reproduzido neste documento — só nomes de arquivo, tipo de configuração, ambiente aparente e risco.

## Arquivos encontrados

| Arquivo | Tipo de configuração | Ambiente aparente | Rastreado pelo Git? | Risco |
|---|---|---|---|---|
| `config.js` | `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `GOOGLE_CLIENT_ID` (valores reais preenchidos) | **Produção** | **Sim** — commitado, está dentro do histórico do commit `6937d04` | **Alto** — a chave anônima e a URL reais de produção estão no histórico do Git. Isso nunca deve ser enviado a um repositório remoto sem antes rotacionar as credenciais ou reescrever o histórico. |
| `.env.local` | `VERCEL_OIDC_TOKEN` | Aparenta ser token de sessão da CLI da Vercel (tipicamente de curta duração) | Não — protegido por `.gitignore` (`.env*`) | Médio — não versionado, mas agora existe fisicamente em 3 pastas (origem, cópia intocável, cópia de desenvolvimento), por ter sido copiado junto com o restante dos arquivos. |
| `.vercel/project.json` | `projectId`, `orgId`, `projectName` (identificadores do projeto Vercel "rg-gastro") | **Produção** (projeto real vinculado) | Não — protegido por `.gitignore` (`.vercel`) | Baixo–médio — não são segredos de acesso por si só (não autenticam nada sozinhos), mas identificam de forma inequívoca o projeto de produção. Relevantes para impedir que o preview de desenvolvimento aponte para o projeto errado. |
| `docs/23-Configuracoes.md`, `docs/29-Configuracoes-Avancadas.md`, `docs/30-Regras-de-Desenvolvimento.md` | Texto descritivo sobre "configurações" como conceito de produto — parte da documentação aspiracional (Next.js/React) já sinalizada como não correspondente à arquitetura real | Nenhum valor real | Sim, rastreados | Nenhum |
| `LEIA-ME.md` | Instrução ao usuário sobre onde preencher a URL/chave dentro de `config.js` | Nenhum valor real | Sim, rastreado | Nenhum |

## Confirmação

As únicas configurações que hoje apontam definitivamente para **produção** são `config.js` (os 3 campos preenchidos) e `.vercel/project.json` (projeto real "rg-gastro"). Nenhum outro arquivo do projeto contém credencial real.

## Proposta de separação entre ambientes

| Ambiente | Onde vive a configuração | Estado atual |
|---|---|---|
| Produção | `config.js` (raiz do projeto) + `.vercel/project.json` | Existe e não deve ser alterado nesta etapa |
| Desenvolvimento local | `config.dev.js` (nunca commitado — precisa ser adicionado ao `.gitignore`) | **Não criado com valores reais nesta etapa.** Um arquivo de exemplo com placeholders foi criado: ver `config.dev.example.js` na raiz da cópia de desenvolvimento |
| Preview da Vercel | Variáveis de ambiente exclusivas do ambiente "Preview" no painel da Vercel, nunca herdando as de "Production" | Ainda não configurado — depende de ação manual (ver Checkpoint 0.8) |

## Ação tomada nesta etapa

Criado `config.dev.example.js` na raiz da cópia de desenvolvimento, contendo **somente placeholders inequívocos** (`SUPABASE_DEV_URL_A_PREENCHER`, `SUPABASE_DEV_ANON_KEY_A_PREENCHER`, `GOOGLE_CLIENT_ID_DEV_A_PREENCHER`), conforme solicitado. Nenhuma credencial real foi escrita nesse arquivo.

**Nenhum arquivo de produção foi alterado.**
