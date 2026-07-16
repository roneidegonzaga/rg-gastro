# PRD 04 — Design System

Versão: 1.0
Status: Aprovado

---

# Objetivo

Este documento define o padrão visual e de experiência do usuário do Painel RG Gastrô.

Todos os módulos deverão seguir estas diretrizes para garantir consistência, previsibilidade e facilidade de uso.

Nenhum módulo poderá criar componentes próprios quando já existir um componente padronizado.

---

# Filosofia de Design

O sistema deverá transmitir sensação de organização, clareza e controle.

A interface deverá priorizar produtividade.

Toda decisão visual deverá responder à pergunta:

"Isso ajuda o usuário a trabalhar mais rápido?"

Se a resposta for não, a solução deverá ser revista.

---

# Princípios

## Clareza

A informação mais importante deve aparecer primeiro.

Nunca obrigar o usuário a procurar informações essenciais.

---

## Consistência

Botões iguais deverão possuir o mesmo comportamento.

Cores iguais deverão possuir o mesmo significado.

Filtros deverão funcionar da mesma maneira em todos os módulos.

---

## Poucos cliques

Toda ação frequente deverá exigir o menor número possível de cliques.

---

## Contexto

Sempre que possível, todas as informações relacionadas ao mesmo assunto deverão permanecer na mesma tela.

Evitar abrir novas páginas sem necessidade.

---

# Estrutura das Telas

Todos os módulos deverão seguir esta estrutura.

Cabeçalho

↓

Filtros

↓

KPIs

↓

Dashboard

↓

Conteúdo principal

↓

Tabela ou Cards

↓

Histórico (quando aplicável)

---

# Cabeçalho

O cabeçalho deverá conter.

Título da página

Descrição curta

Botão principal da tela

Ações rápidas

---

Exemplo.

Clientes

Gerencie toda a operação dos seus clientes.

[Novo Cliente]

---

# Filtros

Os filtros deverão aparecer sempre abaixo do cabeçalho.

Padrão.

Pesquisa

↓

Filtros rápidos

↓

Filtros avançados

↓

Período

↓

Limpar filtros

---

Filtros deverão atualizar dashboards e tabelas simultaneamente.

---

# KPIs

Sempre posicionados acima dos gráficos.

Padrão.

Card

Número

Título

Variação

Ícone (opcional)

---

Ao clicar.

Abrir detalhamento.

---

# Dashboard

Todos os dashboards deverão utilizar o mesmo padrão visual.

Ordem.

KPIs

↓

Gráficos

↓

Tabela

↓

Insights

---

Nunca inverter essa ordem.

---

# Cockpit

Todo Cockpit deverá possuir.

Cabeçalho

↓

Indicadores principais

↓

Pendências

↓

Gráficos

↓

Histórico

↓

Ações rápidas

---

O usuário deverá compreender a situação geral em menos de um minuto.

---

# Cards

Todos os cards deverão seguir o mesmo padrão.

Título

↓

Valor

↓

Descrição

↓

Ação (quando existir)

---

# Botões

Botão Primário

Executa a principal ação da tela.

Exemplo.

Novo Cliente

Salvar

Cadastrar

Adicionar

---

Botão Secundário

Ações auxiliares.

Exemplo.

Cancelar

Voltar

Exportar

Duplicar

---

Botão de Perigo

Apenas para ações destrutivas.

Excluir

Remover

Cancelar definitivamente

---

# Status

Todos os módulos deverão utilizar as mesmas cores para status.

Ativo

Verde

---

Pausado

Amarelo

---

Concluído

Azul

---

Atrasado

Vermelho

---

Cancelado

Cinza

---

# Prioridades

Urgente

Vermelho

Alta

Laranja

Média

Amarelo

Baixa

Azul

---

# Tabelas

Todas deverão permitir.

Pesquisa

Ordenação

Filtros

Ocultar colunas (futuro)

Exportação (quando aplicável)

---

# Timeline

A Timeline deverá seguir sempre o mesmo padrão.

Data

↓

Hora

↓

Responsável

↓

Evento

↓

Descrição

---

Nunca permitir edição de registros históricos.

---

# Modais

Utilizar modais apenas para ações rápidas.

Exemplos.

Novo Cliente

Nova Tarefa

Novo Objetivo

Novo Processo

Novo Case

---

Cadastros complexos deverão abrir páginas próprias.

---

# Formulários

Todos os formulários deverão seguir a mesma estrutura.

Informações Gerais

↓

Informações Complementares

↓

Observações

↓

Arquivos

---

Campos obrigatórios deverão ser claramente identificados.

---

# Upload de Arquivos

Sempre utilizar o mesmo componente.

Aceitar.

Imagem

Vídeo

PDF

Documento

Áudio

Link

---

Sempre mostrar.

Nome

Tipo

Data

Responsável

---

# Pesquisa

Toda pesquisa deverá funcionar em tempo real.

Sempre posicionada acima da listagem.

---

# Paginação

Quando houver grande volume de registros.

Utilizar paginação.

No futuro poderá ser substituída por scroll infinito.

---

# Dashboard Analítico

Todos os dashboards analíticos deverão possuir.

KPIs

↓

Gráfico de Linha

↓

Gráfico de Barras

↓

Gráfico de Rosca

↓

Tabela

↓

Insights

↓

Drill-down

---

Nunca criar dashboards diferentes para módulos distintos.

---

# Drill-down

Todo gráfico deverá permitir aprofundamento.

Ao clicar.

Abrir.

Tabela

Histórico

Comparações

Observações

---

# Histórico

Todo histórico deverá permitir.

Filtros por período

Comparações

Pesquisa

Exportação (quando aplicável)

---

# Estados Vazios

Quando não existirem registros.

Nunca mostrar tela em branco.

Exemplo.

"Nenhum cliente cadastrado."

[Cadastrar Cliente]

---

# Estados de Carregamento

Utilizar Skeleton Loading.

Nunca bloquear completamente a interface.

---

# Mensagens

Mensagens deverão ser objetivas.

Exemplo.

Cliente salvo com sucesso.

Tarefa concluída.

Processo aplicado.

Nunca utilizar mensagens excessivamente técnicas.

---

# Responsividade

O sistema deverá funcionar integralmente.

Desktop

Notebook

Tablet

Celular

Nenhuma funcionalidade poderá deixar de existir na versão mobile.

Apenas adaptar o layout.

---

# Acessibilidade

Utilizar contraste adequado.

Campos identificados.

Navegação consistente.

Feedback visual para ações.

---

# Componentes Compartilhados

Os seguintes componentes deverão ser reutilizados por toda a plataforma.

Cockpit

Dashboard

KPIs

Timeline

Cards

Tabelas

Filtros

Pesquisa

Upload

Cases

Objetivos

Processos

Checklists

---

# Critérios de Aceite

Este documento será considerado atendido quando.

✓ todas as telas seguirem a mesma estrutura

✓ dashboards utilizarem o mesmo padrão

✓ formulários forem consistentes

✓ componentes forem reutilizados

✓ navegação permanecer previsível

✓ sistema funcionar em desktop e mobile

✓ experiência permanecer consistente em toda a plataforma