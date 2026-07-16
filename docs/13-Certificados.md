# PRD 13 — Certificados

Versão: 1.0
Status: Aprovado

---

# Objetivo

O módulo Certificados é responsável por controlar todo o fluxo de emissão de certificados dos cursos da empresa.

Seu objetivo é eliminar controles paralelos, acompanhar solicitações, padronizar o processo de emissão e manter histórico completo de todos os certificados emitidos.

O módulo deverá funcionar integrado ao módulo Cursos e ao módulo Vendas e Alunos.

---

# Objetivos do Módulo

O módulo deverá permitir.

- controlar solicitações
- acompanhar emissão
- organizar documentos
- acompanhar pendências
- registrar histórico
- integrar com alunos
- integrar com cursos

---

# Estrutura

Certificados

↓

Dashboard

↓

Solicitações

↓

Emissão

↓

Emitidos

↓

Fluxos

↓

Documentos

↓

Timeline

---

# Dashboard

O Dashboard deverá responder rapidamente.

- Quantos certificados estão pendentes?
- Quantos foram emitidos?
- Quantos estão aguardando pagamento?
- Qual o tempo médio de emissão?
- Existem atrasos?

---

# KPIs

Solicitações Pendentes

Aguardando Pagamento

Em Emissão

Emitidos

Tempo Médio de Emissão

Pendências

Todos os KPIs deverão ser clicáveis.

---

# Solicitações

Cada solicitação deverá possuir.

Aluno

Curso

Data da Solicitação

Pagamento da Taxa

Status

Responsável

Observações

---

# Status

Solicitado

Aguardando Pagamento

Pagamento Confirmado

Em Emissão

Emitido

Cancelado

---

# Fluxo

O fluxo deverá seguir exatamente esta sequência.

Solicitação

↓

Pagamento da Taxa

↓

Confirmação

↓

Emissão

↓

Envio

↓

Concluído

---

# Tarefas Automáticas

Ao alterar o status.

O sistema deverá criar automaticamente as tarefas necessárias.

Exemplo.

Pagamento confirmado

↓

Criar tarefa.

Solicitar emissão

↓

Criar tarefa.

Acompanhar emissão

↓

Criar tarefa.

Enviar certificado

---

# Dashboard do Fluxo

Mostrar.

Solicitados

Aguardando pagamento

Em emissão

Emitidos

Tempo médio

---

# Cadastro do Certificado

Cada certificado deverá possuir.

Aluno

Curso

Código

Data de emissão

Carga horária

Arquivo PDF

Link

Responsável

Observações

---

# Histórico

Nunca apagar certificados emitidos.

Registrar.

Emissão

Reenvios

Correções

Cancelamentos

---

# Pesquisa

Permitir pesquisar por.

Aluno

Curso

Código

Status

Período

---

# Filtros

Todos

Pendentes

Emissão

Emitidos

Cancelados

Período

Personalizado

---

# Integrações

Cursos

↓

Vendas e Alunos

↓

Google Drive

↓

Projetos e Tarefas

---

# Google Drive

Permitir cadastrar.

Pasta principal

Modelo

PDF Final

Links

---

# Timeline

Registrar automaticamente.

Solicitação

Pagamento

Confirmação

Emissão

Envio

Correções

Cancelamentos

---

# Inteligência Artificial

A IA poderá.

Identificar certificados atrasados.

Gerar resumo das pendências.

Apontar gargalos do fluxo.

Nunca emitir certificados automaticamente.

---

# Permissões

Administradores.

Acesso total.

Equipe.

Somente emissão e acompanhamento.

---

# Critérios de Aceite

O módulo será considerado concluído quando.

✓ controlar solicitações

✓ controlar pagamento da taxa

✓ controlar emissão

✓ controlar envio

✓ manter histórico

✓ integrar com Cursos

✓ integrar com Vendas e Alunos

✓ gerar tarefas automaticamente

✓ possuir Dashboard

✓ responder aos filtros

✓ manter Timeline

✓ integrar com Google Drive

✓ funcionar em desktop e mobile