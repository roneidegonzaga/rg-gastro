# PRD 10 — Clientes

Versão: 1.0
Status: Aprovado

---

# Objetivo

O módulo Clientes é o núcleo operacional da consultoria.

Seu objetivo é concentrar toda a execução do trabalho realizado para cada cliente em um único ambiente.

Todas as informações relacionadas ao cliente deverão permanecer vinculadas ao seu cadastro, permitindo acompanhar a evolução completa da consultoria desde a prospecção até a renovação do contrato.

O sistema deverá eliminar controles paralelos em planilhas, documentos e anotações externas.

---

# Objetivos do Módulo

O módulo deverá permitir.

- gerenciar clientes
- controlar contratos
- acompanhar indicadores
- registrar objetivos
- acompanhar evolução
- aplicar processos
- executar checklists
- registrar visitas
- gerar relatórios
- registrar resultados
- organizar documentos
- acompanhar histórico
- alimentar dashboards
- integrar automaticamente com outros módulos

---

# Estrutura

Clientes

↓

Dashboard

↓

Lista de Clientes

↓

Cockpit

↓

Contratos

↓

Objetivos

↓

Indicadores

↓

Ferramentas

↓

Processos

↓

Checklists

↓

Relatórios

↓

Visitas

↓

Cases

↓

Documentos

↓

Timeline

---

# Dashboard

O Dashboard deverá responder rapidamente.

- Quantos clientes ativos existem?
- Quantos contratos estão próximos do encerramento?
- Qual o Score médio dos clientes?
- Quais clientes precisam de atenção?
- Quais objetivos estão atrasados?
- Quais checklists estão pendentes?
- Quais contratos foram renovados?
- Quais clientes apresentam melhor evolução?

---

# KPIs

Clientes Ativos

Contratos Ativos

Contratos Encerrando

Renovações

Score Médio

Objetivos Concluídos

Processos Ativos

Checklists Pendentes

Todos os KPIs deverão ser clicáveis.

---

# Lista de Clientes

Cada cliente deverá exibir.

Logo

Nome

Cidade

Responsável

Consultor

Origem

Status

Contrato Ativo

Score Geral

Próxima Visita

Dias Restantes do Contrato

---

# Pesquisa

Permitir pesquisar por.

Nome

Cidade

Segmento

Responsável

Consultor

Tags

Origem

---

# Filtros

Todos

Ativos

Pausados

Encerrados

Renovados

Escritório

SEBRAE

Projeto Especial

Período

Personalizado

---

# Cockpit do Cliente

O Cockpit representa a visão executiva daquele cliente.

Ao abrir esta tela o consultor deverá entender rapidamente.

Como está o cliente.

O que precisa ser feito.

Quais resultados foram alcançados.

Quais objetivos ainda faltam.

Quais indicadores precisam de atenção.

---

# Estrutura

Cabeçalho

↓

KPIs

↓

Objetivos

↓

Dashboard Analítico

↓

Pendências

↓

Próxima Visita

↓

Último Relatório

↓

Últimos Cases

↓

Ações Rápidas

---

# Cabeçalho

Logo

Nome

Responsável

Cidade

Status

Origem

Consultor

Score Geral

Dias restantes do contrato

---

# KPIs do Cockpit

Receita

Resultado

CMV

Ticket Médio

Desperdício

Score Geral

Objetivos Concluídos

Processos Ativos

Checklists Pendentes

Última Visita

Próxima Visita

Último Relatório

Todos deverão ser clicáveis.

---

# Ações Rápidas

Novo Relatório

Nova Visita

Novo Objetivo

Novo Processo

Novo Checklist

Nova Ferramenta

Novo Contrato

Novo Case

Abrir Google Drive

Enviar WhatsApp

Enviar E-mail

---

# Cadastro do Cliente

Cada cliente deverá possuir apenas um cadastro.

Todos os contratos ficarão vinculados a esse cadastro.

Nunca duplicar clientes.

---

# Campos

Logo

Nome Fantasia

Razão Social

CNPJ

Inscrição Estadual

Segmento

Cidade

Estado

Endereço

Quantidade de Unidades

Quantidade de Colaboradores

Responsável Principal

Telefone

WhatsApp

E-mail

Instagram

Site

Tags

Observações

---

# Contatos

Cada cliente poderá possuir diversos contatos.

Campos.

Nome

Cargo

Departamento

Telefone

WhatsApp

E-mail

Contato Principal

Observações

---

# Contratos

Cada cliente poderá possuir vários contratos simultaneamente ou em momentos diferentes.

Exemplos.

Diagnóstico

↓

Consultoria

↓

Treinamento

↓

Cardápio

↓

Mentoria

↓

Renovação

Todos permanecerão vinculados ao mesmo cliente.

---

# Cadastro do Contrato

Nome

Origem

Serviço

Valor

Periodicidade

Data Inicial

Data Final

Dia de Pagamento

Quantidade de Parcelas

Recorrente

Consultor Responsável

Status

Observações

---

# Origem

Escritório RG Gastrô

SEBRAE

Projeto Especial

Outro

---

# Serviços

Um contrato poderá possuir diversos serviços.

Exemplo.

Consultoria

+

Cardápio

+

Treinamento

+

Mentoria

---

# Status

Planejado

Ativo

Pausado

Finalizado

Renovado

Cancelado

---

# Renovação

Ao finalizar um contrato.

O sistema deverá perguntar.

Cliente renovou?

SIM

↓

Criar novo período contratual

↓

Gerar novas contas a receber

↓

Atualizar indicador de recorrência

↓

Atualizar dashboards

Nunca apagar contratos anteriores.

---

# Recorrência

Registrar automaticamente.

Quantidade de renovações

Tempo total como cliente

Receita total gerada

Tempo médio de permanência

Tempo médio entre contratos

Esses indicadores alimentarão automaticamente.

Financeiro

↓

Metas

↓

Dashboard Executivo

↓

Visão Geral

---

# Objetivos

Criar uma seção exclusiva chamada Objetivos.

Os Objetivos representam aquilo que o cliente deseja conquistar durante a consultoria.

Eles não se limitam aos entregáveis contratados.

Também representam ganhos estratégicos, financeiros e pessoais.

O consultor deverá registrar esses objetivos logo nas primeiras reuniões e atualizá-los durante toda a consultoria.

---

# Exemplos

Reduzir CMV

Reduzir desperdício

Aumentar faturamento

Aumentar ticket médio

Melhorar margem de lucro

Padronizar processos

Contratar gerente

Contratar equipe

Comprar equipamento

Abrir nova unidade

Melhorar clima da equipe

Ter mais tempo livre

Conseguir tirar férias

Sair da operação

Outro

---

# Cadastro

Cada objetivo possuirá.

Título

Descrição

Categoria

Prioridade

Responsável

Prazo

Status

Valor financeiro (opcional)

Indicador relacionado (opcional)

Observações

---

# Categorias

Financeiro

Operação

Equipe

Equipamentos

Expansão

Marketing

Qualidade

Pessoal

Outro

---

# Prioridade

Urgente

Alta

Média

Baixa

---

# Status

Planejado

Em andamento

Pausado

Concluído

Cancelado

---

# Dashboard dos Objetivos

Mostrar.

Objetivos ativos

Objetivos concluídos

Objetivos atrasados

Objetivos próximos do prazo

Objetivos por categoria

Objetivos por prioridade

Objetivos por responsável

---

# Evolução

Cada objetivo deverá possuir.

Barra de progresso

Percentual

Histórico

Linha do tempo

Comentários

Arquivos relacionados

---

# Integração

Os objetivos poderão ser atualizados automaticamente.

Exemplo.

Meta:

CMV ≤ 32%

↓

Sistema identifica que o indicador foi atingido.

↓

Perguntar ao consultor.

"Deseja concluir este objetivo?"

Nunca concluir automaticamente.

Sempre solicitar confirmação.

---

# Indicadores

Todos os indicadores deverão possuir uma tela própria.

Nunca apresentar apenas o valor atual.

Sempre apresentar evolução.

---

# Indicadores padrão

Receita

CMV

Ticket Médio

Resultado

Margem

Desperdício

Tempo médio de produção

Produção

Outro

---

# Estrutura

Cada indicador possuirá.

Valor Atual

Meta

Gráfico

Histórico

Tabela

Análises

Observações

Arquivos relacionados

---

# Histórico

Todos os indicadores deverão possuir histórico.

Filtros.

30 dias

60 dias

90 dias

6 meses

12 meses

Tudo

Período personalizado

---

# Comparação

Comparar.

Período atual

↓

Período anterior

↓

Mesmo período do ano anterior

---

# Drill-down

Ao clicar em qualquer indicador.

Abrir.

Gráfico completo

Tabela histórica

Comparações

Observações

Insights

Arquivos relacionados

---

# Dashboard Analítico

Todos os dashboards deverão seguir o mesmo padrão.

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

# Score Geral do Cliente

Criar um indicador proprietário chamado Score Geral.

O objetivo é representar, em um único número, a evolução do cliente durante toda a consultoria.

Esse Score deverá aparecer em destaque no Cockpit.

---

# Estrutura

Pontuação

0 a 100

Classificação.

Excelente

Muito bom

Bom

Atenção

Crítico

---

# Pesos iniciais

Resultado Financeiro

20%

CMV

20%

Desperdício

15%

Checklists

15%

Objetivos concluídos

10%

Processos concluídos

10%

Indicadores personalizados

10%

Os pesos deverão ser configuráveis futuramente.

---

# Histórico do Score

Mostrar.

Linha temporal

Filtros

Comparação

Evolução

Nunca sobrescrever históricos.

---

# Dashboard do Score

Mostrar.

Maior evolução

Maior queda

Clientes estáveis

Ranking geral

Distribuição dos Scores

---

# Inteligência Artificial

Quando ocorrer redução significativa do Score.

Gerar automaticamente.

Resumo

Possíveis causas

Indicadores relacionados

Sugestões de investigação

Nunca alterar o Score.

Apenas interpretar os dados.

---

# Biblioteca de Ferramentas

Criar uma seção exclusiva.

Toda ferramenta utilizada durante a consultoria ficará registrada aqui.

---

# Estrutura

Ferramentas D.O.S.E.

↓

Ferramentas PEC

↓

Ferramentas Personalizadas

---

# Cadastro

Nome

Categoria

Descrição

Versão

Status

Indicadores relacionados

Responsável

Observações

---

# Ferramentas D.O.S.E.

Todas as ferramentas HTML deverão alimentar automaticamente os indicadores.

Nunca exigir preenchimento duplicado.

---

# Ferramentas PEC

As ferramentas do PEC poderão ser convertidas para HTML.

Após a conversão.

Passarão a alimentar automaticamente.

Indicadores

↓

Dashboard

↓

Score

↓

Relatórios

↓

Objetivos

---

# Dashboard das Ferramentas

Mostrar.

Ferramentas utilizadas

Ferramentas pendentes

Ferramentas obrigatórias

Ferramentas personalizadas

Última atualização

---

# Integração das Ferramentas

Toda ferramenta deverá informar automaticamente.

Indicadores

↓

Dashboard

↓

Score

↓

Objetivos relacionados

↓

Relatórios

↓

Cases (quando houver resultado relevante)

---

# Cases Automáticos

Quando um indicador apresentar evolução significativa.

Exemplo.

CMV

38%

↓

29%

O sistema poderá sugerir.

"Deseja registrar este resultado como um Case?"

Ao confirmar.

Criar automaticamente um rascunho contendo.

Cliente

Período

Indicador

Gráfico antes/depois

Consultor responsável

O consultor apenas complementará.

Descrição

Fotos

Vídeos

Links

Benefícios

Tags

Autorização

Esse recurso deverá reduzir o tempo necessário para transformar resultados em provas sociais.

---

# Processos

Criar uma seção exclusiva chamada Processos.

O objetivo é padronizar toda a execução da consultoria.

Nenhum processo será criado diretamente dentro do cliente.

Todos os processos deverão ser originados da Biblioteca de Processos da Empresa.

---

# Biblioteca

Os processos serão cadastrados uma única vez.

Ao aplicar um processo ao cliente.

O sistema deverá gerar automaticamente.

Checklist

↓

Tarefas

↓

Prazos

↓

Responsáveis

↓

Documentos sugeridos

↓

Indicadores relacionados

Nunca exigir cadastro repetitivo.

---

# Exemplos

Onboarding

Diagnóstico

Boas Práticas

Cardápio

Treinamento

Implantação

Encerramento

Personalizado

---

# Estrutura

Nome

Categoria

Descrição

Checklist associado

Tarefas associadas

Indicadores relacionados

Prazo padrão

Versão

Responsável

Status

---

# Dashboard

Mostrar.

Processos ativos

Concluídos

Atrasados

Tempo médio

Processos por categoria

---

# Checklists

Checklist representa auditoria.

Tarefa representa execução.

Nunca misturar os dois conceitos.

---

# Checklists padrão

RDC

Boas Práticas

Produção

Estoque

Equipamentos

Segurança Alimentar

Layout

Cardápio

Personalizado

---

# Estrutura

Cada item deverá possuir.

Descrição

Categoria

Conforme

Não Conforme

Não se Aplica

Observações

Fotos

Vídeos (opcional)

Arquivos

Responsável

Data

---

# Evidências

Cada item poderá receber.

Imagem

Vídeo

PDF

Documento

Link

Não limitar quantidade de evidências.

---

# Inteligência Artificial

Após finalizar um checklist.

Gerar automaticamente.

Resumo Executivo

Principais Não Conformidades

Prioridades

Sugestões

Texto inicial do relatório

A IA nunca poderá alterar respostas do consultor.

---

# Dashboard dos Checklists

Mostrar.

Quantidade

Conformes

Não Conformes

Não se Aplica

Última auditoria

Evolução

---

# Cases

Criar um módulo chamado Cases.

Cases representam resultados relevantes obtidos durante a consultoria.

Um Case poderá ou não se tornar uma prova social.

Essa decisão pertence ao consultor.

---

# Objetivo

Organizar todo o histórico de resultados relevantes do cliente.

Também servir como biblioteca de provas sociais.

---

# Estrutura

Cases

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

# Cadastro

Título

Descrição

Categoria

Data

Indicador relacionado

Objetivo relacionado

Relatório relacionado

Consultor

Observações

---

# Galeria

Aceitar.

Imagens

Vídeos

Áudios

PDFs

Documentos

---

# Links

Instagram

Reels

Stories

YouTube

Google Drive

Outro

---

# Benefícios

Registrar.

Redução do CMV

Redução do desperdício

Aumento do ticket médio

Aumento do faturamento

Compra de equipamento

Contratação de equipe

Padronização

Nova unidade

Mais tempo livre para o empresário

Outro

---

# Tags

Permitir múltiplas tags.

Exemplo.

CMV

Desperdício

Equipe

Treinamento

Layout

Cardápio

Financeiro

Boas Práticas

---

# Favoritos

Qualquer Case poderá ser marcado como Favorito.

Permitir pesquisa.

Mostrar apenas Favoritos.

---

# Autorizações

Cada Case deverá possuir controle individual.

Uso interno

Redes sociais

Anúncios

Cursos

Palestras

Sem autorização

---

# Dashboard dos Cases

Mostrar.

Quantidade de Cases

Quantidade de Favoritos

Categorias

Benefícios

Resultados por período

Indicadores relacionados

---

# Pesquisa

Permitir pesquisar por.

Cliente

Categoria

Indicador

Benefício

Tag

Período

Consultor

Autorização

---

# Relatórios

Criar um módulo independente.

Tipos.

Mensal

Parcial

Final

Livre

---

# Editor

Permitir inserir.

Texto

Imagem

Tabela

Indicadores

Gráficos

Fotos

Cases

Objetivos

Checklists

---

# Integração

O relatório poderá importar automaticamente.

Indicadores

↓

Gráficos

↓

Cases

↓

Objetivos

↓

Checklists

↓

Timeline

Sem necessidade de copiar informações manualmente.

---

# PDF

Todo relatório deverá gerar PDF.

Com.

Logo RG Gastrô

Logo do Cliente

Cabeçalho

Rodapé

Numeração

---

# Assinatura

Permitir assinatura digital.

Cliente

Consultor

Tablet

Mouse

Touch

---

# Visitas

Cada visita deverá possuir.

Data

Hora inicial

Hora final

Consultor

Participantes

Resumo

Pendências

Próximos passos

Fotos

Arquivos

Observações

---

# Timeline

Toda movimentação deverá ficar registrada automaticamente.

Eventos.

Cadastro

Contratos

Objetivos

Indicadores

Processos

Checklists

Cases

Relatórios

Visitas

Documentos

Atualizações

Nunca permitir edição da Timeline.

---

# Documentos

Organizar.

Contratos

Relatórios

Ferramentas

PDFs

Google Drive

Fotos

Vídeos

Arquivos

---

# Inteligência Artificial

Criar um Cockpit de IA.

A IA poderá.

Interpretar indicadores

Relacionar Cases

Relacionar Objetivos

Explicar evolução

Sugerir prioridades

Gerar resumo executivo

Gerar primeira versão dos relatórios

Nunca alterar informações cadastradas.

Sempre atuar como assistente.

---

# Permissões

Administradores.

Acesso total.

Consultores.

Clientes atribuídos.

Equipe.

Módulos autorizados.

---

# Banco Lógico

Cliente

↓

Contratos

↓

Objetivos

↓

Indicadores

↓

Ferramentas

↓

Processos

↓

Checklists

↓

Cases

↓

Relatórios

↓

Visitas

↓

Documentos

↓

Timeline

↓

Dashboard

↓

Score Geral

---

# Integrações

CRM

Financeiro

Metas

Agenda

Projetos e Tarefas

Biblioteca de Processos

Biblioteca de Ferramentas

Inteligência Artificial

Visão Geral

---

# Critérios de Aceite

O módulo Clientes será considerado concluído quando.

✓ possuir Cockpit completo

✓ possuir Score Geral

✓ possuir Objetivos

✓ possuir indicadores históricos

✓ possuir Dashboard Analítico

✓ aceitar múltiplos contratos

✓ aceitar múltiplos serviços por contrato

✓ controlar recorrência

✓ calcular renovações

✓ possuir Biblioteca D.O.S.E.

✓ possuir Biblioteca PEC

✓ atualizar indicadores automaticamente

✓ possuir Processos

✓ gerar Checklists automaticamente

✓ aceitar fotos e evidências

✓ gerar análises por IA

✓ possuir módulo Cases

✓ possuir Dashboard dos Cases

✓ controlar autorizações de uso

✓ gerar relatórios completos

✓ exportar PDF

✓ permitir assinatura digital

✓ manter Timeline completa

✓ integrar-se automaticamente aos demais módulos

✓ funcionar em desktop e mobile