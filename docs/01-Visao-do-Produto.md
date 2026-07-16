# PRD 01 — Visão do Produto

Versão: 1.0
Status: Aprovado

---

# Objetivo

Este documento define a visão do Painel RG Gastrô, seus princípios de funcionamento e as diretrizes que deverão orientar todas as decisões de desenvolvimento.

Este é o documento mais importante da documentação. Em caso de conflito entre documentos, este documento prevalece.

---

# Visão do Produto

O Painel RG Gastrô é uma plataforma operacional desenvolvida para centralizar toda a gestão de uma empresa de consultoria gastronômica.

Seu objetivo é substituir o uso de planilhas, documentos isolados, Notion e controles paralelos, concentrando toda a operação em um único ambiente.

O sistema deverá ser capaz de organizar, automatizar e conectar todas as áreas da empresa, permitindo que o usuário trabalhe diariamente dentro do painel.

O produto deverá crescer continuamente sem perder consistência visual, lógica ou arquitetural.

Sua arquitetura deverá permitir evolução futura para um SaaS destinado a consultores gastronômicos.

---

# Problema que o produto resolve

Hoje a operação da empresa encontra-se distribuída em diversas ferramentas.

Exemplos:

- Planilhas
- Google Drive
- Google Agenda
- Notion
- Hotmart
- Meta Ads
- VTurb
- WhatsApp
- Documentos em PDF

Essa descentralização provoca:

- retrabalho
- perda de informações
- dificuldade de acompanhamento
- falta de padronização
- dificuldade para gerar indicadores
- baixa previsibilidade
- dificuldade para escalar a operação

O Painel RG Gastrô deverá eliminar esse cenário.

---

# Objetivos do Produto

O sistema deverá permitir gerenciar:

- Empresa
- Financeiro
- Metas
- Objetivos
- CRM
- Clientes de Consultoria
- Mentorados
- Cursos
- Certificados
- Vendas e Alunos
- Marketing
- Produção de Conteúdo
- Tráfego Pago
- VTurb
- Agenda
- Equipe
- Processos
- Biblioteca de Ferramentas
- Inteligência Artificial

Tudo deverá funcionar de forma integrada.

---

# Princípios do Produto

## 1. Fonte única da informação

Cada informação deverá ser cadastrada apenas uma vez.

A partir desse cadastro, todos os módulos relacionados deverão ser atualizados automaticamente.

O sistema nunca deverá exigir preenchimento duplicado.

---

## 2. Automação sempre que possível

Sempre que uma tarefa puder ser automatizada sem perda de controle, ela deverá ser automatizada.

Exemplos:

- gerar contas recorrentes
- atualizar dashboards
- alimentar indicadores
- criar tarefas
- criar checklists
- criar processos
- gerar relatórios
- sugerir análises por IA

---

## 3. Organização orientada por contexto

O usuário deverá encontrar todas as informações relacionadas ao mesmo assunto dentro do mesmo ambiente.

Exemplo.

Ao abrir um cliente, deverá encontrar:

- indicadores
- objetivos
- contratos
- processos
- checklists
- relatórios
- documentos
- visitas
- histórico
- cases

Sem precisar navegar por diversos módulos.

---

## 4. Dashboards orientados à decisão

Os dashboards não existem apenas para mostrar números.

Seu objetivo é apoiar decisões.

Todo dashboard deverá responder rapidamente:

- O que aconteceu?
- Como evoluiu?
- O que precisa de atenção?
- Qual é o próximo passo?

---

## 5. Inteligência Artificial como apoio

A Inteligência Artificial nunca deverá substituir o consultor.

Sua função será:

- resumir informações
- interpretar indicadores
- sugerir prioridades
- gerar textos iniciais
- identificar padrões
- acelerar o trabalho

Toda decisão continuará sendo do usuário.

---

## 6. Componentes reutilizáveis

Sempre que possível, módulos diferentes deverão utilizar os mesmos componentes.

Exemplos:

- Cockpit
- Dashboard
- Timeline
- Cases
- Objetivos
- Processos
- Checklists
- Indicadores

Isso garante consistência visual e reduz complexidade de desenvolvimento.

---

## 7. Escalabilidade

Toda decisão de arquitetura deverá considerar que o produto poderá crescer continuamente.

Novos módulos deverão ser adicionados sem necessidade de reconstrução da plataforma.

---

# Estrutura Macro do Sistema

O sistema será organizado em quatro áreas principais.

## Empresa

Responsável pela gestão interna da empresa.

## Atendimento

Responsável pelo acompanhamento de clientes, mentorados, cursos e alunos.

## Marketing

Responsável pela gestão de conteúdo, tráfego pago e VTurb.

## Configurações

Responsável pelas configurações gerais, permissões, integrações e parametrizações.

Cada área será detalhada em documentos específicos.

---

# Padrão de Desenvolvimento

Todos os módulos do sistema deverão seguir o mesmo padrão.

Cada módulo deverá possuir, quando aplicável:

- Cockpit
- Dashboard
- Pesquisa
- Filtros
- KPIs
- Histórico
- Timeline
- Integrações
- Inteligência Artificial
- Permissões
- Critérios de aceite

O comportamento deverá ser consistente em toda a plataforma.

---

# Diretrizes de UX

A experiência do usuário deverá seguir os seguintes princípios.

- poucos cliques
- navegação intuitiva
- informações agrupadas por contexto
- ações rápidas sempre visíveis
- filtros padronizados
- dashboards consistentes
- design limpo
- foco em produtividade

---

# Critérios de Qualidade

Uma funcionalidade somente será considerada pronta quando:

- cumprir seu objetivo de negócio
- respeitar a arquitetura do sistema
- integrar-se corretamente aos demais módulos
- não gerar retrabalho
- possuir navegação consistente
- responder aos filtros corretamente
- alimentar dashboards quando necessário
- respeitar as permissões de acesso

---

# Critérios de Aceite

Este documento será considerado atendido quando todo o sistema respeitar os seguintes princípios:

- uma informação cadastrada apenas uma vez
- integração entre módulos
- automações sempre que possível
- dashboards orientados à tomada de decisão
- componentes reutilizáveis
- arquitetura escalável
- Inteligência Artificial como apoio ao usuário
- experiência consistente em toda a plataforma
- possibilidade de evolução futura para SaaS