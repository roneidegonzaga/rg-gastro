# PRD 14 — Vendas e Alunos

Versão: 1.0
Status: Aprovado

---

# Objetivo

O módulo Vendas e Alunos é responsável por centralizar todas as vendas dos produtos educacionais da empresa, bem como o cadastro e acompanhamento dos alunos.

Seu objetivo é consolidar as informações provenientes da Hotmart, calcular indicadores de vendas, acompanhar a evolução da base de alunos e alimentar automaticamente os módulos Financeiro, Metas e Visão Geral.

O módulo deverá funcionar como uma camada analítica sobre os dados da Hotmart, sem substituir a plataforma.

---

# Objetivos do Módulo

O módulo deverá permitir.

- importar vendas da Hotmart
- gerenciar alunos
- acompanhar produtos
- calcular indicadores
- controlar status das compras
- alimentar dashboards
- integrar com Financeiro
- integrar com Certificados
- integrar com Cursos

---

# Estrutura

Vendas e Alunos

↓

Dashboard

↓

Importações

↓

Alunos

↓

Produtos

↓

Vendas

↓

Sinos

↓

Cases

↓

Relatórios

↓

Timeline

---

# Dashboard

O Dashboard deverá responder rapidamente.

- Quantos alunos existem?
- Quanto foi faturado?
- Qual o ticket médio por aluno?
- Qual produto mais vendeu?
- Qual produto gerou mais faturamento?
- Quantos reembolsos ocorreram?
- Quantos novos alunos entraram?
- Como está a evolução das vendas?

---

# KPIs

Alunos

Vendas

Faturamento

Ticket Médio por Aluno

Reembolsos

Produtos Ativos

Novos Alunos

Conversão (futuro)

Todos os KPIs deverão ser clicáveis.

---

# Ticket Médio

O Ticket Médio deverá ser calculado por aluno.

Fórmula.

Faturamento

÷

Quantidade de alunos

Nunca utilizar.

Faturamento

÷

Quantidade de vendas

---

# Importação

O módulo deverá permitir importar arquivos CSV da Hotmart.

Sempre que possível.

Detectar automaticamente o layout.

---

# Histórico de Importações

Registrar.

Arquivo

Data

Usuário

Quantidade importada

Quantidade ignorada

Quantidade com erro

Observações

---

# Reimportação

O sistema deverá identificar registros duplicados.

Nunca duplicar vendas.

Permitir reimportar períodos anteriores.

---

# Exclusão

Permitir excluir uma importação.

Ao excluir.

Remover apenas os registros originados daquela importação.

Nunca apagar registros de outras importações.

---

# Alunos

Cada aluno deverá possuir.

Nome

WhatsApp

E-mail

Cidade

Estado

Produtos adquiridos

Valor total investido

Primeira compra

Última compra

Status

Tags

Observações

---

# WhatsApp

Sempre que existir telefone válido.

Exibir botão.

Abrir WhatsApp

---

# Produtos

Cada produto deverá possuir.

Nome

Categoria

Status

Preço

Quantidade de alunos

Quantidade de vendas

Faturamento

Ticket Médio

---

# Categorias

Curso

Mentoria

Workshop

Imersão

Outro

---

# Vendas

Cada venda deverá possuir.

Aluno

Produto

Valor

Data

Forma de pagamento

Origem

Status

Observações

---

# Status

Aprovada

Pendente

Reembolsada

Chargeback

Cancelada

Recorrente

---

# Reembolso

Quando uma venda for marcada como Reembolsada.

Atualizar automaticamente.

Faturamento

↓

Dashboard

↓

Financeiro

↓

Metas

↓

Visão Geral

---

# Filtros

Todos

Período

Produto

Categoria

Status

Aluno

Origem

Personalizado

Todos os dashboards deverão responder aos filtros.

---

# Dashboard por Produto

Ao selecionar um produto.

Atualizar automaticamente.

KPIs

↓

Gráficos

↓

Tabela

↓

Insights

Sem necessidade de mudar de página.

---

# Dashboard Analítico

Mostrar.

Vendas por período

Faturamento por período

Produtos mais vendidos

Produtos mais lucrativos

Alunos por período

Ticket Médio

Status das vendas

---

# Sinos

Criar um módulo específico.

O objetivo é registrar as conquistas dos alunos.

Essa área será independente do módulo Mentorados.

---

# Cadastro

Aluno

Produto

Data

Quantidade de dias até o primeiro sino

Quantidade total de sinos

Descrição

Observações

---

# Dashboard dos Sinos

Mostrar.

Total de Sinos

Primeiro Sino Médio

Alunos sem Sino

Alunos com mais de um Sino

Evolução por período

Ranking

---

# Cases

Permitir registrar provas sociais dos alunos.

Utilizar exatamente a mesma estrutura do componente Cases.

Galeria

Links

Benefícios

Tags

Favoritos

Autorizações

Dashboard

---

# Relatórios

Gerar.

Vendas

Alunos

Produtos

Ticket Médio

Reembolsos

Sinos

Cases

Todos exportáveis em PDF.

---

# Timeline

Registrar automaticamente.

Importações

Novas vendas

Reembolsos

Novos alunos

Atualizações

Sinos

Cases

---

# Inteligência Artificial

A IA poderá.

Interpretar evolução das vendas.

Comparar produtos.

Identificar sazonalidade.

Explicar redução de faturamento.

Apontar produtos com maior potencial.

Gerar resumo executivo.

Nunca alterar dados importados.

---

# Integrações

Hotmart

Financeiro

Cursos

Certificados

Metas

Visão Geral

Inteligência Artificial

---

# Permissões

Administradores.

Acesso total.

Equipe.

Somente módulos autorizados.

---

# Critérios de Aceite

O módulo será considerado concluído quando.

✓ importar CSV da Hotmart

✓ impedir duplicação de registros

✓ permitir excluir importações

✓ calcular Ticket Médio por aluno

✓ atualizar dashboards por produto

✓ controlar reembolsos

✓ atualizar Financeiro automaticamente

✓ atualizar Metas automaticamente

✓ atualizar Visão Geral automaticamente

✓ possuir Dashboard Analítico

✓ possuir módulo de Sinos

✓ possuir módulo de Cases

✓ manter Timeline completa

✓ integrar com Hotmart

✓ integrar com Cursos

✓ integrar com Certificados

✓ funcionar em desktop e mobile