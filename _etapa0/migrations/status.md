# Registro de aplicação de migrations

| Migration | Desenvolvimento | Produção |
|---|---|---|
| 0000_baseline.sql | Não aplicada | Não aplicada (produção já tem o schema equivalente aplicado manualmente antes deste projeto de migrations existir — ver nota) |
| 0001_v4_cursos_processos_documentos_timeline.sql | Não aplicada | Não aplicada (idem) |
| 0002_v5_categorias_vendas_equipe_visitas_links_cursos.sql | Não aplicada | Não aplicada (idem) |

**Nota sobre produção:** o banco de produção já existe e presumivelmente já reflete o conteúdo equivalente a estas três migrations (aplicado originalmente como um único `setup-supabase.sql` colado no SQL Editor, antes deste sistema de versionamento existir). Estas migrations não devem ser rodadas contra produção — servem como baseline para o Supabase de **desenvolvimento**, e como ponto de partida versionado para qualquer alteração de schema **futura**, que a partir de agora deve vir como uma nova migration numerada (`0003_...sql` e assim por diante), nunca como SQL solto.

Este arquivo deve ser atualizado manualmente toda vez que uma migration for de fato aplicada em algum ambiente.
