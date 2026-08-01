# Registro de aplicação de migrations

| Migration | Desenvolvimento | Produção |
|---|---|---|
| 0000_baseline.sql | ✅ Aplicada em 31/07/2026, projeto `rg-gastro-DEV` — validada (13 tabelas, 3 funções, 1 trigger, RLS + 16 políticas, 0 usuários, 0 dados) | Não aplicada (produção já tem o schema equivalente aplicado manualmente antes deste projeto de migrations existir — ver nota) |
| 0001_v4_cursos_processos_documentos_timeline.sql | ✅ Aplicada em 31/07/2026, projeto `rg-gastro-DEV` — validada (4 tabelas, 1 coluna nova, 2 FKs cascade, RLS + política nas 4) | Não aplicada (idem) |
| 0002_v5_categorias_vendas_equipe_visitas_links_cursos.sql | ✅ Aplicada em 31/07/2026, projeto `rg-gastro-DEV` — validada (6 tabelas, 14 colunas novas, 1 FK cascade, 1 unique, RLS + políticas nas 6; total 23 tabelas no schema) | Não aplicada (idem) |
| 0003_v6_lotes_importacao_hotmart.sql (Etapa 1B.1) | ✅ Aplicada em 01/08/2026, projeto `rg-gastro-DEV` — executada via `../0003_execucao_e_validacao_supabase_DEV.sql` (migration + 9 validações + 4 testes de constraint, todos em blocos `DO $$...END $$` isolados); execução sem erro ("Success. No rows returned."). 2 tabelas novas (`rg_vendas_lotes`, `rg_vendas_alteracoes_historico`), 7 colunas novas em `rg_vendas`, 1 coluna nova em `rg_financeiro`, 10 índices, RLS + política admin-only nas 2 tabelas novas. Testes de constraint (2 válidos, 2 inválidos) comportaram-se como esperado, sem dado de teste persistido. Nenhuma alteração funcional em `app.html` acompanha esta migration (só schema) | Não aplicada — decisão própria, não experimental: nenhuma migration roda em produção sem autorização explícita separada |

**Nota sobre produção:** o banco de produção já existe e presumivelmente já reflete o conteúdo equivalente a estas três migrations (aplicado originalmente como um único `setup-supabase.sql` colado no SQL Editor, antes deste sistema de versionamento existir). Estas migrations não devem ser rodadas contra produção — servem como baseline para o Supabase de **desenvolvimento**, e como ponto de partida versionado para qualquer alteração de schema **futura**, que a partir de agora deve vir como uma nova migration numerada (`0003_...sql` e assim por diante), nunca como SQL solto.

**Schema do Supabase DEV concluído em 31/07/2026** — as 3 migrations rodaram na ordem correta, cada uma dentro de sua própria transação, todas validadas por consultas somente-leitura antes de avançar para a próxima. Nenhum usuário foi criado, nenhum dado real foi inserido. O schema do projeto `rg-gastro-DEV` agora espelha o schema descrito no backup (ver `../01-inventario-schema-backup.md`).

Este arquivo deve ser atualizado manualmente toda vez que uma migration for de fato aplicada em algum ambiente.
