# PRD 06 — Financeiro

Versão: 1.0
Status: Aprovado

---

# Objetivo

O módulo Financeiro é responsável por controlar toda a movimentação financeira da empresa.

Seu objetivo não é apenas registrar receitas e despesas, mas fornecer informações para tomada de decisão, alimentar automaticamente metas, dashboards, fluxo de caixa e projeções financeiras.

Todo lançamento financeiro deverá possuir uma origem e, sempre que possível, ser criado automaticamente por outros módulos do sistema.

---

# Objetivos do Módulo

O módulo deverá permitir:

- controlar receitas
- controlar despesas
- controlar contas a pagar
- controlar contas a receber
- visualizar fluxo de caixa
- acompanhar resultado líquido
- alimentar metas
- alimentar dashboards
- realizar projeções
- gerar relatórios

---

# Estrutura do Módulo

Financeiro

↓

Dashboard

↓

Receitas

↓

Despesas

↓

Contas a Receber

↓

Contas a Pagar

↓

Categorias

↓

Centros de Resultado

↓

Fluxo de Caixa

↓

Relatórios

---

# Dashboard Financeiro

O Dashboard deverá responder rapidamente:

- Quanto entrou?
- Quanto saiu?
- Quanto vou receber?
- Quanto vou pagar?
- Qual meu lucro líquido?
- Estou crescendo?
- Qual categoria gera mais receita?
- Qual categoria gera mais despesas?

---

# KPIs

Receita Total

Despesa Total

Resultado Líquido

Contas a Receber

Contas a Pagar

Saldo Previsto

Ticket Médio por Aluno

Receita Recorrente

Todos os KPIs deverão ser clicáveis.

---

# Filtros

Todos os gráficos e tabelas deverão responder aos mesmos filtros.

Período

Hoje

7 dias

30 dias

60 dias

90 dias

12 meses

Personalizado

Categoria

Centro de Resultado

Tipo

Origem

Status

---

# Receitas

Cada receita deverá possuir.

Descrição

Valor

Data

Categoria

Centro de Resultado

Origem

Cliente (quando existir)

Curso (quando existir)

Contrato (quando existir)

Forma de pagamento

Observações

Status

---

# Origem da Receita

Manual

Clientes

Hotmart

Mentorias

Consultorias

SEBRAE

Projeto Especial

Outro

---

# Despesas

Cada despesa deverá possuir.

Descrição

Valor

Categoria

Centro de Resultado

Fornecedor

Data

Forma de pagamento

Recorrente

Observações

Status

---

# Categorias

O usuário deverá poder criar categorias personalizadas.

Exemplos.

Salários

Marketing

Softwares

Impostos

Equipamentos

Viagens

Freelas

Outros

---

# Dashboard por Categoria

Mostrar.

Receitas por categoria

Despesas por categoria

Resultado por categoria

Percentual de participação

Ranking

Gráfico de Rosca

Gráfico de Barras

Todos deverão responder aos filtros.

---

# Centros de Resultado

Permitir separar receitas por unidade de negócio.

Exemplos.

Infoprodutos

Mentorias

Consultorias

Escritório

SEBRAE

Projeto Especial

Outros

---

# Dashboard por Centro de Resultado

Mostrar.

Receita

Despesa

Lucro

Margem

Participação percentual

---

# Contas a Receber

Cada conta deverá possuir.

Cliente

Origem

Valor

Vencimento

Status

Forma de pagamento

Observações

---

# Status

Prevista

Recebida

Vencida

Cancelada

---

# Contas a Pagar

Cada conta deverá possuir.

Fornecedor

Categoria

Valor

Vencimento

Status

Forma de pagamento

Observações

---

# Status

Prevista

Paga

Vencida

Cancelada

---

# Receitas Recorrentes

O sistema deverá permitir gerar automaticamente receitas futuras.

Exemplo.

Cliente

↓

Contrato de 6 meses

↓

Mensalidade

↓

Todo dia 10

↓

Gerar automaticamente as próximas contas a receber.

---

# Despesas Recorrentes

Também deverão existir.

Exemplos.

Internet

Softwares

Aluguel

Plano de Saúde

Contabilidade

Assinaturas

---

# Fluxo de Caixa

Mostrar.

Entradas

Saídas

Saldo

Saldo previsto

Projeção

---

# Resultado Líquido

Criar indicador próprio.

Resultado Líquido

=

Receitas

-

Despesas

Esse indicador deverá alimentar.

Visão Geral

Metas

Dashboard Executivo

---

# Integrações

O Financeiro deverá receber informações automaticamente de.

CRM

Clientes

Hotmart

Vendas e Alunos

Metas

Objetivos

---

# Relatórios

Gerar.

Fluxo de Caixa

Receitas

Despesas

Resultado

Categorias

Centros de Resultado

Personalizado

Todos exportáveis em PDF.

---

# Dashboard Analítico

O Dashboard Financeiro deverá conter.

KPIs

↓

Receita x Despesa

↓

Resultado Líquido

↓

Receitas por Categoria

↓

Despesas por Categoria

↓

Centros de Resultado

↓

Fluxo de Caixa

↓

Tabela

↓

Insights

---

# Inteligência Artificial

A IA poderá.

Interpretar evolução financeira.

Identificar aumento de despesas.

Apontar categorias críticas.

Detectar redução de margem.

Gerar resumo executivo financeiro.

Nunca alterar lançamentos.

---

# Permissões

Administradores.

Acesso total.

Equipe.

Somente módulos autorizados.

---

# Critérios de Aceite

O módulo será considerado concluído quando.

✓ permitir cadastro de receitas

✓ permitir cadastro de despesas

✓ controlar contas a pagar

✓ controlar contas a receber

✓ gerar recorrências automaticamente

✓ permitir categorias personalizadas

✓ permitir centros de resultado

✓ possuir Dashboard Financeiro

✓ possuir Dashboard por Categoria

✓ possuir Dashboard por Centro de Resultado

✓ calcular resultado líquido

✓ alimentar Visão Geral

✓ alimentar Metas

✓ responder aos filtros

✓ exportar relatórios em PDF

✓ integrar automaticamente com os demais módulos

✓ funcionar em desktop e mobile