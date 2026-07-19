# Estratégia de migrations (Checkpoint 0.5)

**Nenhum SQL foi executado.** Este documento descreve a reorganização proposta e o resultado da análise de ordem/dependência/idempotência do `setup-supabase.sql` original.

## 1. Divisão proposta

| Arquivo | Conteúdo | Corresponde a |
|---|---|---|
| `migrations/0000_baseline.sql` | `profiles` + funções/trigger + 12 tabelas iniciais + RLS do bloco 1 | Linhas 1–189 do arquivo original |
| `migrations/0001_v4_cursos_processos_documentos_timeline.sql` | `rg_alunos`, `rg_processos`, `rg_documentos`, `rg_etapas` + 1 `ALTER` + RLS | Bloco "NOVOS MODULOS (v4)" |
| `migrations/0002_v5_categorias_vendas_equipe_visitas_links_cursos.sql` | `rg_categorias`, `rg_vendas`, `rg_equipe`, `rg_visitas`, `rg_links`, `rg_cursos` + 14 `ALTER` + RLS | Bloco "NOVOS MODULOS (v5)" |

Os três arquivos foram criados nesta pasta com o conteúdo **extraído verbatim** do arquivo original (nenhum comando foi reescrito ou "corrigido") — a reorganização é só de arquivo, não de conteúdo.

## 2. Análise de ordem e dependência

- **Ordem correta confirmada:** 0000 → 0001 → 0002, na mesma ordem em que já aparecem no arquivo original.
- **Blocos repetidos:** nenhum encontrado — cada `CREATE TABLE`, `ALTER TABLE ADD COLUMN` e definição de função aparece exatamente uma vez em todo o arquivo.
- **`ALTER TABLE` dependentes de tabela criada em bloco anterior:** confirmados e corretamente ordenados — por exemplo, os `ALTER TABLE rg_clientes` do bloco v5 dependem de `rg_clientes` já existir (criada no bloco 0000); os `ALTER TABLE rg_documentos`/`rg_etapas` do bloco v5 dependem de tabelas criadas no bloco 0001.
- **Políticas que substituem políticas anteriores:** cada bloco de RLS só cria a política `"membros acessam"`/`"admin acessa"` nas tabelas daquele próprio bloco — nenhuma tabela tem sua política redefinida por um bloco posterior.
- **Funções redefinidas:** nenhuma função é definida mais de uma vez no arquivo original; todas usam `CREATE OR REPLACE`, o que as torna seguras para redefinição futura se necessário.
- **Comandos não idempotentes:** **nenhum encontrado.** Todo `CREATE TABLE` usa `IF NOT EXISTS`; todo `ALTER TABLE ... ADD COLUMN` usa `IF NOT EXISTS`; toda função usa `CREATE OR REPLACE`; todo trigger e toda política usam `DROP IF EXISTS` antes de recriar. Isso significa que rodar os três arquivos, na ordem, contra um banco vazio ou contra um banco que já tenha alguns desses objetos, não deveria gerar erro de duplicidade.

## 3. Baseline segura proposta

Rodar `0000` → `0001` → `0002`, nessa ordem, contra um projeto Supabase de desenvolvimento **vazio**, é a forma mais segura de validar que a reorganização não introduziu nenhuma quebra — sem tocar produção.

## 4. Registro de aplicação por ambiente

Arquivo de controle criado: `migrations/status.md` — hoje mostra os três arquivos como "não aplicados" em nenhum ambiente. Deverá ser atualizado manualmente (ou por processo futuro) toda vez que uma migration for de fato aplicada em desenvolvimento ou produção.

## 5. Rollback documentado (não executado)

| Migration | Rollback (destrutivo — só usar em desenvolvimento vazio, nunca em produção com dados reais) |
|---|---|
| 0000 | `DROP TABLE` de todas as 13 tabelas do bloco (incluindo `profiles`), `DROP FUNCTION` das 3 funções, `DROP TRIGGER` |
| 0001 | `DROP TABLE rg_alunos, rg_processos, rg_documentos, rg_etapas`; `ALTER TABLE rg_clientes DROP COLUMN tipo_consultoria` |
| 0002 | `DROP TABLE rg_categorias, rg_vendas, rg_equipe, rg_visitas, rg_links, rg_cursos`; reverter as 14 colunas adicionadas |

## 6. Regras proibidas a partir de agora (conforme solicitado)

- SQL solto executado direto no SQL Editor do Supabase, sem existir como arquivo de migration versionado.
- Execução de qualquer migration sem identificar explicitamente o ambiente-alvo (nunca um destino padrão implícito).
- Alteração manual em produção sem registro correspondente no `migrations/status.md`.
