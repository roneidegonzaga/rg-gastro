# Plano revisado v2 — Painel RG Gastrô

**Ainda Etapa 1 — versão final consolidada, sem implementação**

Quatro correções objetivas aplicadas ao plano anterior: ordem entre permissões e tarefas, nova etapa de infraestrutura de arquivos/Storage/PDF, critério da Etapa 1A desacoplado da premissa "Aprovado = Completo", e Etapa 0 ampliada com backup/recuperação do Supabase.

- **Nenhum arquivo foi modificado**
- **Nenhum projeto, branch, tag ou banco criado/alterado**
- **Nenhum script SQL executado**
- **CSV original intocado**

---

## Sumário

1. [Correções realizadas](#1-correções-realizadas)
2. [Nova ordem completa](#2-nova-ordem-completa)
3. [Plano atualizado das etapas afetadas](#3-plano-atualizado-das-etapas-afetadas)
   - 3.1 [Matriz de normalização de status](#31-matriz-de-normalização-de-status--aguardando-aprovação)
   - 3.2 [Etapa 0 (ampliada)](#32-etapa-0--ambiente-seguro-backup-e-recuperação-ampliada)
   - 3.3 [Etapa 1A (corrigida)](#33-etapa-1a--auditoria-e-correção-da-importação-da-hotmart-critério-corrigido)
   - 3.4 [Etapa 2 — Permissões](#34-etapa-2--equipe-permissões-e-acessos-renumerada-de-etapa-3)
   - 3.5 [Etapa 3 — Tarefas](#35-etapa-3--projetos-tarefas-e-status-renumerada-de-etapa-2)
   - 3.6 [Etapa 6B (nova)](#36-etapa-6b--infraestrutura-de-arquivos-supabase-storage-e-geração-de-pdfpng-nova)
4. [Dependências atualizadas](#4-dependências-atualizadas)
5. [Riscos atualizados](#5-riscos-atualizados)
6. [Decisões ainda pendentes](#6-decisões-ainda-pendentes)
7. [Prompt operacional — só Etapa 0](#7-prompt-operacional--só-etapa-0)

---

## 1. Correções realizadas

**1. Ordem entre permissões e tarefas corrigida.** A antiga Etapa 2 (Projetos e Tarefas) e Etapa 3 (Equipe e Permissões) foram invertidas. Agora: **Etapa 2 = Equipe, permissões e acessos**, **Etapa 3 = Projetos, tarefas e status**. A Etapa 3 passa a consumir diretamente o mecanismo de permissões criado na Etapa 2 (visibilidade de tarefa por responsável e liberação cruzada usam a Camada 2 de permissões, não um controle solto) — elimina a contradição apontada e evita retrabalho.

**2. Nova Etapa 6B criada: Infraestrutura de arquivos, Supabase Storage e geração de PDF/PNG.** As antigas Etapa 6B (isolamento de processos) e Etapa 6C (relatórios) foram renumeradas para **6C** e **6D**. A sequência agora é: 6A (estrutura de clientes/mentorados) → 6B (infraestrutura de arquivos — nova) → 6C (isolamento de processos, depende de 6B para exportação) → 6D (relatórios, depende de 6B para armazenamento/PDF) → Etapa 7 (depende de 6A, 6B, 6D e das permissões).

**3. Critério da Etapa 1A corrigido.** Deixou de presumir que as 128 vendas do CSV devem entrar automaticamente em todos os indicadores. Agora separa explicitamente: linhas válidas lidas, registros gravados, quantidade por status, quantidade "venda ativa" segundo a regra aprovada, quantidade em faturamento bruto, quantidade em faturamento líquido, quantidade que gera lançamento financeiro. Uma **matriz de normalização de status** (seção 3.1) é apresentada como pré-requisito de aprovação antes de qualquer implementação da Etapa 1A — sem presumir que "Aprovado" e "Completo" são equivalentes.

**4. Etapa 0 ampliada com backup e recuperação do Supabase.** Além da separação de código/ambiente já prevista, a Etapa 0 agora inclui inventário do schema de produção, estratégia de backup (explicada, não executada), procedimento de restauração validado sempre contra o ambiente de desenvolvimento, migrations versionadas e numeradas, proibição de SQL solto sem versionamento, e a regra explícita de que nenhuma credencial privilegiada (service role) pode existir no frontend.

---

## 2. Nova ordem completa

A ordem definida foi conferida contra todas as dependências (antigas e novas). Ela é internamente consistente — nenhuma etapa depende de algo que vem depois dela.

1. Etapa 0 — Ambiente seguro, backup e recuperação
2. Ajustes urgentes de baixo risco
3. Etapa 1A — Auditoria e correção da importação da Hotmart
4. Etapa 1B — Lotes de importação, reprocessamento e exclusão
5. Etapa 1C — Filtros, indicadores e funcionamento de Vendas e Alunos
6. **Etapa 2 — Equipe, permissões e acessos** *(era Etapa 3)*
7. **Etapa 3 — Projetos, tarefas e status** *(era Etapa 2)*
8. Etapa 4 — Agenda e integração com o Google Agenda
9. Etapa 5 — Financeiro, Metas e Visão Geral
10. Etapa 6A — Estrutura de clientes e mentorados
11. **Etapa 6B — Infraestrutura de arquivos, Storage e geração de PDF/PNG** *(nova)*
12. **Etapa 6C — Isolamento dos processos** *(era 6B)*
13. **Etapa 6D — Relatórios de clientes e mentorados** *(era 6C)*
14. Etapa 7 — Propostas, contratos e documentos comerciais
15. Etapa 8 — Checklists e integração com processos
16. Etapa 9 — Comunicação interna
17. Etapa 10 — Perfil e configurações do usuário
18. Etapa 11 — Marketing e Conteúdo, parte operacional
19. Etapa 12 — Marketing e Conteúdo, analytics e campanhas
20. Etapa 13 — Revisão global de UX, navegabilidade e responsividade

> ℹ **Único ponto de atenção (não é violação de dependência — é perda de economia de esforço).** No plano anterior, a Etapa 4 (Agenda) e a antiga etapa de PDF poderiam compartilhar a mesma base de funções serverless. Com a nova Etapa 6B na posição 11 e a Etapa 4 mantida na posição 8, essa oportunidade de reaproveitamento se perde — as duas infraestruturas serverless provavelmente serão construídas separadamente. Isso **não quebra nenhuma dependência**, só representa um pouco mais de esforço total. Nada foi reordenado por conta disso — fica registrado para decisão: se quiser aproveitar a economia, a Etapa 4 poderia vir depois da 6B; do jeito que está, a ordem funciona normalmente, só não é a mais econômica em esforço de infraestrutura.

---

## 3. Plano atualizado das etapas afetadas

### Referência rápida (inalteradas desta rodada)

- **Análise do CSV:** 128 linhas de dados — confirmado novamente que **não é** o arquivo original de "mais de mil registros" citado no problema inicial. Status: `Aprovado` (25 · 19,5%) e `Completo` (103 · 80,5%), sem variação de grafia.
- **Causa confirmada:** `app.html:2367` — `v.status === 'Aprovado'` não reconhece `Completo`. Explica tanto a subcontagem de vendas quanto o "154 já existiam, mas só 27 aparecem".

### 3.1 Matriz de normalização de status — aguardando aprovação

Pré-requisito obrigatório antes de qualquer implementação da Etapa 1A. Enquanto esta matriz não for aprovada, nenhuma linha do CSV é tratada como "venda ativa" por padrão — inclusive as que hoje já mostram "Aprovado".

| Status original | Ocorrências | Nome padronizado | Venda ativa? | Faturamento bruto? | Faturamento líquido? | Gera lançamento? | Aparece nos indicadores? | Aparece na lista de alunos? |
|---|---|---|---|---|---|---|---|---|
| `Aprovado` | 25 | *a definir* | *a definir* | *a definir* | *a definir* | *a definir* | *a definir* | *a definir* |
| `Completo` | 103 | *a definir* | *a definir* | *a definir* | *a definir* | *a definir* | *a definir* | *a definir* |
| Reembolso/Reembolsado | 0 (não observado) | *a definir* | Não | *a definir* | Não — estorna se lançado | Não — estorna | *a definir* | *a definir* |
| Cancelado | 0 (não observado) | *a definir* | Não | Não | Não | Não — estorna se lançado | *a definir* | *a definir* |
| Chargeback | 0 (não observado) | *a definir* | Não | Não | Não | Não — estorna se lançado | *a definir* | *a definir* |

Todas as células "a definir" são propostas em branco de propósito — nenhuma foi presumida. Perguntas que mais ajudariam a preencher com segurança:
1. Confirmar com a Hotmart (ou observar o mesmo período numa nova exportação futura) se "Completo" e "Aprovado" são o mesmo evento em nomes diferentes ou dois estágios do ciclo de vida de uma venda.
2. Um exemplo real de "Reembolso"/"Cancelado" para confirmar o texto exato usado pela Hotmart.

**Sobre mudanças posteriores de status:** também em aberto. Proposta a avaliar (não decidida): se uma venda mudar de status depois de já ter gerado lançamento financeiro, criar um lançamento de ajuste rastreável, nunca editar silenciosamente o lançamento original.

> ⏸ **Aguardando aprovação.** A Etapa 1A não será implementada até esta matriz estar preenchida e aprovada — pode ser aprovada por partes.

### 3.2 Etapa 0 — Ambiente seguro, backup e recuperação *(ampliada)*

**Escopo completo (código + banco):**
- Preservação de cópia intocada do backup original; ponto de restauração no Git; branch de desenvolvimento
- Projeto Supabase separado para testes; preview separado na Vercel; isolamento comprovado
- **Inventário do schema atual de produção** — tabelas, colunas, funções, triggers e políticas RLS, documentado a partir da leitura de `setup-supabase.sql`
- **Verificação das opções de backup do plano atual do Supabase**
- **Exportação segura do schema** antes de qualquer alteração futura
- **Estratégia de backup dos dados** antes de migrations de maior risco
- **Procedimento documentado de restauração**, sempre validado contra o ambiente de desenvolvimento
- **Migrations versionadas e numeradas** — hoje o schema vive em blocos soltos num único arquivo; passam a ser arquivos individuais numerados, com registro de quais rodaram em cada ambiente
- **Proibição de SQL solto sem versionamento**
- **Confirmação de que nenhuma credencial privilegiada (service role) fica no frontend** — só a chave anônima está em `config.js` (padrão correto); a service role key nunca deve existir em arquivo carregado pelo navegador, só em variáveis de ambiente do servidor
- **Proteção contra o preview usar acidentalmente o Supabase de produção** — variáveis de ambiente da Vercel separadas por ambiente

**Método de backup recomendado:**
- **Se plano Pro ou superior:** backups diários automáticos do próprio Supabase (Database → Backups), possivelmente com restauração point-in-time. Primeira linha de defesa recomendada.
- **Se plano Free:** sem backup automático gerenciado. Alternativa: backup manual via `pg_dump`, usando a connection string do Postgres (credencial privilegiada, nunca em arquivo versionado).

**Passos que exigem ação manual do usuário:**
- Confirmar o plano atual do Supabase
- Criar o projeto Supabase de desenvolvimento
- Gerar/fornecer a connection string de backup (temporária, revogada depois de usada), se usarmos `pg_dump`
- Aprovar cada exportação/backup contra produção antes de acontecer
- Configurar variáveis de ambiente na Vercel

**Passos que podem ser preparados localmente (sem executar nada agora):**
- Ler `setup-supabase.sql` e montar o inventário do schema (documento, não ação)
- Preparar os comandos de backup/dump como instruções prontas
- Reorganizar as migrations existentes em arquivos numerados e versionados
- Redigir o checklist "antes de rodar contra produção"

**Acessos necessários:** acesso de owner/admin ao Supabase de produção; connection string de Postgres (só se `pg_dump`); acesso à Vercel para variáveis de ambiente.

**Como validar restauração:** nunca contra produção — sempre restaurando dentro do projeto de desenvolvimento e conferindo manualmente uma amostra dos dados restaurados.

**Como impedir migration no projeto errado:**
- Nomes/URLs de projeto visualmente muito diferentes entre dev e produção
- Checklist manual exigindo confirmar por escrito o projeto-alvo antes de rodar
- Nenhuma automação roda migration sem parâmetro explícito de ambiente (sem valor padrão)
- Variáveis de ambiente segregadas por ambiente na Vercel

**Critério de conclusão:** cópia intocada existe; ponto de restauração identificado; branch de desenvolvimento criada; projeto Supabase de teste isolado e comprovado; preview funcional; inventário completo do schema documentado; estratégia de backup confirmada e testada; migrations versionadas e numeradas; nenhuma credencial privilegiada fora do servidor; variáveis de ambiente corretamente segregadas.

### 3.3 Etapa 1A — Auditoria e correção da importação da Hotmart *(critério corrigido)*

- **Objetivo:** Corrigir o parser e a lógica de leitura para que 100% das linhas válidas sejam lidas e classificadas corretamente — segundo a matriz de status aprovada, não uma presunção de equivalência.
- **Escopo:** Idêntico à rodada anterior (parser preservado, normalização de cabeçalhos/espaços, validação de campos obrigatórios, registro estruturado de erro, correção do contador, relatório final).

**Relatório de importação — números que precisam ser rastreáveis separadamente:**
- Quantidade de linhas válidas lidas
- Quantidade de registros gravados
- Quantidade classificada em cada status (ex.: 25 Aprovado, 103 Completo, neste arquivo)
- Quantidade considerada "venda ativa" **segundo a regra aprovada** — não presumida
- Quantidade considerada no faturamento bruto
- Quantidade considerada no faturamento líquido
- Quantidade que gera lançamento financeiro

Neste CSV de teste, os três primeiros números já são conhecidos (128 lidas, 128 gravadas, 25+103 por status) — os quatro últimos dependem da matriz de status estar aprovada.

**Critério de conclusão (corrigido):**
- 100% das linhas válidas são lidas
- Nenhuma linha válida desaparece silenciosamente
- Todas as linhas são classificadas de acordo com a regra de status aprovada
- Os contadores do relatório de importação correspondem ao resultado real
- Nenhuma linha inválida interrompe o processamento das demais
- Nenhuma venda gera lançamento financeiro fora da regra aprovada

- **Fora do escopo:** Conceito de "lote" (Etapa 1B); filtros/indicadores (Etapa 1C); decidir a própria matriz de status (é aprovação, não implementação).
- **Arquivos afetados:** `app.html:2332-2432`.
- **Riscos:** Alto — venda "ativa" pode gerar lançamento automático no Financeiro; sem a matriz aprovada, a etapa não tem como saber o que é seguro lançar.
- **Dependências:** **Matriz de normalização de status aprovada**; Etapa 0.
- **Como testar:** Reimportar este CSV no ambiente de teste e conferir os 7 números do relatório, comparando com o que a matriz aprovada determina.

### 3.4 Etapa 2 — Equipe, permissões e acessos *(renumerada de Etapa 3)*

- **Objetivo:** Base de permissões em duas camadas (módulo + registro sensível), via RLS, mais os novos status de equipe. Construída **antes** de Projetos e Tarefas para que esta já nasça usando o mecanismo definitivo.
- **Escopo:** Camada 1 (módulo — Financeiro, CRM, Projetos e Tarefas, Processos, Agenda, Clientes, Mentorados, Cursos, Certificados, Vendas e Alunos, Marketing e Conteúdo, Propostas e Contratos, Comunicação Interna, Equipe e Permissões); Camada 2 (registros sensíveis); status Ativo/Férias/Licença/Desligado; regra de "nunca zero admin ativo"; auditoria; tudo validado por RLS.
- **Arquivos afetados:** `app.html:1520-1568`; RLS de praticamente todas as 24 tabelas.
- **Banco/migrations:** Tabela de permissões por módulo/usuário; tabela/coluna de permissão por registro sensível; coluna `status` em `rg_equipe`; tabela de auditoria; novas políticas de RLS.
- **Riscos:** Alto — reescreve políticas de segurança de quase todas as tabelas.
- **Dependências:** Etapa 0.
- **Critério de conclusão:** Admin configura, por pessoa, módulos e registros sensíveis; regra "nunca zero admin" impossível de violar; Desligado bloqueia mas preserva; auditoria registra toda mudança; **mecanismo já pronto para a Etapa 3 consumir diretamente**.

### 3.5 Etapa 3 — Projetos, tarefas e status *(renumerada de Etapa 2)*

- **Objetivo:** Visibilidade correta de tarefas por padrão, status mais claro, filtros completos — usando o mecanismo de permissões já existente.
- **Escopo:** Filtro "Fazendo" isolado; prazo personalizado; visibilidade padrão por responsável (Camada 2 da Etapa 2); admin libera visibilidade cruzada pelo mesmo mecanismo; concluídas saem da lista ativa.
- **Fora do escopo:** Sincronização com "Plano de ação" dos mentorados (Etapa 6A).
- **Arquivos afetados:** `app.html:1146-1307`.
- **Banco/migrations:** Campo de visibilidade em `rg_tarefas`, usando diretamente a tabela de permissões da Etapa 2 — não uma coluna paralela isolada.
- **Riscos:** Baixo–médio.
- **Dependências:** **Etapa 2 concluída** — dependência direta e obrigatória, não mais "idealmente".
- **Critério de conclusão:** Filtro "Fazendo" existe; prazo personalizado funciona; visibilidade padrão por responsável usando o mecanismo genérico; concluídas saem da lista; nenhum controle de visibilidade solto criado à parte.

### 3.6 Etapa 6B — Infraestrutura de arquivos, Supabase Storage e geração de PDF/PNG *(nova)*

- **Objetivo:** Construir de uma vez a infraestrutura de arquivos e geração de documentos que Processos, Relatórios e Propostas/Contratos vão reutilizar.

**Escopo:**
- Criação e configuração dos buckets no Supabase Storage
- Estrutura de pastas isolada por empresa, cliente, mentorado e módulo
- Metadados de arquivo no banco: nome, caminho, bucket, tipo MIME, extensão, tamanho, proprietário, cliente/mentorado vinculado, módulo de origem, responsável pelo envio, data, permissões, status, versão, hash
- Políticas de acesso e RLS do Storage, alinhadas ao mecanismo da Etapa 2
- Validação de tipo MIME e tamanho antes do upload
- Upload, download, substituição, versionamento e exclusão segura
- Controle de arquivos órfãos
- **Compatibilidade com arquivos antigos em base64** — leitura simultânea do formato antigo e do novo durante a transição
- Plano de migração gradual (módulo por módulo) e auditoria de cada migração
- Serviço reutilizável de geração de PDF (função serverless, navegador headless)
- Geração de PNG para processos, no navegador (canvas)
- Armazenamento do documento final com preservação da versão finalizada
- Autenticação e autorização das funções serverless
- Avaliação de limites e custos de execução da Vercel
- Tratamento de falhas e timeouts, com mensagem clara e possibilidade de tentar de novo

- **Fora do escopo:** Migração retroativa completa de todos os arquivos já existentes (é gradual, nas etapas seguintes); conteúdo específico de cada relatório/contrato (6D e 7); lógica de negócio de Processos/Clientes/Mentorados em si.
- **Arquivos afetados:** Novo componente/serviço fora de `app.html` (funções serverless); pequenas adições em `app.html` para helpers de upload/download.
- **Alterações no banco:** Nova tabela de metadados (ex.: `rg_arquivos`); coluna de referência nos módulos que hoje usam base64, mantendo a coluna antiga intacta durante a transição.
- **Migrations:** Criação de `rg_arquivos`; colunas novas (nulas por padrão); nenhuma coluna antiga removida nesta etapa.
- **Funções serverless:** Geração de PDF (headless browser); intermediação de upload/download quando necessário — nenhuma usa credencial privilegiada exposta ao navegador.
- **Buckets:** Proposta inicial — um por grande área (`documentos-clientes`, `documentos-mentorados`, `relatorios`, `processos`, `contratos`), cada um com política própria; nomenclatura final fica para o desenho técnico detalhado.
- **Políticas de acesso:** Espelham o mecanismo da Etapa 2 — nenhuma política de Storage isolada.
- **Riscos:** Alto — duas peças de infraestrutura novas ao mesmo tempo; compatibilidade retroativa é o ponto mais delicado.
- **Dependências:** Etapa 6A; Etapa 2; decisão de arquitetura serverless (compartilhável com a Etapa 4).
- **Checkpoint:** Arquivo salvo antes desta etapa continua abrindo normalmente depois; arquivo novo via Storage também abre normalmente; nenhum dos dois se mistura ou corrompe.
- **Rollback:** Colunas antigas não removidas — reverter é possível sem perda, desativando os novos caminhos e voltando ao base64 até a causa ser corrigida.
- **Como testar:** No ambiente de desenvolvimento — subir arquivo novo via Storage; confirmar leitura de arquivo antigo em base64; gerar PDF de teste e confirmar que a versão finalizada não muda ao editar o modelo depois; forçar timeout e confirmar erro claro e recuperável.
- **Critério de conclusão:** Buckets criados e organizados; metadados completos; upload/download/substituição/versionamento/exclusão funcionando; arquivos antigos continuam legíveis; PDF/PNG funcionando como serviço único; nenhuma credencial privilegiada exposta; falhas e timeouts tratados com mensagem clara.

*Não implementada nesta etapa — nenhum bucket, política, função serverless ou migration foi criado.*

### Demais etapas afetadas apenas por renumeração/dependência (conteúdo inalterado)

- **Etapa 6C — Isolamento dos processos** *(era 6B)*: conteúdo inalterado. Nova dependência: Etapa 6B, para exportação em PDF/PNG.
- **Etapa 6D — Relatórios de clientes e mentorados** *(era 6C)*: conteúdo inalterado. Nova dependência: Etapa 6B, para armazenamento e geração de PDF.
- **Etapa 7 — Propostas e contratos**: conteúdo inalterado. Dependências atualizadas: Etapa 6A, **Etapa 6B**, Etapa 6D, Etapa 2.
- **Etapas 4, 5, 6A, 8, 9, 10, 11, 12, 13**: sem mudança de conteúdo nesta rodada, só de posição relativa quando aplicável (ver seção 2).

---

## 4. Dependências atualizadas

| Etapa | Depende de |
|---|---|
| Ajustes urgentes | Só da Etapa 0 |
| Etapa 1A | Etapa 0; **matriz de normalização de status aprovada** |
| Etapa 1B | Etapa 1A concluída |
| Etapa 1C | Etapas 1A e 1B; matriz de status aprovada |
| **Etapa 2 (permissões)** | Etapa 0 |
| **Etapa 3 (tarefas)** | **Etapa 2 concluída** (antes "idealmente"; agora obrigatória) |
| Etapa 4 | Decisão de arquitetura serverless; acesso ao Google Cloud Console |
| Etapa 5 | Etapas 1A/1B/1C concluídas |
| Etapa 6A | Etapa 2 (campos sensíveis); compartilha `rg_tarefas` com a Etapa 3 |
| **Etapa 6B (nova)** | Etapa 6A; Etapa 2; decisão de arquitetura serverless |
| Etapa 6C (processos) | Etapa 2; **Etapa 6B** (exportação); revisão manual da classificação |
| Etapa 6D (relatórios) | Etapa 2; **Etapa 6B** (armazenamento/PDF) |
| Etapa 7 | Etapa 6A; **Etapa 6B**; Etapa 6D; Etapa 2 |
| Etapa 8 | Etapa 6C concluída |
| Etapa 9 | Nenhuma bloqueante |
| Etapa 10 | Nenhuma bloqueante |
| Etapa 11 | Etapa 2 |
| Etapa 12 | Etapa 11 |
| Etapa 13 | Praticamente todas as demais |

---

## 5. Riscos atualizados

**[Alto]** — Etapa 1A não pode avançar sem a matriz de status aprovada
Diferente da rodada anterior, o plano agora deixa isso explícito como bloqueio, não sugestão — evita implementação sobre regra de negócio não decidida.

**[Alto]** — Etapa 6B concentra duas peças de infraestrutura inteiramente novas
Storage real e funções serverless de uma vez. A compatibilidade retroativa com arquivos base64 é o ponto mais delicado — precisa de teste extensivo antes de qualquer módulo dependente (6C, 6D, 7) começar a usá-la.

**[Alto]** — Backup de produção depende de uma informação ainda não confirmada
O plano de Supabase (Free vs. Pro+) determina se há backup automático gerenciado ou se é preciso `pg_dump` manual — enquanto isso não for confirmado, a estratégia de backup da Etapa 0 fica parcialmente em aberto.

**[Médio]** — Perda de economia de esforço entre Etapa 4 e Etapa 6B
Não é violação de dependência, só possível retrabalho de infraestrutura serverless se construídas separadamente.

**[Médio]** — Migrations hoje não são versionadas
`setup-supabase.sql` é um único arquivo com blocos incrementais soltos — a Etapa 0 propõe corrigir isso, mas até lá qualquer alteração manual no SQL Editor foge do controle de versão.

**[Baixo]** — "Ajustes urgentes de baixo risco" continua seguro em qualquer momento
Nenhuma das quatro correções desta rodada afeta essa etapa.

---

## 6. Decisões ainda pendentes

1. **Matriz de normalização de status** — a mais urgente, bloqueia a Etapa 1A inteira. Pode ser aprovada por partes.
2. **Confirmação do plano atual do Supabase** (Free/Pro/Team) — decide o método de backup disponível na Etapa 0.
3. **Se "Completo" e "Aprovado" são o mesmo evento ou estágios diferentes** — alimenta diretamente a matriz de status.
4. **O arquivo CSV original do incidente** (dez/2024–jul/2026) — ajudaria a confirmar em escala real o mesmo mecanismo.
5. **Regra para lançamentos financeiros de um lote excluído/reprocessado** (Etapa 1B) — ainda em aberto.
6. **Decisão sobre Férias e Licença** (opções A/B/C) — ainda em aberto.
7. **Se vale reordenar a Etapa 4 para depois da Etapa 6B** — só para aproveitar a economia de esforço serverless, não é obrigatório.
8. **Nomenclatura final dos buckets do Storage** (Etapa 6B) — proposta inicial dada, decisão definitiva fica para o desenho técnico detalhado.

---

## 7. Prompt operacional — só Etapa 0

```
Autorizo a execução da Etapa 0 (ambiente seguro, backup e recuperação) do plano
revisado v2 do Painel RG Gastrô.

Execute apenas a Etapa 0, exatamente como descrita na seção 3.2 desse plano:
- copiar a pasta de backup original para um local separado, intocado;
- organizar o histórico no Git com uma tag/branch de ponto de restauração;
- criar uma branch de desenvolvimento;
- criar um novo projeto Supabase dedicado a testes e rodar setup-supabase.sql nele;
- criar uma configuração de desenvolvimento separada (config.dev.js) sem sobrescrever
  a de produção;
- criar um ambiente de preview na Vercel apontando para esse projeto de teste;
- confirmar e demonstrar o isolamento (registro de teste aparece só no banco de
  desenvolvimento);
- montar o inventário completo do schema de produção (tabelas, colunas, funções,
  triggers, políticas RLS) a partir da leitura de setup-supabase.sql;
- reorganizar as migrations existentes em arquivos numerados e versionados;
- me apresentar, sem executar, as opções de backup disponíveis conforme o plano do
  Supabase que eu confirmar, e o checklist de "antes de rodar contra produção".

Não toque no banco de produção. Não altere config.js de produção. Não faça deploy no
domínio real. Não execute nenhum backup ou pg_dump real sem minha aprovação explícita
de cada execução. Não avance para nenhuma outra etapa sem nova autorização minha.

Ao concluir, apresente o checkpoint definido (registro de teste confirmado isolado +
inventário de schema completo) e pare para minha aprovação antes de seguir para os
"Ajustes urgentes de baixo risco".
```

---

*Plano v2 — quatro correções aplicadas sobre o plano revisado anterior. Nenhum arquivo do projeto foi modificado, nenhum projeto/branch/tag/banco criado, nenhum script executado, CSV original intocado. Aguardando aprovação antes de qualquer implementação.*
