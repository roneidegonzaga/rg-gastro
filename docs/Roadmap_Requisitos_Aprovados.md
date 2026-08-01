# Roadmap — requisitos aprovados (ampliação de escopo registrada em 01/08/2026)

> Documento de requisitos, não de implementação. Nenhum código, banco de dados ou migration foi alterado para produzir isto — só leitura do schema já aplicado (`_etapa0/migrations/`) e do `app.html` atual, para classificar cada item como já existente, parcial ou novo.
>
> Base estrutural: `_fontes-planejamento/Plano_Revisado_Painel_RG_Gastro.md` (ordem de etapas, seção 2). Esse arquivo é uma cópia congelada da fonte externa e não foi editado — este documento é complementar a ele, não uma substituição.

---

## 1. Distribuição por etapa

### Etapa 2 — Equipe, permissões e acessos

| Requisito | Situação atual | Observação |
|---|---|---|
| Organização de usuários por equipe (agrupamento) | **Novo** | `rg_equipe` ([`0002_v5...sql:48-54`](../_etapa0/migrations/0002_v5_categorias_vendas_equipe_visitas_links_cursos.sql:48)) só tem pessoas individuais (nome, cargo, função) — não existe conceito de "time"/grupo. |
| Permissões por função | **Novo** | O plano já previa Camada 1 (módulo × usuário) — função como unidade adicional de permissão amplia esse desenho. |
| Permissões por usuário | **Já previsto** | Já é a Camada 1 descrita na Etapa 2 do `Plano_Revisado...md` (seção 3.4) — não é item novo, só confirma o que já estava no escopo. |
| Permissões por seção | **Já previsto** | Camada 1 = por módulo, que é essencialmente "seção" — mesmo caso acima. |

### Etapa 3 — Projetos, tarefas e status

| Requisito | Situação atual | Observação |
|---|---|---|
| Comentários em projetos e tarefas | **Novo** | Nenhuma tabela de comentários existe hoje. |
| Anexos | **Novo — depende da Etapa 6B** | Sem infraestrutura de Storage, cairia no padrão antigo de base64 que o próprio plano já quer descontinuar. |
| Dependências entre tarefas | **Novo** | `rg_tarefas` ([`0000_baseline.sql:161-169`](../_etapa0/migrations/0000_baseline.sql:161)) não tem nenhum vínculo tarefa→tarefa. |
| Indicação de tarefas bloqueadas por outras | **Novo** | Deriva do item acima. |
| Percentual de conclusão do projeto | **Novo** | `rg_projetos` ([`0000_baseline.sql:153-159`](../_etapa0/migrations/0000_baseline.sql:153)) só tem `status` (ativo/concluido/pausado), sem percentual. |
| Percentual de conclusão das tarefas | **Novo** | `rg_tarefas.status` é só aberta/fazendo/feita, sem percentual. |
| Tarefas recorrentes | **Novo** | Nenhum campo de recorrência em `rg_tarefas`. |
| Atribuição de tarefas a usuários | **Parcial** | `rg_tarefas.responsavel` já existe ([`0000_baseline.sql:166`](../_etapa0/migrations/0000_baseline.sql:166)), mas é texto livre, não um vínculo formal a `profiles.user_id`. |
| Atribuição de tarefas a equipes | **Novo — depende do conceito de equipe (Etapa 2)** | Não existe "equipe" como entidade ainda. |
| Histórico de alterações e responsáveis | **Novo** | Não existe tabela de auditoria para tarefas/projetos hoje; a Etapa 2 já prevê uma tabela de auditoria para permissões — pode ser reaproveitada ou espelhada. |

**Dependência já existente no plano, reafirmada:** Etapa 3 depende de Etapa 2 concluída (obrigatória, não "idealmente" — conforme `Plano_Revisado...md`, seção 4). Isso já cobre a nova dependência de "atribuição por equipe" sem quebrar a ordem atual.

### Etapa 5 — Financeiro, Metas e Visão Geral

**Bloco Financeiro:**

| Requisito | Situação atual | Observação |
|---|---|---|
| Categorias financeiras | **Parcial** | `rg_financeiro.categoria` e `rg_contas.categoria` já existem ([`0000_baseline.sql:74`](../_etapa0/migrations/0000_baseline.sql:74) e [`:85`](../_etapa0/migrations/0000_baseline.sql:85)) como texto livre — o requisito implica uma lista gerenciável, não só o campo solto. |
| Centros de custo | **Novo** | Nenhum campo equivalente em `rg_financeiro` ou `rg_contas`. |
| Receitas e despesas recorrentes | **Parcial** | `rg_contas.recorrente` já existe ([`0000_baseline.sql:89`](../_etapa0/migrations/0000_baseline.sql:89), hoje só `null | mensal`) — mas só em Contas a pagar/receber, não em `rg_financeiro` (lançamentos diretos). |
| Controle de inadimplência | **Parcial/derivável** | `rg_contas` já tem `vencimento` + `status` ([`:87-88`](../_etapa0/migrations/0000_baseline.sql:87)) — dá para calcular sem mudar schema, falta indicador/UI. |
| Identificação de parcelas vencidas | **Parcial/derivável** | Mesma base de dados do item acima. |
| Filtros por categoria/centro de custo/recorrência/situação | **Parcial** | Categoria, recorrência e situação já são filtráveis pelos campos existentes; centro de custo depende do item novo acima. |
| Indicadores de valores vencidos e a vencer | **Novo** | Dado-base existe, indicador dedicado não. |

**Bloco Metas:**

| Requisito | Situação atual | Observação |
|---|---|---|
| Metas de atendimento | **Novo** | `rg_metas` ([`0000_baseline.sql:94-99`](../_etapa0/migrations/0000_baseline.sql:94)) só tem categorias infoproduto/consultoria/mentoria/total — "atendimento" não existe como categoria. |
| Metas individuais e por equipe | **Novo — depende do conceito de equipe (Etapa 2)** | `rg_metas` não tem coluna de pessoa nem de equipe. |
| Valor planejado | **Parcial** | `rg_metas.valor` já cumpre esse papel. |
| Valor realizado | **Parcial/derivável** | Hoje calculado a partir de `rg_financeiro`, não armazenado — comportamento a preservar ou rever. |
| Percentual atingido | **Novo** | Não armazenado hoje; decisão de desenho pendente (calcular em tempo real ou persistir). |
| Filtros por período, pessoa e equipe | **Parcial** | Período (`mes`) já existe; pessoa e equipe são novos. |

### Etapa 6C — Isolamento dos processos *(ampliação de escopo proposta — ver ressalva)*

| Requisito | Situação atual | Observação |
|---|---|---|
| Arquivamento de processos | **Novo** | `rg_processos` ([`0001_v4...sql:26-33`](../_etapa0/migrations/0001_v4_cursos_processos_documentos_timeline.sql:26)) não tem nenhum campo de status/arquivado. |
| Área para consultar processos arquivados | **Novo** | Depende do campo acima. |
| Restaurar processo arquivado | **Novo** | Depende do campo acima. |
| Data da última revisão | **Novo** | Só existe `atualizado` (timestamp de qualquer edição, não um campo de "revisão" formal). |
| Próxima data de revisão | **Novo** | Nenhum campo equivalente. |
| Responsável pela revisão | **Novo** | Nenhum campo equivalente. |
| Histórico de versões ou alterações relevantes | **Novo — dependência condicional** | Se incluir anexos/arquivos versionados, depende também da Etapa 6B; se for só registro textual de mudanças, não depende. |

> ⚠ **Ressalva a confirmar com você:** a descrição atual da Etapa 6C no `Plano_Revisado...md` é só "isolamento dos processos" (segregação por cliente/mentorado) — os itens acima ampliam esse escopo para o ciclo de vida completo do processo (arquivar, revisar, versionar). Estou propondo a Etapa 6C como o lugar mais próximo por ser a etapa dedicada ao módulo Processos, **não porque o plano já previa isso** — precisa da sua confirmação antes de virar posição definitiva no roadmap.

### Relatórios — necessidade futura registrada (sem posição fixa comprometida)

Conforme instrução explícita: registrar, não implementar nem comprometer o roadmap atual.

| Relatório | Módulo/etapa mais próximo | Observação |
|---|---|---|
| Relatórios educacionais | Cursos / Certificados / Vendas e Alunos (Etapa 1C é a única com número de etapa nessa área hoje) | Registrado como necessidade futura — **não** adiciona escopo à Etapa 1C agora, conforme sua instrução anterior de não criar módulo novo nem alterar o roadmap atual neste momento. |
| Relatórios de desempenho da equipe | Etapa 2 | — |
| Relatórios de atendimento | Etapa 6A / 6D (Clientes e Mentorados) | — |
| Relatórios de inadimplência | Etapa 5 | — |
| Relatórios por centro de custo | Etapa 5 | Depende de "centros de custo" existir primeiro (ver bloco Financeiro acima). |
| Relatórios de execução de projetos e tarefas | Etapa 3 | — |

Todos dependem, para virarem PDF de fato, do motor de geração da **Etapa 6B** — isso é sobre a entrega do relatório, não sobre os dados, que continuam pertencendo a cada módulo de origem (regra "não criar módulo independente" respeitada).

---

## 2. Dependências novas identificadas (além das já existentes no plano)

- **Conceito de "equipe" (agrupamento de pessoas)** precisa nascer na Etapa 2 antes de: atribuição de tarefas por equipe (Etapa 3) e metas por equipe (Etapa 5). Como a Etapa 3 já depende obrigatoriamente da Etapa 2 concluída, e a Etapa 5 já depende das Etapas 1A/1B/1C (não da 2), **a Etapa 5 passa a também depender, na prática, da Etapa 2** para a parte de metas por pessoa/equipe — dependência nova que não existia no plano revisado, registrada aqui para sua decisão.
- **Anexos em Projetos/Tarefas (Etapa 3)** dependem da Etapa 6B — mesma lógica de dependência já usada para Etapa 6C/6D/7 no plano original.
- **Histórico de versões em Processos (Etapa 6C)** pode depender da Etapa 6B, condicionalmente (ver tabela acima).

## 3. Itens já cobertos pelo escopo atual (sem necessidade de nova posição no roadmap)

- Permissões por usuário e por seção — já fazem parte da Camada 1 da Etapa 2.

## 4. O que não foi decidido aqui (aguardando você)

1. Confirmar se a ampliação de escopo da Etapa 6C (arquivamento/revisão/versionamento de Processos) é aceita como proposta, ou se deve virar uma etapa própria.
2. Decidir se "valor realizado" e "percentual atingido" (Metas) devem ser persistidos em `rg_metas` ou continuar calculados em tempo real a partir de `rg_financeiro`.
3. Confirmar a lista de relatórios como registro de necessidade futura — nenhum foi posicionado como compromisso de entrega em nenhuma etapa específica.

---

*Nenhum código, tabela, coluna, política de RLS ou migration foi criado ou alterado para produzir este documento. `master` e o banco de produção não foram tocados.*
