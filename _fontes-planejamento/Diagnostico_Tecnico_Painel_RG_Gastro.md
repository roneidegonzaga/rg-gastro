# Diagnóstico técnico do sistema de gestão — Painel RG Gastrô

**Etapa 1 — Diagnóstico, sem implementação**

- **Fonte do código:** pasta de backup local (única fonte válida)
- **Fonte dos requisitos:** Registro de Análise do Sistema de Gestão
- **Data:** 18 de julho de 2026
- **Status:** nenhum arquivo do projeto foi alterado

Leitura integral da pasta de backup (código-fonte real) cruzada com o Registro de Análise e com os dois modelos de contrato, para orientar um plano de evolução por etapas testáveis e reversíveis.

**Legenda de status usada em todas as tabelas abaixo:**
`[Funcionando]` já implementado e funcionando · `[Parcial]` implementado parcialmente · `[Com problema]` existe, mas apresenta problema · `[Não implementado]` ainda não implementado · `[Não confirmado]` não foi possível confirmar

---

## Sumário

1. [Resumo da arquitetura atual](#1-resumo-da-arquitetura-atual)
2. [Diagnóstico por seção do documento](#2-diagnóstico-por-seção-do-documento)
3. [Matriz de impacto técnico](#3-matriz-de-impacto-técnico)
4. [Principais riscos](#4-principais-riscos)
5. [Plano de implementação por etapas](#5-plano-de-implementação-por-etapas)
6. [Dúvidas e pendências](#6-dúvidas-e-pendências)
7. [Recomendação da primeira etapa](#7-recomendação-da-primeira-etapa)

---

## 1. Resumo da arquitetura atual

O projeto já está publicado e funcionando — não é um projeto a ser iniciado. A stack real é bem mais simples do que a documentação interna do próprio projeto sugere, e essa divergência é, em si, o primeiro achado relevante.

> ⚠ **A pasta `docs/` descreve uma arquitetura que não existe no código.**
> Os 34 arquivos em `docs/` (criados em 16/07, dois dias depois do restante do backup) descrevem uma stack Next.js + TypeScript + React + Tailwind + shadcn/ui, com camadas Controllers/Services/Repositories, auditoria completa e um "serviço de IA". **Nada disso existe no código real.** O sistema publicado é HTML/CSS/JavaScript puro, sem framework, sem build, sem TypeScript. Se essa documentação for usada como referência técnica para decidir como implementar qualquer etapa, o caminho natural seria reescrever o projeto do zero em outra stack — o que contraria diretamente sua instrução de não reconstruir a plataforma. Recomendo tratar `docs/` como material à parte (visão de produto/negócio, não arquitetura), não como fonte técnica.

| Camada | O que realmente existe |
|---|---|
| **Frontend** | 3 arquivos: `index.html` (login, 388 linhas), `app.html` (painel inteiro — HTML, CSS e JavaScript no mesmo arquivo, 2.894 linhas), `config.js` (credenciais). Sem framework, sem bundler, sem etapa de build — os arquivos rodam exatamente como estão. |
| **Backend / API** | Não existe um backend próprio. O navegador fala diretamente com o Supabase usando a chave anônima (`anon key`). Toda regra de negócio (cálculos, validações, formatação) roda no JavaScript do navegador. |
| **Banco de dados** | Supabase (Postgres), schema em `setup-supabase.sql` — 24 tabelas, construídas em blocos incrementais (v1 → v4 → v5) diretamente com `ALTER TABLE`, sem migrations versionadas formalmente. |
| **Autenticação** | Supabase Auth (e-mail/senha + Google OAuth). Primeiro usuário cadastrado vira admin automaticamente; os demais entram como "pendente" até um admin aprovar. |
| **Autorização** | Row Level Security do Postgres, com duas funções auxiliares (`rg_is_member()`, `rg_is_admin()`). O sistema inteiro conhece apenas dois papéis: `admin` e `equipe` — não existe nenhuma permissão granular por seção, documento ou tarefa em nenhum lugar do banco. |
| **Armazenamento de arquivos** | Não há bucket do Supabase Storage em uso. Todo "upload" (documentos, fotos de relatório, imagens de processo) é gravado como texto base64 direto em colunas do Postgres — é essa a causa técnica dos limites de 1,5 MB e 400 KB relatados no documento de análise. |
| **Gráficos** | Chart.js 4.4.1 via CDN. É a única biblioteca de visualização do projeto. |
| **Geração de PDF/imagem** | Nenhuma biblioteca de PDF ou exportação de imagem existe no projeto (sem jsPDF, sem html2canvas, sem `window.print` dedicado). Toda funcionalidade de "exportar em PDF" pedida no documento de análise parte do zero. |
| **Inteligência artificial** | Nenhuma integração de IA (OpenAI ou outra) existe hoje em nenhuma tela. |
| **Integrações externas ativas** | Google Calendar (via Google Identity Services, token só em memória — não persiste); Google Drive (apenas link salvo pelo usuário, sem API); Hotmart (importação manual de arquivo CSV, sem API). |
| **Ferramentas anexas** | `ferramentas/` (21 páginas HTML do Sistema D.O.S.E.) e `ferramentas-pec/` (19 páginas HTML do PEC), abertas em iframe dentro do painel. `dose-sync.js` isola os dados de cada ferramenta por cliente no `localStorage` (prefixo `cli:ID:`) e replica para a tabela `rg_dose` no Supabase. |
| **Execução local** | Basta abrir `index.html` no navegador — sem servidor, sem instalação. Enquanto `config.js` estiver vazio, abre em modo demonstração com dados fictícios em `localStorage`. |
| **Deploy** | Vercel, projeto `rg-gastro` (`.vercel/project.json`), publicação estática — sem pipeline de CI/CD próprio além do que a Vercel oferece por padrão. |
| **Configuração externa necessária** | Projeto Supabase (URL + chave anônima em `config.js`); Google Cloud OAuth Client ID; domínio `painel.roneidegonzaga.com` apontado na Vercel e replicado em Authentication → URL Configuration no Supabase. |

> ⚠ **Este backup contém credenciais reais de produção.**
> `config.js` já vem preenchido com a URL, a chave anônima do Supabase e o Client ID do Google reais. O modo demonstração só se ativa quando esses campos estão vazios — aqui não estão. Ou seja: **abrir esta pasta de backup localmente (ou publicá-la em qualquer lugar) conecta direto ao banco de dados ao vivo**, não a um ambiente de teste.

> ℹ **Sobre o histórico do Git.**
> O repositório local tem um único commit (16/07), sem remoto configurado, que já inclui de uma vez o código de 14/07 e a documentação de 16/07. Não há como usar `git diff`/`git log` para comparar este backup com "a versão de antes dos ajustes que pioraram" — a análise a seguir se baseia inteiramente na leitura direta deste snapshot, tratado como a fonte de verdade combinada por você.

---

## 2. Diagnóstico por seção do documento

Cada um dos 24 tópicos do Registro de Análise foi verificado linha a linha no código real (`app.html`, `setup-supabase.sql`). Nenhuma classificação presume funcionamento pela simples existência de um botão ou campo — cada uma cita o trecho exato do código que a sustenta.

### 2.1 Visão Geral (dashboard executivo)

Estrutura geral funciona e recalcula com o filtro de período — mas metade dos cards prometidos (meta, comparação com período anterior, mini-gráfico) não existe, e dois blocos inteiros (objetivos estratégicos, despesas por categoria) estão ausentes.

| Requisito | Status | Evidência | Nota |
|---|---|---|---|
| Botão "Definir metas" → "Abrir metas" | `[Com problema]` | app.html:780,864 | Abre modal de edição, não navega para a seção. |
| Filtro único de período para todo o dashboard | `[Funcionando]` | app.html:650-674 | Alimenta todos os cards e os dois gráficos. |
| Card Receita total (meta, %, comparação, mini-gráfico, link) | `[Parcial]` | app.html:733 | Só valor + categorias + link; sem meta, comparação ou sparkline. |
| Card Despesas totais (mesmos elementos) | `[Parcial]` | app.html:734 | Mesma lacuna do card acima. |
| Card Resultado líquido (considerando cancelamentos/reembolsos) | `[Com problema]` | app.html:734,745 | É só uma linha de rodapé do card Despesas, não um card próprio; sem campo de cancelamento/estorno em nenhuma tabela. |
| Ticket médio por aluno = faturamento ÷ alunos únicos | `[Não implementado]` | — | Não existe na Visão Geral. Existe algo parecido em Vendas, mas dividindo por número de vendas, não de alunos — fórmula errada onde existe. |
| Card Contas a receber (total, qtd. em 7 dias, link) | `[Com problema]` | app.html:735 | Card combina pagar+receber numa janela de 30 dias, não isola "vencendo em 7 dias". |
| Rosca Composição da receita (valor central, %, legenda, link) | `[Parcial]` | app.html:777,850-851 | Existe com legenda e tooltip; falta valor central visível. |
| Gráfico único de evolução receita×despesa (hoje reclamado como 2 separados) | `[Funcionando]` | app.html:840-846 | Já é um gráfico combinado nesta tela (o problema dos "2 gráficos separados" é do Financeiro, ver 2.2). |
| Rosca Despesas por categoria | `[Não implementado]` | — | Não existe na Visão Geral. |
| Bloco Funil do CRM (nome, qtd., barra, cor, "Abrir CRM") | `[Funcionando]` | app.html:781,808-813 | Completo. |
| Bloco Metas do mês (Receita, Novos contratos, Novos alunos, Lucro líquido — separados) | `[Com problema]` | app.html:854-863 | Mostra só 3 categorias de receita; "Novos contratos"/"Novos alunos"/"Lucro líquido" não existem em lugar nenhum do sistema. |
| Bloco Próximos compromissos | `[Funcionando]` | app.html:791,816-824 | Completo. |
| Bloco Tarefas abertas (com prioridade) | `[Parcial]` | app.html:792,826-829 | Campo "prioridade" não existe em nenhum lugar do sistema, não só aqui. |
| Bloco Contas a pagar 7 dias (visual de vencida/próxima) | `[Funcionando]` | app.html:782,833-836 | Completo. |
| Bloco Objetivos estratégicos | `[Não implementado]` | — | Não existe em nenhum lugar do código ou do banco. |
| Hierarquia visual + todo card clicável | `[Parcial]` | app.html:733-739 | Cards de KPI são clicáveis; blocos maiores só têm link de texto interno, não o card inteiro. |

### 2.2 Financeiro

| Requisito | Status | Evidência | Nota |
|---|---|---|---|
| Filtro por período, cadastro, contas a pagar/receber, recorrência | `[Funcionando]` | app.html:942,987-1001,1043-1071 | Recorrência confirmada funcionando conforme você descreveu. |
| Filtrar lançamentos por só receita / só despesa / categoria | `[Não implementado]` | app.html:958-967 | Tabela de lançamentos não tem nenhum filtro; o único controle existente afeta apenas o gráfico de rosca. |
| Gráfico misto receita×despesa (hoje 2 separados) | `[Com problema]` | app.html:955-957,969-984 | O gráfico combinado só aparece quando o período cobre mais de 1 mês — no filtro padrão ("mês atual") ele simplesmente não renderiza. A rosca por categoria alterna receita/despesa em vez de mostrar as duas. |
| Contas a pagar/receber funcionando bem | `[Funcionando]` | app.html:1043-1071 | Confirma sua própria avaliação. |

### 2.3 Metas

| Requisito | Status | Evidência | Nota |
|---|---|---|---|
| Cadastro de meta por categoria (Infoprodutos/Consultorias/Mentorias) | `[Funcionando]` | app.html:867-874,921-927 | — |
| Sistema soma tudo e não detalha realizado por categoria | `[Com problema]` | app.html:887-888,895-909 | Confirmado: não existe em nenhum lugar do código um cálculo de realizado por categoria — só o total agregado. |
| Filtro de período: só 1 mês por vez | `[Com problema]` | app.html:893,931 | Confirmado; sem seleção de intervalo/múltiplos meses. |
| Linha da meta invisível quando coincide com o realizado | `[Não confirmado]` | app.html:913-916 | No código a linha (dourada) é desenhada por cima da barra (azul), com cores contrastantes — o comportamento relatado depende de renderização em tempo real do Chart.js e não pôde ser confirmado só pela leitura do código. |

### 2.4 CRM e Propostas

| Requisito | Status | Evidência | Nota |
|---|---|---|---|
| Kanban: Novo lead / Em conversa / Proposta enviada / Fechado / Perdido | `[Funcionando]` | app.html:1078 | Etapas batem exatamente. |
| Etapas de Follow-up (1/2/3) e "recuperação" | `[Não implementado]` | app.html:1078 | Lista de etapas é fixa, 5 itens. |
| Diferenciar dentro de "Perdido" (não respondeu/recusou/pode recuperar) | `[Não implementado]` | app.html:1094-1107 | Não existe campo de submotivo no formulário nem no banco. |

### 2.5 Propostas e Contratos

`[Não implementado]` — módulo inteiro ausente. Busca por "proposta", "contrato", "modelo" e por bibliotecas de PDF em `app.html` não encontra nenhum editor de modelo, geração de documento ou versionamento — apenas a etapa "proposta" do Kanban do CRM e menções livres de texto (ex.: anexar um link chamado "Contrato assinado" na aba de documentos genérica). Como o documento de análise pediu, nesta etapa a análise fica restrita ao lado técnico/estrutural — sem alterar o conteúdo jurídico dos dois modelos fornecidos.

**Como os modelos poderiam se estruturar na plataforma:** um documento gerado = um "modelo" (texto com marcadores) + um conjunto de "valores" preenchidos para aquele cliente/mentorado específico, mais um registro de versão/status. Isso mapeia bem em 3 tabelas novas: `rg_modelos_documento` (tipo, nome, corpo do texto com marcadores, versão, responsável, data), `rg_documentos_gerados` (modelo usado, cliente_id/mentorado_id, valores preenchidos em JSON, status, arquivo PDF final, histórico de envio/assinatura) e, para o contrato de consultoria, `rg_documento_itens` para as linhas do Anexo I (serviço, entregável, prazo, valor).

**Campos variáveis identificados nos 2 modelos fornecidos:**

| Campo no contrato | Existe hoje em rg_clientes/rg_mentorados? |
|---|---|
| Nome completo, CPF, RG, órgão expedidor, naturalidade | Não existe |
| Endereço completo (rua, número, bairro, complemento, cidade, UF, CEP) | Não existe |
| CNPJ, razão social, nome fantasia (contrato de consultoria) | Não existe — CNPJ confirmado ausente por busca no código |
| E-mail e WhatsApp separados | Parcial — hoje é um único campo "contato" genérico em ambas as tabelas |
| Valor, forma de pagamento, parcelas, datas de vencimento | Parcial — `valor_mensal` existe em clientes; nada equivalente para mentorados nem para parcelamento |
| Data de início / duração / data de encerramento | Existe — `duracao_meses`/`inicio` em rg_clientes |
| Serviços do Anexo I (elaboração de cardápio, teste de cardápio, ficha técnica, etc.) com prazos e valores | Não existe — precisa de tabela nova |

**Dependências técnicas:**
- **Edição de texto rico com marcadores** — nenhum editor desse tipo existe hoje no projeto.
- **Geração de PDF** — dependência zero hoje. Precisa de uma decisão: biblioteca client-side (jsPDF/pdfmake, sem custo de servidor) ou função serverless com navegador headless (mais fiel, mas exige um componente de backend que hoje não existe).
- **Armazenamento do arquivo final** — um contrato em PDF facilmente ultrapassa 1,5 MB; o padrão atual de "base64 em coluna de texto" não é viável. Provavelmente força a adoção de Supabase Storage.
- **Versionamento** — precisa de regra explícita de "documento finalizado é imutável; qualquer alteração cria nova versão".

### 2.6 Projetos e Tarefas

| Requisito | Status | Evidência | Nota |
|---|---|---|---|
| Cadastro completo (projeto, tarefa, responsável, prazo, filtros, anexos) | `[Funcionando]` | app.html:1174-1242 | — |
| "Equipe" vê todas as tarefas de todos (deveria ver só as suas por padrão) | `[Com problema]` | app.html:1186-1192 | Confirmado: filtro de responsável é manual (dropdown), não há padrão "minhas tarefas" nem campo de visibilidade restrita por tarefa. |
| Status clicável pouco intuitivo; concluídas deveriam sair para área própria | `[Com problema]` | app.html:1197-1198,1250-1252 | Um único botão alterna 3 estados em ciclo; não existe área separada, só um filtro sobre a mesma lista. |
| Filtro exclusivo para "Fazendo" | `[Com problema]` | app.html:1179,1186 | Confirmado: "Abertas" hoje junta aberta+fazendo. |
| Filtro de prazo personalizado | `[Com problema]` | app.html:1177,1189-1192 | Só opções fixas (7d/30d/sem prazo/qualquer). |
| Limite de 1,5 MB em anexos | `[Confirmado — limite existe]` | app.html:1297 | Ver causa raiz no tópico 24. |
| Permissão de visualização por pessoa em cada documento | `[Não implementado]` | setup-supabase.sql:218-225 | Tabela de documentos não tem nenhuma coluna de controle de acesso. |

### 2.7 Processos

| Requisito | Status | Evidência | Nota |
|---|---|---|---|
| Áreas fixas; cliente quer poder criar novas áreas | `[Com problema]` | app.html:2446 | Lista de 7 áreas hardcoded; diferente de outros campos do sistema, este nem tem a opção "outro" de texto livre. |
| Formatos: quadro visual, fluxo, kanban, mapa mental, texto, imagem | `[Funcionando]` | app.html:2448,2519-2639 | Todos os 6 formatos existem e funcionam. |
| Limite de 1,5 MB para imagens/arquivos | `[Confirmado — limite existe]` | app.html:2658 | Ver tópico 24. |
| Exportação em PDF/PNG (individual e por área) | `[Não implementado]` | — | Nenhuma lib de exportação em todo o projeto. |
| Transformar processo em checklist reutilizável de onboarding | `[Não implementado]` | — | A tabela de etapas de onboarding (`rg_etapas`) é um modelo fixo hardcoded, sem ligação com a tabela de processos. |

### 2.8 Comunicação Interna

`[Não implementado]` — busca por "chat", "mensagem" e "comunicação" em todo o `app.html` não encontra nenhum vestígio de funcionalidade real (o único resultado é um texto de exemplo dentro dos dados de demonstração). Módulo inteiramente novo.

### 2.9 Responsividade Mobile

| Requisito | Status | Evidência | Nota |
|---|---|---|---|
| Botão Sair acessível no celular | `[Com problema]` | app.html:40,46,56,276-280 | Causa raiz identificada: a barra lateral usa `height:100vh`, e em navegadores móveis o `100vh` inclui a área escondida atrás da barra de endereço dinâmica — só a lista de menu tem rolagem própria; o bloco de usuário/Sair, por ser o último item da coluna, pode ficar renderizado abaixo da área visível sem nenhum jeito de rolar até ele. |
| Responsividade geral de tabelas/dashboards | `[Parcial]` | app.html:275-296 | Só 3 breakpoints no projeto inteiro, aplicados via classes utilitárias compartilhadas — cobertura sistêmica, mas rasa. |

### 2.10 Perfil e Login do Usuário

`[Não implementado]` — não existe nenhuma tela pós-login para editar nome, foto, senha ou dados da conta. app.html:2884-2886 só exibe (não edita) nome/papel/avatar; busca por "senha" no arquivo inteiro não retorna nenhum uso real.

### 2.11 Links Úteis

`[Funcionando]` — cadastro, restrição a admin/pessoas específicas e abertura direta confirmados em app.html:1308-1345. A lista exibida já passa por um filtro real de permissão antes de renderizar (não é uma restrição só "de fachada").

### 2.12 Agenda

| Requisito | Status | Evidência | Nota |
|---|---|---|---|
| Google Agenda permanece conectado | `[Com problema — prioridade]` | app.html:1348 | Token de acesso vive só numa variável JavaScript (`gToken`), nunca salvo — some a cada recarregamento de página. Explica exatamente o comportamento relatado. |
| Filtros diário/semanal/mensal/anual/personalizado | `[Não implementado]` | app.html:1436,1494,1497 | Lista fixa dos próximos 14 itens, sem seletor. |
| Tipos de compromisso personalizáveis | `[Não implementado]` | app.html:1468-1469,1502 | Lista fixa de 4 tipos (reunião/sessão/prazo/outro). |
| Aniversários/datas: filtro e clique | `[Não implementado]` | app.html:1455-1459 | Janela fixa de 60 dias, itens não clicáveis. |
| Calendário de datas comerciais/gastronômicas completo | `[Parcial]` | app.html:1389-1414,1461-1466 | Existem 24 datas gastronômicas cadastradas, mas faltam Dia das Mães/Avós/Pais e feriados nacionais; janela fixa de 90 dias, sem visão anual, itens não clicáveis. |

### 2.13 Equipe e Permissões

| Requisito | Status | Evidência | Nota |
|---|---|---|---|
| Cadastro completo do membro | `[Funcionando]` | app.html:1546-1555 | Todos os campos citados existem. |
| Aniversário integrado à agenda | `[Funcionando]` | app.html:1450,1455 | — |
| Permissão granular por seção (CRM, Clientes, etc.) | `[Não implementado]` | setup-supabase.sql:7-14 | Confirmado: só existe o binário admin/equipe no banco inteiro; granularidade só existe hoje em Links e Processos. |
| Admin aprova novos acessos | `[Funcionando]` | app.html:1538,1563 | — |
| Status do membro (Ativo/Férias/Licença/Desligado) | `[Não implementado]` | setup-supabase.sql:284-290 | Coluna não existe; hoje só há cadastro ou exclusão definitiva. |

### 2.14 Clientes de Consultoria

Maior módulo do sistema. A base (dashboard, abas, Drive, timeline básica) funciona; os itens ausentes concentram-se em exportação, relatórios estruturados e isolamento de processos por cliente.

| Requisito | Status | Evidência | Nota |
|---|---|---|---|
| Dashboard com abas (tarefas, plano, indicadores, timeline, ferramentas, visitas, docs, Drive) | `[Funcionando]` | app.html:1667-1669 | — |
| Botão de retorno à lista de clientes | `[Não implementado]` | app.html:1666-1667 | Padrão pronto para copiar já existe em Cursos (`#cu-back`, linha 2280) e Processos (`#pr-back`, linha 2619). |
| Geração de PDF das informações do cliente | `[Não implementado]` | — | — |
| Filtro de indicadores personalizado (hoje 3/6/12m/tudo) | `[Parcial]` | app.html:1720 | Confirmado, sem período customizado. |
| Indicadores de engenharia de cardápio, desperdício, quebra, inventário, setorização | `[Não implementado]` | app.html:1719,1602-1608 | Dashboard mostra só faturamento/CMV/ticket/resultado. As ferramentas do PEC existem como abas de iframe isoladas — nenhum dado delas é lido de volta para o dashboard. |
| Análise automática dos indicadores via IA | `[Não implementado]` | — | Zero integração de IA no projeto inteiro. |
| Seção de Relatórios (1º mês, 2º mês, encerramento, com gráficos no corpo) | `[Não implementado]` | app.html:1669 | Só existe "Relatório de visita". |
| Upload de arquivo de ferramenta personalizada na aba Ferramentas | `[Parcial]` | app.html:1759-1774 | Aba só lista ferramentas fixas via iframe; upload só existe na aba Documentos, genérica. |
| Processos isolados por cliente (sem misturar com outros clientes/empresa) | `[Não implementado]` | setup-supabase.sql:209-216 | Achado crítico: a tabela `rg_processos` não tem coluna `cliente_id` — é uma tabela única e global, sem isolamento nenhum, não uma implementação parcial. |
| Timeline: travada em "Agora", clique abre edição em vez de resumo | `[Com problema]` | app.html:1828-1853 | Confirmado exatamente como relatado. |
| Relatório de visita: acompanhante + horário início/fim | `[Parcial]` | app.html:1872-1878 | Campos atuais confirmados; os dois novos campos não existem. |
| Assinatura digital por toque no relatório | `[Não implementado]` | — | — |
| Logo do cliente | `[Não implementado]` | setup-supabase.sql:96-106 | Nenhum campo de imagem no cadastro. |
| Drive do cliente | `[Funcionando]` | app.html:1667,1676,1931 | — |
| Restringir visibilidade de documentos por pessoa | `[Não implementado]` | setup-supabase.sql:218-225 | Tabela sem coluna de acesso, diferente de Links/Processos que já têm. |
| Checklists de análise (RDC 256 etc.) | `[Não implementado]` | — | — |
| Cadastro: e-mail/WhatsApp separados, CNPJ | `[Com problema]` | app.html:1582-1596 | Confirmado campo "contato" único; CNPJ ausente. |
| "Serviço contratado → Personalizada" editável livremente | `[Com problema]` | app.html:1585 | Select sem opção de texto livre. |

### 2.15 Mentorados

| Requisito | Status | Evidência | Nota |
|---|---|---|---|
| Cadastro (contato único, tipo, encontros, status) | `[Funcionando]` | app.html:2052-2059 | Mesmo problema de contato único do cadastro de clientes. |
| "Plano de ação" → "Tarefas", integrado à seção geral | `[Não implementado]` | app.html:2093 | Confirmado: `rg_plano_itens` é tabela totalmente separada de `rg_tarefas`, sem nenhuma sincronização. |
| Área de arquivos/links do mentorado | `[Não implementado]` | setup-supabase.sql:218-225 | Achado importante: a tabela de documentos nem tem coluna `mentorado_id` — não há onde salvar. |
| Processos isolados do mentorado | `[Não implementado]` | setup-supabase.sql:209-216 | Mesmo achado do tópico Clientes — tabela sem isolamento nenhum. |
| Relatórios do mentorado | `[Não implementado]` | app.html:2066-2117 | — |
| Botão de retorno à lista de mentorados | `[Não implementado]` | app.html:2075-2076 | Mesmo padrão de Cursos pode ser reaproveitado. |

### 2.16 Cursos

`[Funcionando]` — cadastro, atividades, materiais/documentos e botão de retorno (app.html:2280,2309) todos confirmados. Este módulo é a referência de padrão de navegação a ser replicada em Clientes e Mentorados.

### 2.17 Marketing e Conteúdo

`[Não implementado]` — módulo inteiro ausente. Busca por "marketing", "editorial", "instagram", "youtube", "vturb", "tráfego" e "campanha" no `app.html` só retorna falsos positivos (o Kanban existente é do CRM/Processos; "marketing" e "tráfego" existem apenas como nome de categoria de despesa financeira). É o maior módulo greenfield do roadmap.

### 2.18 Certificados de Alunos

| Requisito | Status | Evidência | Nota |
|---|---|---|---|
| Status e cadastro do aluno | `[Funcionando]` | app.html:2134-2149,2187-2192 | Contato ainda é campo único, mesmo padrão dos outros módulos. |
| Sequência de etapas clicáveis (você confirma que funciona bem) | `[Funcionando]` | app.html:2199-2220 | Confirmado, não precisa mudar. |
| Blocos de status no topo parecem clicáveis mas não fazem nada | `[Com problema]` | app.html:2146-2149 | Confirmado: nenhum `onclick` nesses blocos; só os botões de filtro acima funcionam. |

### 2.19 Vendas e Alunos (importação Hotmart)

Seção com mais bugs confirmados e a de maior prioridade — os defeitos de importação afetam diretamente o Financeiro.

| Requisito | Status | Evidência | Nota |
|---|---|---|---|
| Ticket médio por aluno único (hoje por venda) | `[Com problema]` | app.html:2379 | Confirmado: divide pelo número de vendas aprovadas, não pelo número de e-mails únicos (já calculado ao lado, mas não usado aqui). |
| Importação não traz todas as 1000+ linhas do CSV | `[Com problema — causa raiz identificada]` | app.html:2413-2427,388 | Não há filtro de data nem limite de linhas no código. O contador de "novas vendas" incrementa mesmo quando um insert falha, e cada linha é inserida uma de cada vez — um erro no meio do arquivo pode travar a importação num `alert()` bloqueante por linha, dando a impressão de que só um recorte pequeno foi processado. |
| "154 registros ignorados" mas só 27 aparecem no painel | `[Com problema — causa raiz mais provável]` | app.html:2367,2424 | A comparação de status usa `=== 'Aprovado'` — sem `.trim()`, sensível a maiúsculas/minúsculas. Se o texto do CSV variar, a linha é gravada mas nunca aparece nos indicadores. Não confirmado 100% sem o CSV real. |
| Limite de linhas por importação | `[Não existe — confirmado]` | app.html:2332-2350,2413 | Sem limite algum no código. |
| Excluir/desfazer uma importação | `[Não implementado]` | setup-supabase.sql:275-282 | Tabela de vendas não agrupa registros por lote de importação. |
| Filtro por período (mensal/intervalo/personalizado) | `[Não implementado]` | app.html:2381-2384 | Só filtro de status e produto. |
| Filtro por produto atualiza os cards do topo | `[Com problema]` | app.html:2366-2379,2387 | Confirmado: os 4 cards do topo ignoram o filtro de produto; só a tabela de baixo reflete. |
| Status de venda gerenciável (Reembolso/Cancelado) abatendo faturamento | `[Parcial]` | app.html:2390 | Campo aceita texto livre com estilo pronto, mas sem tela para alterar status manualmente nem lógica de abatimento explícita. |
| Botão WhatsApp a partir do telefone importado | `[Não implementado]` | app.html:2390 | Telefone é só texto, sem link. |

### 2.20 Padronização dos botões de retorno

`[Com problema — padrão já existe, só falta replicar]`. Cursos já usa exatamente o padrão certo: `<button class="btn btn-o btn-sm" id="cu-back">← Cursos</button>` com `onclick` chamando `go('cursos')` (app.html:2280,2309; o mesmo padrão também já existe em Processos, `#pr-back`, linha 2619). Replicar em Clientes e Mentorados é uma alteração pequena e de baixo risco.

### 2.21 Filtros personalizados

`[Não existe um componente reutilizável]` de filtro de período — cada módulo reinventa seu próprio filtro, mais simples. Padronizar exige construir um componente único de período e substituir todas as implementações atuais — é um trabalho transversal, não um ajuste pequeno em cada tela isoladamente.

### 2.22 Permissões e proteção das informações

`[Confirmado pelo schema]` — setup-supabase.sql:173-189,316-332 mostra que toda a segurança do banco é feita em blocos que aplicam uma única política por tabela inteira. Não existe nenhuma coluna do tipo `owner_id` ou `visible_to` em nenhuma tabela. Implementar permissão granular exige (a) schema novo de permissões, (b) políticas de RLS novas por tabela, e (c) interface nova em cada módulo — é uma mudança arquitetural, não um recurso pequeno.

### 2.23 Relatórios e exportação em PDF

`[Não implementado em lugar nenhum]` — confirmado por busca no arquivo inteiro por "pdf", sem nenhuma ocorrência de biblioteca ou geração. Como o projeto não tem backend próprio além do Supabase, viabilizar isso é uma decisão arquitetural real.

### 2.24 Limites de arquivos e imagens

`[Causa raiz identificada]` — os limites (1,5 MB em documentos/processos, 400 KB e máx. 6 fotos em relatório de visita — app.html:1297,2658,1894-1895) existem porque todo arquivo é convertido em texto base64 e gravado direto numa coluna do Postgres; não há nenhum uso de Supabase Storage no projeto. Aumentar os limites de forma relevante não é um ajuste de configuração — é a adoção de um mecanismo de armazenamento de arquivo diferente do que existe hoje.

---

## 3. Matriz de impacto técnico

Para cada tópico, os tipos de trabalho técnico envolvidos:

| Tópico | Impacto técnico |
|---|---|
| 1. Visão Geral | Interface · Regra de negócio · Desempenho |
| 2. Financeiro | UX · Regra de negócio |
| 3. Metas | Regra de negócio · Interface |
| 4. CRM | Banco de dados · Regra de negócio |
| 5. Propostas e Contratos | Banco de dados · Geração de PDF · Regra de negócio · Permissões · Segurança/dados |
| 6. Projetos e Tarefas | Permissões · Regra de negócio · UX |
| 7. Processos | Banco de dados · Geração de PDF · Regra de negócio |
| 8. Comunicação Interna | Banco de dados · Interface · Desempenho (tempo real) |
| 9. Responsividade Mobile | Interface · UX |
| 10. Perfil e Login | Autenticação · Interface |
| 11. Links Úteis | — nenhum pendente |
| 12. Agenda | Integração externa · Autenticação · UX |
| 13. Equipe e Permissões | Banco de dados · Permissões · Autenticação |
| 14. Clientes de Consultoria | Banco de dados · Geração de PDF · Permissões · UX · Regra de negócio |
| 15. Mentorados | Banco de dados · Regra de negócio · UX |
| 16. Cursos | — nenhum pendente |
| 17. Marketing e Conteúdo | Banco de dados · Integração externa · Importação de arquivos · Interface · Regra de negócio |
| 18. Certificados | Interface |
| 19. Vendas e Alunos | Importação de arquivos · Regra de negócio · Banco de dados · Desempenho |
| 20. Botões de retorno | Interface · UX |
| 21. Filtros personalizados | Interface · Regra de negócio |
| 22. Permissões granulares | Banco de dados · Permissões · Segurança/dados |
| 23. Relatórios e PDF | Geração de PDF · Regra de negócio |
| 24. Limites de arquivo | Banco de dados · Importação de arquivos · Desempenho |

---

## 4. Principais riscos

**[Alto]** — Este backup conecta a dados reais de produção
`config.js` tem credenciais reais preenchidas; qualquer teste feito abrindo esta pasta local ou publicando-a grava direto no banco ao vivo. Recomendo, antes de qualquer teste manual, apontar temporariamente para um projeto Supabase separado ou esvaziar `config.js` para cair em modo demonstração.

**[Alto]** — Correções na importação da Hotmart tocam o Financeiro automaticamente
Toda venda aprovada gera um lançamento em `rg_financeiro` (app.html:2438). Qualquer ajuste na regra de "o que conta como aprovado" precisa de um plano explícito para o histórico já importado — senão o Financeiro e as Metas passam a ter números inconsistentes com o passado.

**[Alto]** — `rg_processos` é uma tabela global sem isolamento
Processos de clientes, mentorados e da empresa moram todos na mesma tabela sem chave de isolamento. Adicionar isolamento é uma migração de dados, não só de schema — risco real de misturar ou perder a categorização atual se feito sem cuidado.

**[Médio]** — Nenhum uso de Supabase Storage — aumentar limites de arquivo é maior do que parece
Migrar de "base64 na coluna" para arquivos reais em Storage afeta pelo menos 4 tabelas, e registros antigos precisam continuar sendo lidos corretamente durante e depois da transição.

**[Médio]** — Permissões granulares mexem em todas as políticas de RLS
Criar granularidade por seção implica reescrever as políticas de praticamente todas as 24 tabelas; um erro pode bloquear acesso legítimo ou expor dado sensível (financeiro, salários).

**[Médio]** — Google Agenda: qualquer correção de persistência de token é uma decisão arquitetural
O projeto não tem backend próprio hoje. Persistir o token com segurança normalmente pede um componente de servidor, ainda que mínimo.

**[Médio]** — Duplicação de dados entre "Plano de ação" e "Tarefas"
`rg_plano_itens` (mentorados) e `rg_tarefas` (geral) são tabelas distintas guardando conceitualmente a mesma coisa. Unificar precisa de decisão clara sobre migração ou sincronização.

**[Baixo]** — Certificados, Cursos e Links Úteis estão estáveis
Esses três módulos não apresentam bugs confirmados — qualquer trabalho neles deve ser tratado como baixo risco e não priorizado.

**[Baixo]** — A pasta docs/ pode induzir decisões erradas se for consultada como referência técnica
Descreve uma arquitetura que não existe. Se usada como guia de implementação, o caminho natural leva a uma reescrita, não a uma evolução incremental.

---

## 5. Plano de implementação por etapas

A ordem que você propôs foi avaliada etapa a etapa contra as dependências reais do código. No geral, **a sequência respeita a arquitetura** — os pontos abaixo são ajustes de composição a considerar, não uma reordenação. Nenhuma etapa foi encolhida, ampliada ou reinterpretada sem essa marcação explícita.

### Etapa 1 — Importação da Hotmart e consistência dos dados
- **Objetivo:** Corrigir a importação de CSV para que reflita fielmente o volume real de vendas, sem duplicar nem perder faturamento.
- **Requisitos contemplados:** Tópico 19 (Vendas e Alunos): ticket médio, importação incompleta, descompasso de duplicados, exclusão de importação, filtros, status de venda, WhatsApp.
- **Arquivos/áreas afetados:** app.html:2331-2445 (seção Vendas), possivelmente setup-supabase.sql se for necessário um campo de lote de importação.
- **Alterações no banco:** Provável: normalizar/validar o campo `status`; possível campo novo para agrupar uma importação (permitir desfazer em lote).
- **Riscos:** Alto — toda venda aprovada já lança no Financeiro automaticamente; mudar a regra de "aprovado" exige decidir o que fazer com o histórico já importado.
- **Dependências:** Nenhuma dependência de outra etapa. Bloqueia indiretamente a Etapa 5 (Financeiro/Metas), que herda esses números.
- **Como testar:** Reimportar o CSV real (ou uma amostra) que gerou o problema relatado e comparar contagem de linhas do arquivo × vendas gravadas × vendas exibidas.
- **Critério de conclusão:** 100% das linhas válidas do CSV aparecem no sistema; reimportar o mesmo arquivo não duplica nem descarta silenciosamente; é possível excluir uma importação errada.

### Etapa 2 — Projetos, tarefas e status
- **Objetivo:** Visibilidade correta de tarefas por padrão, status mais claro, filtros completos.
- **Requisitos contemplados:** Tópico 6 inteiro (Projetos e Tarefas).
- **Arquivos/áreas afetados:** app.html:1146-1307.
- **Alterações no banco:** Campo de visibilidade/responsáveis extras em `rg_tarefas`, se a granularidade "admin escolhe quem mais vê" for implementada aqui.
- **Riscos:** Baixo–médio — mudar o padrão de visibilidade pode "sumir" tarefas que a equipe está acostumada a ver todas; vale comunicar a mudança.
- **Dependências:** A tabela `rg_tarefas` também é o destino da integração "Plano de ação → Tarefas" do módulo Mentorados (etapa 6). Recomendo decidir aqui o desenho de schema que já acomode essa integração futura.
- **Como testar:** Login como "equipe" com tarefas de terceiros e conferir que só as próprias aparecem por padrão; admin consegue liberar visibilidade cruzada.
- **Critério de conclusão:** Filtro "Fazendo" existe; período personalizado de prazo funciona; visibilidade padrão é por responsável; concluídas saem da lista ativa.

### Etapa 3 — Equipe, permissões e acessos
- **Objetivo:** Criar a base de permissões granulares por seção e os novos status de membro da equipe.
- **Requisitos contemplados:** Tópico 13 (Equipe) e a base técnica do Tópico 22 (Permissões).
- **Arquivos/áreas afetados:** app.html:1520-1568, setup-supabase.sql (novo schema de permissão), políticas de RLS de praticamente todas as tabelas.
- **Alterações no banco:** Nova tabela/coluna de permissão por seção e por usuário; coluna `status` em `rg_equipe`; novas políticas de RLS.
- **Riscos:** Médio–alto — é a etapa que mais mexe em segurança de dados; um erro de RLS pode bloquear acesso legítimo ou expor dado sensível.
- **Dependências:** Recomendo desenhar aqui um mecanismo genérico e extensível de permissão, porque módulos futuros (Marketing, Propostas) também vão precisar de controle de acesso — refazer esse desenho depois seria retrabalho em cascata.
- **Como testar:** Criar um usuário "equipe" de teste e confirmar, seção por seção, que só enxerga o que o admin liberou — inclusive tentando acessar pela URL/console.
- **Critério de conclusão:** Admin consegue configurar, por pessoa, quais seções ela acessa; status Férias/Licença/Desligado bloqueia acesso; nenhuma tabela sensível fica acessível fora da regra definida.

### Etapa 4 — Agenda e integração com o Google Agenda
- **Objetivo:** Conexão persistente com o Google Agenda e filtros de visualização completos.
- **Requisitos contemplados:** Tópico 12 inteiro.
- **Arquivos/áreas afetados:** app.html:1347-1520.
- **Alterações no banco:** Nenhuma prevista, a menos que se opte por guardar o token do lado do servidor.
- **Riscos:** Médio — a forma "correta" de persistir o token (com renovação automática) normalmente exige um pequeno componente de servidor que hoje não existe no projeto.
- **Dependências:** Nenhuma com outras etapas.
- **Como testar:** Conectar, fechar o navegador, reabrir no dia seguinte e confirmar que a conexão persiste sem precisar reconectar.
- **Critério de conclusão:** Conexão sobrevive a recarregamentos e reaberturas; filtros diário/semanal/mensal/anual/personalizado funcionam; calendário comercial completo e clicável.

### Etapa 5 — Financeiro, Metas e Visão Geral
- **Objetivo:** Corrigir filtros e visualizações do núcleo financeiro, incluindo o dashboard executivo.
- **Requisitos contemplados:** Tópicos 1, 2 e 3 inteiros.
- **Arquivos/áreas afetados:** app.html:623-1007.
- **Alterações no banco:** Possível: categoria de despesa padronizada para bater com a lista pedida; campos para "novos contratos"/"novos alunos" se viraram metas oficiais.
- **Riscos:** Baixo–médio — mexe em cálculos que a equipe já usa para decisão; validar os números antes/depois com um período conhecido.
- **Dependências:** Depende da Etapa 1 (Hotmart) já estar corrigida, porque Vendas alimenta o Financeiro automaticamente.
- **Como testar:** Comparar os números da Visão Geral com uma apuração manual do mesmo período.
- **Critério de conclusão:** Metas detalhadas por categoria; gráfico misto de receita×despesa sempre visível; ticket médio por aluno correto na Visão Geral; botão "Abrir metas" corrigido.

### Etapa 6 — Clientes de consultoria, mentorados e relatórios
- **Objetivo:** Fechar as lacunas dos dois maiores módulos de atendimento e introduzir a primeira capacidade de relatório/PDF do sistema.
- **Requisitos contemplados:** Tópicos 14, 15 e a parte de exportação em PDF do Tópico 23 aplicada a esses dois módulos.
- **Arquivos/áreas afetados:** app.html:1568-2119; nova biblioteca/serviço de PDF a ser adicionada ao projeto.
- **Alterações no banco:** Isolamento de `rg_processos` por cliente/mentorado (migração de dados); coluna `mentorado_id` em `rg_documentos`; novo campo de logo do cliente; separação e-mail/WhatsApp; CNPJ; nova tabela de Relatórios.
- **Riscos:** Alto — a migração de `rg_processos` para isolar por cliente mexe em dados já cadastrados; planejar a reclassificação com cuidado antes de rodar em produção.
- **Dependências:** Como este é o primeiro módulo do roadmap a gerar PDF, recomendo tratar a "capacidade de gerar PDF" como um serviço reutilizável construído aqui — a Etapa 7 (Propostas e Contratos) precisa da mesma capacidade logo em seguida.
- **Como testar:** Gerar um PDF de cliente e de relatório de visita e conferir visualmente cabeçalho, logo, dados e paginação; confirmar que processos de um cliente não aparecem para outro.
- **Critério de conclusão:** Botão de retorno em ambos os módulos; processos isolados por cliente/mentorado; "Plano de ação" renomeado e sincronizado com Tarefas; PDF de cliente e de relatório de visita funcionando.

### Etapa 7 — Propostas, contratos e documentos comerciais
- **Objetivo:** Construir o novo módulo de modelos/documentos a partir dos dois contratos fornecidos como referência estrutural.
- **Requisitos contemplados:** Tópico 5 inteiro.
- **Arquivos/áreas afetados:** Módulo novo dentro de app.html; reaproveita o serviço de PDF da Etapa 6.
- **Alterações no banco:** Tabelas novas: modelos de documento, documentos gerados, itens do Anexo I; campos novos em rg_clientes/rg_mentorados (CPF, RG, órgão expedidor, naturalidade, endereço completo, razão social, nome fantasia, CNPJ em clientes).
- **Riscos:** Alto — envolve dados pessoais sensíveis (CPF/RG) de clientes e mentorados; a decisão de armazenamento de arquivo (ver dúvidas) precisa estar fechada antes de começar.
- **Dependências:** Depende diretamente da Etapa 6 (capacidade de PDF) e de decisão prévia sobre Supabase Storage. Os dois modelos fornecidos são só referência estrutural — nenhuma cláusula jurídica é alterada.
- **Como testar:** Gerar um contrato de teste ponta a ponta (criar → preencher → prévia → finalizar → PDF) e comparar visualmente com os modelos originais fornecidos.
- **Critério de conclusão:** Os dois modelos fornecidos estão cadastrados como modelos iniciais; um documento pode ser gerado, revisado, finalizado e baixado em PDF vinculado a um cliente/mentorado; documento finalizado não é alterado por mudanças posteriores no modelo.

### Etapa 8 — Checklists e integração com processos
- **Objetivo:** Permitir que um processo gere um checklist reutilizável de onboarding.
- **Requisitos contemplados:** Parte do Tópico 7 (checklists) e do Tópico 14 (checklists de análise do cliente).
- **Arquivos/áreas afetados:** app.html:2445-2693 (Processos); tabela `rg_etapas`, hoje um modelo fixo.
- **Alterações no banco:** Vínculo entre `rg_processos` e uma nova estrutura de checklist reutilizável.
- **Riscos:** Baixo — módulo aditivo, não altera dado existente.
- **Dependências:** Depende do isolamento de processos por cliente (Etapa 6) já estar pronto.
- **Como testar:** Marcar um processo como gerador de checklist, cadastrar um cliente novo e confirmar que o checklist aparece automaticamente.
- **Critério de conclusão:** Um processo pode virar checklist; novo cliente/mentorado/curso recebe o checklist correspondente automaticamente.

### Etapa 9 — Comunicação interna
- **Objetivo:** Chat interno entre membros da equipe.
- **Requisitos contemplados:** Tópico 8 inteiro.
- **Arquivos/áreas afetados:** Módulo novo dentro de app.html; nova tabela de mensagens.
- **Alterações no banco:** Tabela nova de mensagens + política de RLS restringindo cada conversa aos participantes.
- **Riscos:** Baixo — módulo isolado, sem dependência de dado existente. Atenção a desempenho se o Supabase Realtime for usado.
- **Dependências:** Nenhuma.
- **Como testar:** Duas contas de teste trocando mensagem e conferindo o indicador de não lida.
- **Critério de conclusão:** Mensagem direta entre dois membros funciona; indicador visual de mensagem nova aparece na barra lateral.

### Etapa 10 — Perfil e configurações do usuário
- **Objetivo:** Tela de edição de perfil dentro do painel.
- **Requisitos contemplados:** Tópico 10 inteiro.
- **Arquivos/áreas afetados:** Nova tela dentro de app.html, usando a API de auth do Supabase já presente.
- **Alterações no banco:** Coluna de foto de perfil em `profiles` (ou reaproveitar armazenamento definido na Etapa 7).
- **Riscos:** Baixo.
- **Dependências:** Nenhuma bloqueante — candidata a "vitória rápida".
- **Como testar:** Trocar nome, foto e senha e confirmar refletido na barra lateral e no próximo login.
- **Critério de conclusão:** Usuário consegue alterar nome, foto e senha sem depender de um admin.

### Etapa 11 — Marketing e Conteúdo — parte operacional
- **Objetivo:** Construir a base do novo módulo: perfis de conteúdo, calendário editorial, kanban de produção, banco de ideias, referências e biblioteca.
- **Requisitos contemplados:** Parte operacional do Tópico 17.
- **Arquivos/áreas afetados:** Módulo inteiramente novo — reaproveita só o padrão visual e a camada de dados genérica (DB.list/insert/update/remove).
- **Alterações no banco:** Tabelas novas: perfis, conteúdos, ideias, referências, pilares editoriais.
- **Riscos:** Baixo quanto a dado existente (tudo novo); alto em volume de trabalho — é o maior módulo greenfield do roadmap.
- **Dependências:** Se a permissão granular por seção (Etapa 3) já estiver pronta como mecanismo genérico, este módulo só precisa configurar novas seções nela, sem retrabalho.
- **Como testar:** Cadastrar um conteúdo do início ao fim (ideia → produção → publicado) e conferir que aparece no calendário e na biblioteca.
- **Critério de conclusão:** Calendário, kanban de produção, banco de ideias e biblioteca funcionando para pelo menos um perfil de conteúdo.

### Etapa 12 — Marketing e Conteúdo — analytics e campanhas
- **Objetivo:** Indicadores de Instagram/YouTube/tráfego pago/VTurb e gestão de campanhas.
- **Requisitos contemplados:** Parte de analytics/campanhas do Tópico 17.
- **Arquivos/áreas afetados:** Extensão do módulo criado na Etapa 11.
- **Alterações no banco:** Tabelas de campanhas, métricas importadas, central de uploads.
- **Riscos:** Baixo — o próprio documento de análise já prevê que, sem integração automática, os dados entram por importação de planilha.
- **Dependências:** Depende da Etapa 11 (estrutura de conteúdo/perfis) já existir.
- **Como testar:** Importar uma planilha de exemplo de cada fonte e conferir que os indicadores aparecem corretamente.
- **Critério de conclusão:** Central de uploads recebe planilhas/relatórios; analytics de cada canal e o funil de tráfego exibem os dados importados; campanhas cadastráveis e vinculáveis a conteúdos.

### Etapa 13 — Revisão global de UX, navegabilidade e responsividade
- **Objetivo:** Padronizar o que ficou disperso durante as etapas anteriores: botões de retorno, filtros personalizados, responsividade.
- **Requisitos contemplados:** Tópicos 9, 20 e 21 (o que não tiver sido resolvido pontualmente nas etapas anteriores).
- **Arquivos/áreas afetados:** Transversal a todo app.html.
- **Alterações no banco:** Nenhuma.
- **Riscos:** Baixo — mudanças majoritariamente de CSS/interface, mas tocam todas as telas.
- **Dependências:** Faz sentido como última etapa formal — ver ressalva abaixo.
- **Como testar:** Percorrer todas as telas em celular real conferindo rolagem e acesso ao botão Sair.
- **Critério de conclusão:** Filtro de período personalizado padronizado nas seções listadas no documento de análise; todo módulo interno tem botão de retorno; barra lateral utilizável do início ao fim em celular.

> **Observação sobre a ordem:** a sequência proposta respeita as dependências reais do código. Os únicos ajustes que sugiro considerar — sem alterar o que cada etapa entrega — são: (1) o bug de rolagem da barra lateral no celular e o botão "Abrir metas" têm causa raiz já identificada e conserto de baixíssimo risco; poderiam entrar como um pacote pequeno já na Etapa 1, em vez de esperar a Etapa 13, já que você mesma classificou a responsividade mobile como prioridade urgente. (2) A Etapa 10 (Perfil) não depende de nada e é pequena — é candidata a "vitória rápida" se quiser intercalar algo simples entre etapas maiores. Qualquer uma dessas mudanças de composição só deve acontecer com sua aprovação explícita.

---

## 6. Dúvidas e pendências

Tudo abaixo precisa da sua decisão antes da implementação correspondente — nenhuma foi respondida por conta própria.

1. **Armazenamento de arquivo — base64 ou Supabase Storage?** Afeta diretamente os limites de arquivo (tópico 24), documentos, relatórios com foto e, principalmente, Propostas e Contratos (etapa 7), que dificilmente cabe no modelo atual. É a decisão técnica de maior efeito cascata em todo o plano.
2. **Geração de PDF — biblioteca no navegador ou serviço de servidor?** Impacta fidelidade visual, custo de manutenção e se o projeto passa a precisar de um componente de backend próprio, que hoje não existe.
3. **Quais campos novos entram no cadastro de cliente/mentorado para os contratos?** CPF, RG, órgão expedidor, naturalidade, endereço completo, razão social, nome fantasia, CNPJ (cliente) — confirmar a lista definitiva e se são obrigatórios no cadastro ou preenchíveis só na hora de gerar o documento.
4. **O valor do contrato de mentoria (R$ 3.500,00, 6 encontros) deve virar 100% variável?** Hoje está fixo no modelo fornecido.
5. **Qual é a menor unidade de permissão que faz sentido (módulo inteiro? aba dentro do módulo?)** Define o desenho do schema de permissões da Etapa 3.
6. **É possível reenviar o CSV real (ou uma amostra anonimizada) da importação com problema?** Confirmaria com certeza a causa antes de programar a correção da Etapa 1.
7. **Google Agenda: aceitar reconexão por sessão, ou investir num pequeno backend para token persistente?**
8. **Áreas de Processos: lista sugerida com opção "outra", ou totalmente livre?**
9. **Lista definitiva de status de venda e regra de abatimento no faturamento líquido.**
10. **Um admin pode revogar/rebaixar outro admin? O que acontece se a única conta admin sair de férias?**
11. **O que fazer com a pasta docs/?** Sugiro arquivá-la ou marcá-la claramente como "não é a arquitetura real" para não confundir decisões técnicas futuras — mas a decisão final é sua.

---

## 7. Recomendação da primeira etapa

### Etapa 1 — Importação da Hotmart e consistência dos dados

Concordo com sua proposta de começar por aqui: é a área com mais bugs confirmados no código, afeta diretamente o Financeiro (que várias etapas seguintes dependem), e — diferente de praticamente todo o resto do roadmap — não depende de nenhuma decisão arquitetural em aberto (armazenamento de arquivo, geração de PDF, backend para tokens). É um conserto autocontido, testável com o próprio CSV real, e reversível caso algo saia diferente do esperado.

Se fizer sentido para você, sugiro empacotar junto — por serem triviais, independentes, e de alta visibilidade — os dois ajustes citados na Etapa 13: o botão "Abrir metas" e a causa raiz já identificada do bug de rolagem da barra lateral no celular. Nenhum dos dois depende de decisão em aberto, e o segundo já foi classificado por você como urgente.

---

*Diagnóstico gerado a partir da leitura direta do código-fonte da pasta de backup e do Registro de Análise fornecido. Nenhum arquivo do projeto foi modificado nesta etapa. Aguardando sua aprovação antes de qualquer implementação.*
