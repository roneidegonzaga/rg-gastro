# PRD 28 — Automações

Versão: 1.0
Status: Aprovado

---

# Objetivo

Este documento define todas as automações do Painel RG Gastrô.

Seu objetivo é eliminar atividades repetitivas, reduzir erros operacionais e garantir que os módulos da plataforma trabalhem de forma integrada.

Toda automação deverá ser baseada em eventos.

Nunca depender de execução manual quando uma ação puder ser realizada automaticamente.

---

# Princípios

Toda automação deverá.

• possuir um evento de origem

• possuir condições de execução

• executar ações previsíveis

• registrar logs

• registrar Timeline

• permitir auditoria

• nunca excluir informações automaticamente

---

# Estrutura

Evento

↓

Condição

↓

Ação

↓

Logs

↓

Timeline

---

# CRM

## Proposta aceita

Evento.

Proposta alterada para "Aceita".

---

Ações.

Criar Cliente

↓

Criar Contrato

↓

Criar Projeto

↓

Aplicar Processo de Onboarding

↓

Gerar Tarefas

↓

Criar Conta a Receber

↓

Atualizar Financeiro

↓

Atualizar Metas

↓

Atualizar Visão Geral

↓

Registrar Timeline

---

## Lead perdido

Evento.

Status alterado para Perdido.

---

Ações.

Solicitar motivo

↓

Atualizar Dashboard

↓

Adicionar à lista de Recuperação

↓

Registrar Timeline

---

## Follow-up vencido

Evento.

Data do follow-up expirada.

---

Ações.

Criar alerta

↓

Atualizar Agenda

↓

Atualizar Visão Geral

↓

Registrar Timeline

---

# Clientes

## Novo contrato

Evento.

Contrato criado.

---

Ações.

Criar Projeto

↓

Aplicar Processo

↓

Gerar Tarefas

↓

Atualizar Dashboard

↓

Registrar Timeline

---

## Contrato encerrando

Evento.

Contrato a 30 dias do vencimento.

---

Ações.

Criar tarefa de renovação

↓

Criar lembrete

↓

Atualizar Dashboard

↓

Registrar Timeline

---

## Objetivo atingido

Evento.

Indicador atingir a meta definida.

---

Ações.

Sugerir conclusão do objetivo

↓

Sugerir criação de Case

↓

Atualizar Dashboard

---

# Mentorados

## Nova sessão

Evento.

Sessão concluída.

---

Ações.

Criar tarefas

↓

Atualizar Radar (opcional)

↓

Atualizar Dashboard

↓

Registrar Timeline

---

## Primeiro sino

Evento.

Primeiro sino registrado.

---

Ações.

Atualizar KPIs

↓

Atualizar Dashboard de Sinos

↓

Atualizar Visão Geral

↓

Registrar Timeline

↓

Sugerir criação de Case

---

## Novo sino

Evento.

Novo sino registrado.

---

Ações.

Atualizar indicadores

↓

Atualizar ranking

↓

Registrar Timeline

---

# Cursos

## Nova versão

Evento.

Nova versão publicada.

---

Ações.

Atualizar histórico

↓

Atualizar Dashboard

↓

Registrar Timeline

---

# Certificados

## Pagamento confirmado

Evento.

Pagamento aprovado.

---

Ações.

Criar tarefa de emissão

↓

Atualizar Dashboard

↓

Registrar Timeline

---

## Certificado emitido

Evento.

Emissão concluída.

---

Ações.

Atualizar aluno

↓

Atualizar curso

↓

Atualizar Dashboard

↓

Registrar Timeline

---

# Vendas e Alunos

## Nova venda

Evento.

Venda importada.

---

Ações.

Criar aluno (quando necessário)

↓

Atualizar faturamento

↓

Atualizar Financeiro

↓

Atualizar Metas

↓

Atualizar Dashboard

↓

Atualizar Visão Geral

↓

Registrar Timeline

---

## Reembolso

Evento.

Venda alterada para Reembolsada.

---

Ações.

Atualizar Financeiro

↓

Atualizar Metas

↓

Atualizar Dashboard

↓

Atualizar Visão Geral

↓

Registrar Timeline

---

# Financeiro

## Receita recebida

Evento.

Receita marcada como recebida.

---

Ações.

Atualizar Fluxo de Caixa

↓

Atualizar KPIs

↓

Atualizar Metas

↓

Atualizar Visão Geral

---

## Despesa paga

Evento.

Despesa marcada como paga.

---

Ações.

Atualizar Fluxo de Caixa

↓

Atualizar KPIs

↓

Atualizar Dashboard

---

# Marketing

## Conteúdo publicado

Evento.

Status alterado para Publicado.

---

Ações.

Atualizar Dashboard

↓

Atualizar Timeline

↓

Atualizar Calendário

---

## Analytics importado

Evento.

Nova importação concluída.

---

Ações.

Atualizar KPIs

↓

Atualizar Conteúdos Campeões

↓

Atualizar Dashboard

---

# Tráfego

## Relatório importado

Evento.

Importação concluída.

---

Ações.

Atualizar KPIs

↓

Atualizar campanhas

↓

Atualizar criativos

↓

Atualizar Dashboard

---

# VTurb

## Novo relatório

Evento.

Importação concluída.

---

Ações.

Atualizar retenção

↓

Atualizar Dashboard

↓

Atualizar Visão Geral

---

# Projetos e Tarefas

## Processo aplicado

Evento.

Processo iniciado.

---

Ações.

Criar Projeto

↓

Criar Tarefas

↓

Criar Checklists

↓

Criar Prazos

↓

Atualizar Dashboard

↓

Registrar Timeline

---

## Tarefa concluída

Evento.

Status alterado para Concluída.

---

Ações.

Atualizar Projeto

↓

Atualizar Produtividade

↓

Atualizar Dashboard

↓

Registrar Timeline

---

# Agenda

## Novo compromisso

Evento.

Compromisso criado.

---

Ações.

Atualizar Dashboard

↓

Atualizar Visão Geral

↓

Registrar Timeline

---

# Inteligência Artificial

A IA poderá ser acionada automaticamente após determinados eventos.

Exemplos.

Checklist concluído

↓

Gerar resumo

---

Radar atualizado

↓

Comparar evolução

---

Importação financeira

↓

Gerar insights

---

Nova venda

↓

Atualizar resumo executivo

---

Primeiro sino

↓

Sugerir Case

---

# Logs

Toda automação deverá registrar.

Data

Hora

Evento

Origem

Destino

Usuário

Resultado

Tempo de execução

Erro (quando existir)

---

# Auditoria

Toda automação deverá permitir rastreamento completo.

Nunca executar ações sem possibilidade de auditoria.

---

# Falhas

Caso uma automação falhe.

Registrar erro

↓

Notificar usuário (quando necessário)

↓

Permitir reprocessamento

Nunca perder informações.

---

# Futuras Automações

Integração com WhatsApp

Integração com N8N

Integração com Make

Integração com Zapier

Automações baseadas em IA

Automações agendadas

Automações condicionais

---

# Critérios de Aceite

Este documento será considerado atendido quando.

✓ todos os principais eventos estiverem mapeados

✓ todas as automações possuírem gatilho definido

✓ todas registrarem Timeline

✓ todas registrarem Logs

✓ todas permitirem auditoria

✓ todas permitirem reprocessamento em caso de falha

✓ nenhuma automação excluir dados automaticamente

✓ toda a plataforma permanecer preparada para novas automações