# Inventário do schema descrito no backup

> **Este documento descreve o que o arquivo `setup-supabase.sql` define, não o estado confirmado do banco de produção.** Ver seção final para o que ainda depende de consulta à produção.

- **Arquivo-fonte:** `setup-supabase.sql`
- **Checksum SHA-256 no momento desta análise:** `528a9a545c2067d2aeb8fd5764b7cbe6c609756cc2f2c71dba592aab57c01f5f`
- **332 linhas, 3 blocos incrementais** (baseline + "NOVOS MODULOS v4" + "NOVOS MODULOS v5")

---

## 1. Tabelas (23 no total)

### `public.profiles`
| Coluna | Tipo | Observação |
|---|---|---|
| `user_id` | uuid | PK, FK → `auth.users(id)` on delete cascade |
| `nome` | text | |
| `email` | text | |
| `role` | text | not null, default `'pendente'` — valores esperados (só em comentário, não em CHECK): `admin`, `equipe`, `pendente` |
| `aprovado` | boolean | not null, default `false` |
| `criado_em` | timestamptz | not null, default `now()` |

### Bloco baseline (v1) — 12 tabelas
`rg_financeiro`, `rg_contas`, `rg_metas`, `rg_crm`, `rg_clientes`, `rg_mentorados`, `rg_sessoes`, `rg_plano_itens`, `rg_projetos`, `rg_tarefas`, `rg_agenda`, `rg_dose`.

| Tabela | Colunas principais | Chaves estrangeiras |
|---|---|---|
| `rg_financeiro` | id, tipo, categoria, descricao, valor, data, criado_em | — |
| `rg_contas` | id, tipo, descricao, categoria, valor, vencimento, status, recorrente, ref, criado_em | — |
| `rg_metas` | id, mes, categoria, valor | — |
| `rg_crm` | id, nome, contato, origem, interesse, valor, etapa, obs, atualizado | — |
| `rg_clientes` | id, nome, restaurante, contato, cidade, status, inicio, valor_mensal, obs | — |
| `rg_mentorados` | id, nome, contato, produto, status, inicio, obs | — |
| `rg_sessoes` | id, mentorado_id, data, hora, resumo, status | `mentorado_id` → `rg_mentorados(id)` **cascade** |
| `rg_plano_itens` | id, mentorado_id, cliente_id, item, prazo, status | `mentorado_id` → `rg_mentorados(id)` **cascade**; `cliente_id` → `rg_clientes(id)` **cascade** |
| `rg_projetos` | id, nome, cliente_id, status, prazo | `cliente_id` → `rg_clientes(id)` **set null** |
| `rg_tarefas` | id, titulo, projeto_id, cliente_id, responsavel, prazo, status | `projeto_id` → `rg_projetos(id)` **set null**; `cliente_id` → `rg_clientes(id)` **set null** |
| `rg_agenda` | id, titulo, data, hora, tipo, ref, obs | — |
| `rg_dose` | cliente_id, key, value, updated_at — **PK composta (cliente_id, key)** | `cliente_id` → `rg_clientes(id)` **cascade** |

### Bloco v4 — "cursos, processos, documentos e linha do tempo" — 4 tabelas + 1 alteração
- `ALTER TABLE rg_clientes ADD COLUMN IF NOT EXISTS tipo_consultoria text`
- `rg_alunos`: id, nome, contato, curso, inicio, etapa (int, 0–9), obs, criado_em — sem FK
- `rg_processos`: id, nome, area, blocos (json em texto), atualizado, criado_em — **sem FK para cliente/mentorado** (achado já sinalizado no diagnóstico técnico — tabela global sem isolamento)
- `rg_documentos`: id, cliente_id, nome, tipo, url, criado_em — `cliente_id` → `rg_clientes(id)` **cascade**; **sem coluna `mentorado_id`**
- `rg_etapas`: id, cliente_id, nome, prazo, status, ordem, criado_em — `cliente_id` → `rg_clientes(id)` **cascade**

### Bloco v5 — "categorias, vendas, equipe, visitas, links, cursos e colunas extras" — 6 tabelas + 8 alterações
- `ALTER TABLE`: `rg_clientes` ganha `nascimento`, `aniversario_restaurante`, `drive_url`, `duracao_meses`; `rg_mentorados` ganha `encontros_total`; `rg_tarefas` ganha `curso_id`; `rg_documentos` ganha `projeto_id` e `curso_id`; `rg_etapas` ganha `descricao` e `atividades`; `rg_processos` ganha `acesso` (default `'todos'`) e `emails`; `rg_contas` ganha `recorrente_dias`; `rg_projetos` ganha `vinculo`.
- `rg_categorias`: id, dominio, nome, criado_em — sem FK
- `rg_vendas`: id, **transacao (unique, mas não `not null`)**, produto, nome, email, telefone, valor, liquido, status, data, fin_lancado, criado_em — sem FK
- `rg_equipe`: id, nome, email, cargo, funcao, tipo_contratacao, salario, nascimento, admissao, obs, criado_em — sem FK; **sem coluna `status`** (Ativo/Férias/Licença/Desligado ainda não existe)
- `rg_visitas`: id, cliente_id, data, consultor, atividades, a_desenvolver, obs, fotos (json em texto), criado_em — `cliente_id` → `rg_clientes(id)` **cascade**
- `rg_links`: id, titulo, url, area, acesso (default `'todos'`), emails, criado_em — sem FK
- `rg_cursos`: id, nome, descricao, drive_url, status, criado_em — sem FK

---

## 2. Funções (3, todas `SECURITY DEFINER`)
| Função | Linguagem | Propósito |
|---|---|---|
| `public.rg_first_admin()` | plpgsql | Trigger — primeiro usuário inserido em `profiles` vira admin automaticamente |
| `public.rg_is_member()` | sql | Retorna true se o usuário autenticado é membro aprovado |
| `public.rg_is_admin()` | sql | Retorna true se o usuário autenticado é admin aprovado |

## 3. Triggers (1)
`trg_first_admin` — `BEFORE INSERT ON public.profiles`, executa `rg_first_admin()`.

## 4. Índices
**Nenhum índice explícito além das chaves primárias.** Nenhuma das colunas de chave estrangeira (`mentorado_id`, `cliente_id`, `projeto_id`, `curso_id` etc.) tem índice próprio — só a PK de cada tabela. Isso é uma observação de desempenho para volumes maiores, não um erro funcional.

## 5. Row Level Security e políticas
RLS habilitado em **todas as 23 tabelas**. `profiles` tem 4 políticas nomeadas (leitura própria/admin, criação própria, edição própria/admin, exclusão só admin). As demais 22 tabelas recebem uma de duas políticas genéricas idênticas, aplicadas em massa por blocos `DO $$ ... $$` que percorrem arrays de nomes de tabela:

| Política | Tabelas | Regra |
|---|---|---|
| `"membros acessam"` | rg_crm, rg_clientes, rg_mentorados, rg_sessoes, rg_plano_itens, rg_projetos, rg_tarefas, rg_agenda, rg_dose, rg_alunos, rg_processos, rg_documentos, rg_etapas, rg_categorias, rg_visitas, rg_links, rg_cursos (17 tabelas) | Qualquer usuário aprovado (`rg_is_member()`) tem acesso total (select/insert/update/delete) |
| `"admin acessa"` | rg_financeiro, rg_contas, rg_metas, rg_equipe, rg_vendas (5 tabelas) | Só admin (`rg_is_admin()`) tem qualquer acesso |

Não existe granularidade por seção, por registro ou por coluna em nenhuma tabela — confirma o achado já registrado no diagnóstico técnico.

## 6. Constraints e validação de dados
- **Nenhuma constraint `CHECK`** em nenhuma tabela — todos os campos "tipo enumerado" (`status`, `tipo`, `role`, `etapa`, `acesso` etc.) são texto livre, com os valores esperados documentados apenas em comentário `--`, nunca reforçados pelo banco.
- `rg_vendas.transacao` é `UNIQUE`, mas não `NOT NULL` — Postgres permite múltiplas linhas com `transacao` nulo numa coluna unique; a aplicação (`app.html`) evita isso na prática pulando linhas sem transação (`if (!rw[iTrans]) continue;`), mas o banco por si só não impede.
- Nenhuma constraint de unicidade em `rg_clientes`/`rg_mentorados` (ex.: por nome, e-mail) — cadastro duplicado é possível.

## 7. Comportamento de exclusão (cascade) — inconsistente entre tabelas
| Tabela referenciando `rg_clientes`/`rg_mentorados` | Comportamento ao excluir o cliente/mentorado pai |
|---|---|
| `rg_sessoes`, `rg_plano_itens`, `rg_dose`, `rg_documentos`, `rg_etapas`, `rg_visitas` | **CASCADE** — todos os registros filhos são apagados silenciosamente |
| `rg_projetos`, `rg_tarefas` | **SET NULL** — o vínculo é desfeito, o registro permanece |

**Achado relevante:** excluir um cliente ou mentorado hoje apaga permanentemente (sem qualquer confirmação em cascata visível) sessões, itens de plano de ação, dados do D.O.S.E., documentos, etapas da linha do tempo e visitas associadas. Isso é particularmente importante para o desenho da Etapa 6A/6C/6D, que devem considerar se esse comportamento é o desejado ou se merece revisão (ex.: exclusão lógica em vez de física).

## 8. Observações de segurança
- As 3 funções `SECURITY DEFINER` não definem um `search_path` explícito — prática recomendada do Postgres/Supabase para evitar risco de manipulação de `search_path`. Não é uma falha ativa conhecida hoje, mas é um ponto de reforço recomendado para quando a Etapa 2 (permissões) for desenhada em detalhe.
- Nenhuma coluna de auditoria (`updated_by`, `deleted_at` etc.) existe em nenhuma tabela — consistente com o achado do diagnóstico técnico de que não há auditoria hoje.

## 9. Qualidade do script — observação positiva
Apesar dos pontos acima, o script é **bem escrito do ponto de vista de idempotência**: toda `CREATE TABLE` usa `IF NOT EXISTS`, toda `ALTER TABLE ... ADD COLUMN` usa `IF NOT EXISTS`, toda função usa `CREATE OR REPLACE`, todo trigger e toda política usam `DROP IF EXISTS` antes de recriar. Rodar o arquivo inteiro novamente contra o mesmo banco, do início ao fim, não deveria gerar erro — isso reduz o risco de aplicar a baseline num Supabase de desenvolvimento vazio (ver Checkpoint 0.5).

## 10. Cruzamento com o código (`app.html`)
O array `TABLES` usado pela camada de dados genérica do app (`DB.list/insert/update/remove`) lista 22 tabelas — **não inclui `rg_dose`**, que é gerida por um caminho de código separado (sincronização das ferramentas D.O.S.E. via `dose-sync.js`). Isso é esperado, não uma divergência de schema.

---

## O que está confirmado apenas pelos arquivos locais
- A estrutura exata que este arquivo, se executado do zero e sem erros, produziria — tabelas, colunas, tipos, FKs, funções, triggers e políticas listadas acima.

## O que só poderá ser confirmado consultando o Supabase de produção
- Se o banco de produção real tem **exatamente** essas tabelas e colunas hoje, sem alterações manuais feitas fora deste arquivo.
- Se todas as três seções (baseline, v4, v5) realmente rodaram por completo em produção, sem falhas parciais.
- Se existem políticas de RLS, grants, extensões ou índices adicionais configurados manualmente no painel do Supabase, que nunca vieram deste script.
- Se existem dados que hoje dependem de alguma regra não capturada aqui (ex.: valores de `status` diferentes dos documentados em comentário).

## Possíveis divergências
O próprio diagnóstico técnico já registrou que houve "uma tentativa posterior de ajustes que pioraram" a plataforma. É plausível que o banco de produção tenha colunas ou tabelas criadas manualmente fora deste arquivo, ou que este arquivo contenha trechos que nunca chegaram a rodar em produção. **Até que uma consulta de leitura à produção seja explicitamente autorizada, este documento deve ser tratado como "schema pretendido pelo backup", não como "schema confirmado da produção".**
