# PRD 09 — Componentes Reutilizáveis

Versão: 1.0
Status: Aprovado

---

# Objetivo

Este documento define todos os componentes reutilizáveis do Painel RG Gastrô.

Seu objetivo é garantir consistência visual, funcional e arquitetural em toda a plataforma.

Sempre que um módulo precisar de uma funcionalidade já existente, deverá reutilizar o componente definido neste documento, nunca criar uma nova versão.

---

# Componentes

O sistema possuirá os seguintes componentes reutilizáveis.

- Cockpit
- Dashboard
- KPIs
- Objetivos
- Timeline
- Cases
- Processos
- Checklists
- Biblioteca de Ferramentas
- Upload
- Pesquisa
- Filtros
- Inteligência Artificial

---

# Cockpit

## Objetivo

O Cockpit é a tela principal de um módulo.

Seu papel é responder rapidamente ao usuário:

- Como está esta área?
- O que exige minha atenção?
- Quais são os próximos passos?

---

## Estrutura

Cabeçalho

↓

KPIs

↓

Dashboard

↓

Pendências

↓

Histórico

↓

Ações rápidas

---

## Utilização

O Cockpit será utilizado em:

- Visão Geral
- Clientes
- Mentorados

Futuramente poderá ser utilizado em outros módulos.

---

## Regras

Sempre apresentar:

- principais indicadores
- resumo da situação
- tarefas prioritárias
- próximos compromissos
- atalhos

Nunca substituir a tela completa do módulo.

Seu papel é resumir.

---

# Dashboard

## Objetivo

Todo Dashboard deverá transformar dados em informação útil para tomada de decisão.

Nunca deverá existir apenas para exibir gráficos.

---

## Estrutura

KPIs

↓

Gráficos

↓

Tabela

↓

Insights

↓

Drill-down

---

## KPIs

Sempre posicionados acima dos gráficos.

Todo KPI deverá ser clicável.

Ao clicar.

Abrir detalhamento.

---

## Filtros

Todos os dashboards deverão responder aos mesmos filtros.

Hoje

7 dias

30 dias

60 dias

90 dias

12 meses

Personalizado

Quando aplicável.

Categoria

Responsável

Status

Origem

Produto

Centro de Resultado

---

## Drill-down

Todo gráfico deverá permitir aprofundamento.

Abrir.

Tabela

↓

Histórico

↓

Comparações

↓

Observações

↓

Arquivos relacionados

---

# Objetivos

## Objetivo

Representam resultados que se deseja alcançar.

Não representam tarefas.

---

## Estrutura

Título

Descrição

Categoria

Responsável

Prazo

Status

Prioridade

Indicador relacionado

Observações

---

## Dashboard

Objetivos ativos

Concluídos

Atrasados

Próximos do prazo

Categorias

Prioridades

---

# Timeline

## Objetivo

Registrar automaticamente todos os acontecimentos relevantes.

Nunca depender de preenchimento manual.

---

## Estrutura

Data

Hora

Responsável

Evento

Descrição

---

## Eventos

Cadastro

Atualização

Visita

Relatório

Checklist

Processo

Objetivo

Case

Documento

Sessão

Contrato

---

# Cases

## Objetivo

Registrar resultados relevantes.

Cases poderão ser utilizados como provas sociais, materiais de marketing, apresentações, aulas e acompanhamento interno.

---

## Estrutura

Cadastro

↓

Galeria

↓

Links

↓

Benefícios

↓

Tags

↓

Favoritos

↓

Autorizações

↓

Dashboard

---

## Cadastro

Título

Descrição

Categoria

Data

Origem

Indicador relacionado

Objetivo relacionado

Observações

---

## Galeria

Aceitar.

Imagem

Vídeo

Áudio

PDF

Documento

---

## Benefícios

Permitir registrar.

Financeiros

Operacionais

Equipe

Marketing

Expansão

Pessoais

Personalizados

---

## Tags

Permitir múltiplas tags.

---

## Favoritos

Permitir marcação individual.

---

## Autorizações

Uso interno

Redes sociais

Anúncios

Cursos

Palestras

Sem autorização

---

## Pesquisa

Pesquisar por.

Categoria

Benefício

Tag

Período

Origem

Autorização

---

# Processos

## Objetivo

Padronizar atividades recorrentes.

Todos os processos deverão nascer na Biblioteca de Processos.

Nunca diretamente nos módulos.

---

## Estrutura

Nome

Categoria

Descrição

Checklist

Tarefas

Prazo

Versão

Responsável

---

## Aplicação

Ao aplicar um processo.

Gerar automaticamente.

Checklist

↓

Tarefas

↓

Prazos

↓

Responsáveis

↓

Documentos sugeridos

---

# Checklists

## Objetivo

Realizar auditorias e verificações.

Não substituir tarefas.

---

## Estrutura

Descrição

Categoria

Conforme

Não conforme

Não se aplica

Observações

Fotos

Vídeos

Arquivos

Responsável

Data

---

## Inteligência Artificial

Após conclusão.

Gerar automaticamente.

Resumo

Prioridades

Não conformidades

Sugestões

Texto inicial para relatório

---

# Biblioteca de Ferramentas

## Objetivo

Centralizar todas as ferramentas utilizadas pela empresa.

---

## Estrutura

Ferramentas D.O.S.E.

↓

Ferramentas PEC

↓

Ferramentas Personalizadas

---

## Integração

Sempre que possível.

Ferramentas deverão alimentar automaticamente.

Indicadores

↓

Dashboards

↓

Objetivos

↓

Relatórios

↓

Cases

---

# Upload

## Objetivo

Padronizar envio de arquivos.

Aceitar.

Imagem

Vídeo

Áudio

PDF

Documento

Planilha

Link

---

## Exibir

Nome

Tipo

Data

Responsável

---

# Pesquisa

Todo módulo deverá possuir pesquisa.

Funcionamento.

Tempo real

Pesquisa parcial

Pesquisa por tags

Pesquisa por filtros

---

# Inteligência Artificial

## Objetivo

A IA será um componente compartilhado.

Sua função será acelerar o trabalho do usuário.

Nunca substituir decisões humanas.

---

## Poderá

Interpretar indicadores

Gerar resumos

Sugerir prioridades

Relacionar informações

Gerar textos iniciais

Explicar históricos

Detectar padrões

---

## Nunca poderá

Alterar cadastros automaticamente

Excluir registros

Modificar indicadores

Executar ações sem confirmação do usuário

---

# Regras Gerais

Todos os componentes deverão.

- manter identidade visual consistente
- respeitar permissões
- responder aos filtros
- funcionar em desktop e mobile
- permitir evolução futura
- evitar duplicação de código
- evitar duplicação de interface

---

# Critérios de Aceite

Este documento será considerado atendido quando.

✓ todos os módulos reutilizarem os componentes definidos

✓ não existirem componentes duplicados

✓ toda a interface permanecer consistente

✓ todos os dashboards seguirem o mesmo padrão

✓ todos os cockpits seguirem o mesmo padrão

✓ processos e checklists forem reutilizáveis

✓ a IA funcionar como componente compartilhado

✓ a plataforma permanecer preparada para crescimento futuro