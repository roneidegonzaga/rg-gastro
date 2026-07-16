# PRD 02 — Arquitetura do Sistema

Versão: 1.0
Status: Aprovado

---

# Objetivo

Este documento define a arquitetura funcional do Painel RG Gastrô.

Seu objetivo é estabelecer como todos os módulos se relacionam, quais são as responsabilidades de cada área do sistema e quais princípios deverão ser respeitados durante todo o desenvolvimento.

Este documento serve como referência para toda a estrutura do projeto.

---

# Arquitetura Geral

O Painel RG Gastrô será dividido em quatro grandes áreas.

Empresa

↓

Atendimento

↓

Marketing

↓

Configurações

Essas áreas deverão permanecer independentes, porém totalmente integradas.

---

# Área 1 — Empresa

A área Empresa representa toda a gestão interna da RG Gastrô.

É utilizada para administrar a própria empresa, independentemente dos clientes atendidos.

Compõem esta área:

- Visão Geral
- Financeiro
- Contas a Pagar
- Contas a Receber
- Metas
- Objetivos
- CRM
- Projetos e Tarefas
- Agenda
- Equipe
- Processos
- Biblioteca de Ferramentas
- Links Úteis

---

# Área 2 — Atendimento

A área Atendimento concentra toda a operação relacionada aos clientes e alunos.

Compõem esta área:

- Clientes de Consultoria
- Mentorados
- Cursos
- Certificados
- Vendas e Alunos

Todos os módulos desta área deverão compartilhar informações entre si quando necessário.

---

# Área 3 — Marketing

Responsável pela gestão de marketing da empresa.

Compõem esta área:

- Conteúdo
- Tráfego
- VTurb

Os três módulos deverão compartilhar indicadores, mantendo cada um sua responsabilidade específica.

---

# Área 4 — Configurações

Responsável pelas configurações gerais da plataforma.

Compõem esta área:

- Perfil
- Segurança
- Permissões
- Integrações
- Preferências
- Configurações Gerais

---

# Fluxo Principal

Empresa

↓

CRM

↓

Cliente

↓

Contrato

↓

Processos

↓

Checklists

↓

Ferramentas

↓

Indicadores

↓

Objetivos

↓

Cases

↓

Relatórios

↓

Encerramento

↓

Renovação

---

# Fluxo da Mentoria

Mentorado

↓

Onboarding

↓

Sessões

↓

Tarefas

↓

Processos

↓

Radar de Evolução

↓

Cases

↓

Conclusão

---

# Fluxo dos Cursos

Curso

↓

Produção

↓

Publicação

↓

Venda

↓

Aluno

↓

Certificado

↓

Histórico

---

# Fluxo de Marketing

Conteúdo

↓

Publicação

↓

Instagram

↓

Tráfego

↓

VTurb

↓

Conversão

↓

Vendas

---

# Integração entre Módulos

Os módulos deverão compartilhar informações automaticamente.

Exemplos.

CRM

↓

Clientes

↓

Financeiro

↓

Metas

---

Clientes

↓

Projetos e Tarefas

---

Mentorados

↓

Projetos e Tarefas

---

Agenda

↓

Clientes

↓

Mentorados

↓

Equipe

---

Financeiro

↓

Metas

↓

Dashboard

---

Conteúdo

↓

Tráfego

↓

VTurb

↓

Dashboard

---

Vendas

↓

Financeiro

↓

Metas

↓

Dashboard

---

# Componentes Compartilhados

Os seguintes componentes deverão possuir comportamento padronizado em toda a plataforma.

## Cockpit

Tela inicial de um módulo.

Apresenta visão executiva, KPIs, pendências e ações rápidas.

Será utilizado em:

- Empresa
- Clientes
- Mentorados
- Marketing (quando aplicável)

---

## Dashboard

Todo dashboard deverá seguir o mesmo padrão.

Estrutura.

KPIs

↓

Gráficos

↓

Filtros

↓

Drill-down

↓

Tabela

↓

Insights

Nunca criar dashboards diferentes entre módulos.

---

## Timeline

Responsável por registrar automaticamente todos os eventos importantes.

Será utilizada em:

- Clientes
- Mentorados

Futuramente poderá ser utilizada em outros módulos.

---

## Objetivos

Representam resultados desejados.

Poderão existir na Empresa e nos Clientes.

Nunca deverão ser tratados como tarefas.

---

## Cases

Representam resultados relevantes obtidos.

Poderão ser utilizados por:

- Clientes
- Mentorados
- Vendas e Alunos (futuro)

A estrutura deverá ser reutilizável.

---

## Processos

Todos os processos serão cadastrados uma única vez.

Posteriormente poderão ser aplicados em:

- Clientes
- Mentorados
- Equipe
- Cursos

Nunca duplicar processos.

---

## Checklists

Todo checklist será originado de um processo.

Não deverão ser criados manualmente dentro dos módulos.

---

## Biblioteca de Ferramentas

Centraliza todas as ferramentas utilizadas pela empresa.

Dividida em:

- D.O.S.E.
- PEC
- Personalizadas

As ferramentas HTML deverão alimentar automaticamente os indicadores.

---

## Inteligência Artificial

A IA será um componente compartilhado.

Sua função será:

- interpretar dados
- resumir informações
- gerar textos iniciais
- sugerir prioridades
- identificar padrões
- apoiar decisões

Nunca alterar automaticamente informações cadastradas pelo usuário.

---

# Regras Arquiteturais

Toda informação deverá possuir apenas um local de cadastro.

Sempre que possível, o sistema deverá atualizar automaticamente os demais módulos relacionados.

Nenhum módulo deverá depender de preenchimento duplicado.

As integrações deverão acontecer em segundo plano, sem exigir ações adicionais do usuário.

---

# Regras de Navegação

Todo módulo deverá possuir:

- pesquisa
- filtros
- dashboard
- ações rápidas
- histórico (quando aplicável)

Sempre que existir um cadastro detalhado, deverá existir um botão para retornar à listagem principal.

---

# Escalabilidade

A arquitetura deverá permitir:

- inclusão de novos módulos
- inclusão de novos dashboards
- inclusão de novas integrações
- inclusão de novas ferramentas
- inclusão de novos indicadores

Sem necessidade de alterar a estrutura existente.

---

# Critérios de Aceite

A arquitetura será considerada correta quando:

- todas as áreas estiverem organizadas por responsabilidade
- não existir duplicidade de informação
- todos os componentes compartilhados forem reutilizados
- todos os módulos seguirem o mesmo padrão estrutural
- as integrações ocorrerem automaticamente
- a navegação for consistente em toda a plataforma
- a arquitetura suportar expansão futura sem reconstrução do sistema