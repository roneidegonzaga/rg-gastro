# PRD 30 — Regras de Desenvolvimento

Versão: 1.0
Status: Obrigatório

---

# Objetivo

Este documento define as regras obrigatórias para qualquer desenvolvimento realizado no Painel RG Gastrô.

Seu objetivo é garantir consistência, qualidade, escalabilidade e evitar retrabalho.

Toda implementação deverá seguir este documento.

Nenhuma exceção deverá ser feita sem atualização prévia da documentação.

---

# Princípios

Todo desenvolvimento deverá seguir.

• simplicidade

• reutilização

• escalabilidade

• consistência

• previsibilidade

• performance

• segurança

---

# Antes de Implementar

Antes de escrever qualquer código.

Responder obrigatoriamente.

Existe um PRD?

Existe um módulo relacionado?

Existe um componente semelhante?

Existe uma entidade semelhante?

Existe uma automação semelhante?

Existe integração necessária?

Existe impacto em outro módulo?

Se alguma resposta for SIM.

Reutilizar.

Nunca criar uma segunda solução.

---

# Fonte de Verdade

Sempre utilizar.

Banco de Dados

↓

Serviços

↓

Componentes

↓

Interface

Nunca inverter essa ordem.

---

# Regras de Banco

Nunca criar.

Entidades duplicadas.

Históricos duplicados.

Timelines duplicadas.

Categorias duplicadas.

Tags duplicadas.

Relacionamentos paralelos.

Sempre utilizar o Documento 25.

---

# Regras de Interface

Toda tela deverá possuir.

Título

Pesquisa (quando aplicável)

Filtros (quando aplicável)

Dashboard (quando aplicável)

Responsividade

Estados de carregamento

Estados vazios

Tratamento de erro

Nunca criar páginas fora desse padrão.

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

Todos responderão aos filtros.

---

# Formulários

Todo formulário deverá possuir.

Validação

Mensagens claras

Máscaras (quando necessário)

Feedback visual

Tratamento de erro

Confirmação de sucesso

---

# Componentes

Antes de criar um componente.

Verificar se já existe.

Botão

Card

Modal

Input

Tabela

Filtro

Upload

Timeline

Dashboard

KPI

Nunca duplicar componentes.

---

# Layout

Sempre utilizar.

Layout principal

↓

Sidebar

↓

Header

↓

Área de conteúdo

↓

Rodapé (quando necessário)

Nunca criar layouts diferentes para módulos semelhantes.

---

# Regras de Backend

Toda regra de negócio deverá permanecer no Backend.

Nunca implementar.

Cálculos

Permissões

Automações

Integrações

Regras comerciais

No Frontend.

---

# APIs

Toda comunicação deverá ocorrer por APIs.

Nunca acessar banco diretamente pelo Frontend.

---

# Logs

Registrar sempre.

Importações

Exportações

Automações

Integrações

Erros

Alterações críticas

Nunca ocultar erros silenciosamente.

---

# Timeline

Sempre registrar.

Criação

Atualização

Mudança de status

Conclusão

Cancelamento

Nunca apagar registros da Timeline.

---

# Permissões

Toda funcionalidade deverá validar permissões.

Frontend

↓

Backend

Nunca confiar apenas na interface.

---

# Responsividade

Toda funcionalidade deverá funcionar em.

Desktop

Notebook

Tablet

Celular

Nenhuma funcionalidade poderá existir apenas para desktop.

---

# Performance

Sempre priorizar.

Paginação

Lazy Loading

Consultas otimizadas

Componentes reutilizáveis

Cache (quando necessário)

---

# Inteligência Artificial

A IA poderá.

Interpretar

Resumir

Comparar

Explicar

Sugerir

Nunca poderá.

Excluir registros

Alterar dados automaticamente

Executar ações críticas

Modificar regras de negócio

---

# Código

Todo código deverá ser.

Legível

Modular

Reutilizável

Documentado quando necessário

Evitar comentários desnecessários.

O código deve explicar sua própria intenção.

---

# Nomeação

Utilizar nomes claros.

Evitar abreviações.

Exemplo.

ClienteService

ProjetoRepository

CreateTaskUseCase

Nunca utilizar nomes genéricos como.

Utils2

ServiceNovo

TesteFinal

---

# Integrações

Toda integração deverá.

Possuir tratamento de erro

Registrar logs

Permitir reprocessamento

Nunca interromper o sistema em caso de falha.

---

# Testes

Toda funcionalidade deverá ser validada antes da entrega.

Verificar.

Fluxo principal

Fluxos alternativos

Permissões

Responsividade

Integrações

Automações

---

# Refatoração

Antes de criar código novo.

Perguntar.

Existe algo que pode ser reutilizado?

Se SIM.

Refatorar.

Nunca duplicar lógica.

---

# O que Nunca Fazer

Nunca.

Criar módulos fora dos PRDs.

Criar componentes duplicados.

Criar entidades duplicadas.

Criar APIs desnecessárias.

Criar regras de negócio no Frontend.

Ignorar permissões.

Ignorar logs.

Ignorar Timeline.

Ignorar documentação.

---

# Definição de Pronto

Uma funcionalidade somente será considerada pronta quando.

✓ atender ao PRD

✓ respeitar a Arquitetura Técnica

✓ respeitar o Banco de Dados

✓ respeitar o Design System

✓ possuir tratamento de erros

✓ possuir responsividade

✓ respeitar permissões

✓ integrar corretamente com os demais módulos

✓ registrar Timeline quando aplicável

✓ registrar Logs quando aplicável

✓ não gerar duplicação de código

✓ não gerar duplicação de componentes

✓ não gerar duplicação de entidades

---

# Regra Final

Sempre priorizar qualidade de arquitetura em vez de velocidade de implementação.

Código pode ser reescrito.

Arquitetura mal planejada custa caro durante toda a vida do projeto.