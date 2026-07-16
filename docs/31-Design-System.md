# PRD 31 — Design System

Versão: 1.0
Status: Aprovado

---

# Objetivo

Este documento define os padrões visuais e de experiência do usuário do Painel RG Gastrô.

Seu objetivo é garantir consistência visual, previsibilidade e escalabilidade da interface.

Nenhuma tela deverá ser construída sem seguir este Design System.

---

# Princípios

Toda interface deverá transmitir.

• clareza

• simplicidade

• velocidade

• organização

• profissionalismo

• consistência

O sistema deverá parecer uma única aplicação, nunca um conjunto de telas diferentes.

---

# Identidade Visual

O design deverá seguir uma estética moderna, limpa e minimalista.

Referências.

Linear

Notion

Vercel

Stripe Dashboard

Supabase

GitHub

O objetivo não é copiar essas interfaces, mas utilizar os mesmos princípios de organização e legibilidade.

---

# Stack de Interface

Componentes

shadcn/ui

Estilização

Tailwind CSS

Ícones

Lucide React

Gráficos

Recharts

Tabelas

TanStack Table

---

# Layout Geral

Toda página seguirá a estrutura.

Header

↓

Título

↓

Descrição (quando necessária)

↓

Barra de ações

↓

KPIs (quando aplicável)

↓

Filtros

↓

Conteúdo

---

Nunca inverter essa ordem sem justificativa.

---

# Grid

Desktop

12 colunas

Tablet

8 colunas

Mobile

1 coluna

Todo layout deverá ser responsivo.

---

# Espaçamentos

Utilizar múltiplos de 4.

4

8

12

16

20

24

32

40

48

64

Nunca utilizar espaçamentos arbitrários.

---

# Bordas

Cards

12px

Inputs

10px

Botões

10px

Modais

16px

Manter consistência em toda a aplicação.

---

# Sombras

Utilizar sombras discretas.

Priorizar profundidade através de espaçamento.

Nunca utilizar sombras pesadas.

---

# Tipografia

Fonte principal.

Inter

Hierarquia.

H1

H2

H3

Título de Card

Texto

Legenda

Nunca utilizar mais de uma família tipográfica.

---

# Cores

As cores deverão utilizar tokens.

Nunca utilizar valores HEX diretamente nos componentes.

Categorias.

Primária

Secundária

Sucesso

Aviso

Erro

Informação

Neutras

As cores reais serão definidas pelo tema.

---

# Modo Escuro

Toda interface deverá funcionar em.

Modo Claro

↓

Modo Escuro

Nenhum componente poderá existir apenas em um dos modos.

---

# Botões

Tipos.

Primário

Secundário

Outline

Ghost

Link

Destrutivo

Estados.

Normal

Hover

Focus

Disabled

Loading

---

# Inputs

Todos os formulários deverão utilizar componentes padronizados.

Texto

Número

Data

Select

MultiSelect

Textarea

Checkbox

Radio

Switch

Upload

Busca

Nunca criar inputs personalizados sem necessidade.

---

# Cards

Todo card deverá possuir.

Título

Conteúdo

Espaçamento interno

Ações (quando necessário)

Os cards deverão ser reutilizáveis.

---

# KPIs

Todos os KPIs seguirão o mesmo padrão.

Título

Valor

Variação

Ícone

Clique

Nunca alterar esse layout entre módulos.

---

# Dashboards

Todo Dashboard deverá possuir.

KPIs

↓

Gráficos

↓

Tabela

↓

Insights

↓

Drill-down

Sempre nessa ordem.

---

# Tabelas

Toda tabela deverá possuir.

Pesquisa

Filtros

Ordenação

Paginação

Colunas configuráveis (futuro)

Exportação (quando aplicável)

---

# Formulários

Todo formulário deverá possuir.

Título

Descrição (quando necessário)

Campos agrupados

Mensagens de validação

Botões de ação

Nunca criar formulários longos sem agrupamento lógico.

---

# Modais

Utilizar modais apenas para ações rápidas.

Nunca colocar processos longos dentro de modais.

---

# Drawer

Utilizar Drawer para.

Detalhes

Visualização rápida

Edição simples

---

# Navegação

Sidebar fixa.

Header superior.

Breadcrumb.

Pesquisa Global.

Nunca utilizar menus diferentes em módulos diferentes.

---

# Estados

Toda tela deverá possuir.

Loading

↓

Empty State

↓

Erro

↓

Sucesso

Nunca deixar áreas vazias sem contexto.

---

# Empty State

Toda tela vazia deverá explicar.

O que é esta área.

Por que está vazia.

Qual a próxima ação do usuário.

---

# Feedback

Toda ação deverá gerar feedback.

Sucesso

Erro

Aviso

Informação

Utilizar Toasts para ações rápidas.

---

# Ícones

Utilizar apenas Lucide React.

Nunca misturar bibliotecas diferentes.

---

# Animações

As animações deverão ser discretas.

Priorizar.

Fade

Scale

Slide

Evitar animações longas.

---

# Acessibilidade

Garantir.

Contraste adequado.

Navegação por teclado.

Labels.

ARIA.

Focus visível.

---

# Responsividade

Desktop

Notebook

Tablet

Celular

Nenhuma funcionalidade poderá desaparecer em telas menores.

Apenas reorganizar a interface.

---

# Consistência

Se um componente existir em um módulo.

Ele deverá possuir exatamente o mesmo comportamento em todos os demais.

---

# Evolução

Novos componentes somente poderão ser criados quando realmente não existir um componente reutilizável equivalente.

Sempre priorizar reutilização.

---

# Critérios de Aceite

Este documento será considerado atendido quando.

✓ todas as telas utilizarem o mesmo padrão visual

✓ todos os componentes forem reutilizáveis

✓ todos os dashboards seguirem a mesma estrutura

✓ todos os formulários seguirem o mesmo padrão

✓ todos os KPIs seguirem o mesmo layout

✓ toda a plataforma funcionar em modo claro e escuro

✓ toda a plataforma for responsiva

✓ toda a plataforma atender aos requisitos de acessibilidade

✓ toda a experiência do usuário permanecer consistente