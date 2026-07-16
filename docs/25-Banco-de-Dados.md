# PRD 25 — Banco de Dados

Versão: 1.0
Status: Aprovado

---

# Objetivo

Este documento define a estrutura lógica do banco de dados do Painel RG Gastrô.

Seu objetivo é garantir consistência entre todos os módulos da plataforma, evitando duplicação de informações e garantindo que todos utilizem as mesmas entidades.

Este documento não representa o modelo físico do banco.

Ele representa o modelo de negócio da aplicação.

---

# Princípios

Toda informação deverá possuir uma única origem.

Nunca duplicar entidades.

Sempre relacionar informações.

Nunca copiar dados entre módulos.

---

# Estrutura Geral

Empresa

↓

Usuários

↓

Clientes

↓

Mentorados

↓

Alunos

↓

Financeiro

↓

CRM

↓

Projetos

↓

Agenda

↓

Marketing

↓

Processos

↓

Ferramentas

↓

Configurações

---

# EMPRESA

Representa a empresa proprietária do sistema.

Relacionamentos.

Empresa

1:1 Configurações

1:N Usuários

1:N Clientes

1:N Mentorados

1:N Alunos

1:N Projetos

1:N Processos

1:N Ferramentas

---

# USUÁRIOS

Representa qualquer pessoa que utiliza o sistema.

Relacionamentos.

Usuário

1:N Projetos

1:N Tarefas

1:N Clientes

1:N Mentorados

1:N Processos

1:N Relatórios

1:N Sessões

1:N Compromissos

---

# CLIENTES

Relacionamentos.

Cliente

1:N Contratos

1:N Objetivos

1:N Indicadores

1:N Ferramentas Aplicadas

1:N Processos

1:N Checklists

1:N Relatórios

1:N Cases

1:N Visitas

1:N Documentos

1:N Timeline

N:1 Consultor

---

# CONTRATOS

Contrato

N:1 Cliente

1:N Serviços

1:N Parcelas

1:N Receitas

---

# OBJETIVOS

Objetivo

N:1 Cliente

N:1 Indicador

N:1 Usuário

---

# INDICADORES

Indicador

N:1 Cliente

1:N Histórico

---

# HISTÓRICO DE INDICADORES

Histórico

N:1 Indicador

---

# MENTORADOS

Mentorado

1:N Sessões

1:N Tarefas

1:N Radar

1:N Processos

1:N Cases

1:N Sinos

1:N Benefícios

1:N Documentos

1:N Timeline

N:1 Mentor

---

# SESSÕES

Sessão

N:1 Mentorado

1:N Arquivos

---

# RADAR

Radar

N:1 Mentorado

1:N Avaliações

---

# AVALIAÇÕES

Avaliação

N:1 Radar

---

# SINOS

Sino

N:1 Mentorado

---

# BENEFÍCIOS

Benefício

N:1 Mentorado

---

# ALUNOS

Aluno

N:N Produtos

1:N Certificados

1:N Cases

1:N Sinos

---

# PRODUTOS

Produto

N:N Alunos

1:N Vendas

---

# VENDAS

Venda

N:1 Produto

N:1 Aluno

---

# CERTIFICADOS

Certificado

N:1 Aluno

N:1 Curso

---

# CURSOS

Curso

1:N Módulos

1:N Materiais

1:N Documentos

1:N Certificados

---

# MÓDULOS

Módulo

N:1 Curso

1:N Aulas

---

# AULAS

Aula

N:1 Módulo

---

# PROCESSOS

Processo

N:N Clientes

N:N Mentorados

N:N Cursos

1:N Tarefas

1:N Checklists

---

# CHECKLISTS

Checklist

N:1 Processo

1:N Itens

---

# ITENS

Item

N:1 Checklist

---

# PROJETOS

Projeto

1:N Tarefas

N:1 Usuário

---

# TAREFAS

Tarefa

N:1 Projeto

N:1 Usuário

Origem opcional.

Cliente

Mentorado

Curso

Processo

CRM

Financeiro

Marketing

---

# CRM

Lead

1:N Follow-ups

1:N Objeções

1:N Propostas

1:N Timeline

---

# FOLLOW-UPS

Follow-up

N:1 Lead

---

# OBJEÇÕES

Objeção

N:1 Lead

---

# PROPOSTAS

Proposta

N:1 Lead

Quando aceita.

↓

Gera Cliente

↓

Gera Contrato

---

# FINANCEIRO

Centro de Resultado

1:N Receitas

1:N Despesas

---

# RECEITAS

Receita

N:1 Centro de Resultado

Origem opcional.

Cliente

Hotmart

Outro

---

# DESPESAS

Despesa

N:1 Centro de Resultado

---

# MARKETING

Perfil

1:N Conteúdos

1:N Campanhas

1:N Analytics

---

# CONTEÚDOS

Conteúdo

N:1 Perfil

N:1 Produto

---

# CAMPANHAS

Campanha

N:1 Perfil

N:N Conteúdos

N:N Criativos

---

# CRIATIVOS

Criativo

N:N Campanhas

---

# CASES

Case

Origem.

Cliente

Mentorado

Aluno

Todos utilizarão a mesma entidade.

Nunca criar tabelas diferentes.

---

# DOCUMENTOS

Documento

Origem.

Cliente

Mentorado

Curso

Projeto

Outro

---

# ARQUIVOS

Arquivo

Origem.

Documento

Case

Checklist

Sessão

Visita

Outro

---

# TIMELINE

A Timeline será uma entidade única.

Origem.

Cliente

Mentorado

Curso

Projeto

CRM

Marketing

Financeiro

Outro

Nunca existirão tabelas diferentes de Timeline.

---

# TAGS

As Tags serão globais.

Qualquer entidade poderá utilizar.

---

# CATEGORIAS

Também serão globais.

Sempre reutilizadas.

---

# RELACIONAMENTOS OBRIGATÓRIOS

Clientes

↓

Financeiro

↓

Metas

↓

Visão Geral

---

CRM

↓

Clientes

↓

Financeiro

↓

Agenda

↓

Projetos

---

Mentorados

↓

Projetos

↓

Agenda

↓

Sinos

↓

Cases

---

Marketing

↓

Tráfego

↓

VTurb

↓

Visão Geral

---

Cursos

↓

Certificados

↓

Vendas e Alunos

↓

Financeiro

---

# Regras Gerais

Nunca duplicar entidades.

Nunca duplicar históricos.

Nunca duplicar timelines.

Nunca duplicar tags.

Nunca duplicar categorias.

Sempre reutilizar relacionamentos existentes.

---

# Critérios de Aceite

Este documento será considerado atendido quando.

✓ todas as entidades estiverem definidas

✓ todos os relacionamentos estiverem documentados

✓ não existirem duplicações de entidades

✓ todos os módulos utilizarem este modelo lógico

✓ o banco permanecer preparado para evolução futura