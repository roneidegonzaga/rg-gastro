# Ajustes urgentes de baixo risco

> Bloco 2 da "Nova ordem completa" do `Plano_Revisado_Painel_RG_Gastro.md` (posição imediatamente após a Etapa 0). Esse documento não detalha o conteúdo deste bloco em nenhuma seção própria — este arquivo existe para reunir, de forma rastreável, o que foi efetivamente encontrado nas fontes disponíveis, sem completar lacunas por conta própria.
>
> Fontes verificadas (cópias em `_fontes-planejamento/`):
> - `Plano_Revisado_Painel_RG_Gastro.md`
> - `Diagnostico_Tecnico_Painel_RG_Gastro.md`
> - `02_Registro_de_Analise_do_Sistema_de_Gestao.docx`
> - `Quadro_de_Gestao_RG_Gastro.md` (verificado — é um template genérico de gestão de restaurante, sem relação com o Painel RG Gastrô ou com este bloco)

---

## 1. Item confirmado

Único item descrito explicitamente como **"alteração pequena e de baixo risco"** no diagnóstico técnico:

| Item | Fonte | Descrição |
|---|---|---|
| Padronizar o botão de voltar em Clientes e Mentorados | `Diagnostico_Tecnico_Painel_RG_Gastro.md`, item 2.20 (linha 270) | Cursos (`#cu-back`, `app.html:2286,2315`) e Processos (`#pr-back`, `app.html:2625,2684`) já usam o padrão `<button id="X-back">← Y</button>` com `onclick` chamando `go('Y')`. Clientes (`VIEWS.cliente`, `app.html:1673`) e Mentorados (`VIEWS.mentorado`, `app.html:2082`) não têm esse botão — confirmado lendo o código atual do repositório. |

Plano detalhado apresentado separadamente, nesta mesma resposta.

---

## 2. Possíveis candidatos encontrados nas fontes (não confirmados como parte deste bloco)

Nenhum destes foi aprovado para entrar em "Ajustes urgentes de baixo risco" — estão registrados aqui porque apareceram nas fontes descrevendo baixo risco ou baixo esforço, mas nenhum tem a mesma clareza de escopo do item confirmado acima.

| Candidato | Fonte | Observação |
|---|---|---|
| Bug de rolagem da barra lateral no celular (botão Sair inacessível) | `Diagnostico_Tecnico...md`, item 2.9 (linha 169) e observação final (linha 488) | Causa raiz já identificada pelo diagnóstico: a barra usa `height:100vh`, que em navegadores móveis inclui a área atrás da barra de endereço dinâmica; o bloco de usuário/Sair pode ficar fora da área rolável. O próprio diagnóstico sugere empacotar este item com a Etapa 1, "já que você mesma classificou a responsividade mobile como prioridade urgente" — mas isso é uma sugestão do documento, não uma decisão sua registrada. |
| Botão "Definir metas" → "Abrir metas" | `Diagnostico_Tecnico...md`, item na seção de Visão Geral (linha 71) | `app.html:780,864` — hoje abre um modal de edição em vez de navegar para a seção de metas. Classificado como `[Com problema]`, não explicitamente como "baixo risco", mas o diagnóstico o cita junto do bug de rolagem como candidato a pacote pequeno (linha 516). |
| Etapa 10 — Perfil e configurações do usuário | `Diagnostico_Tecnico...md`, seção Etapa 10 (linha 448-456) | Risco classificado como `Baixo`, "sem dependência bloqueante", chamada de "candidata a vitória rápida" (linha 454). Diferente dos itens acima, é uma etapa inteira do roadmap (tela nova de edição de perfil), não um ajuste pontual — por isso listada aqui como candidato de menor confiança, não como equivalente ao item confirmado. |

---

## 3. Lacunas ainda não resolvidas

- Não existe, em nenhuma das quatro fontes, uma lista fechada e nomeada "Ajustes urgentes de baixo risco" — o termo aparece só como posição 2 na ordem do `Plano_Revisado_Painel_RG_Gastro.md`, sem conteúdo próprio.
- A lista "PRIORIDADES IDENTIFICADAS NA ANÁLISE" do `02_Registro_de_Analise_do_Sistema_de_Gestao.docx` (12 itens: Google Agenda, importação Hotmart, exclusão/desfazer importações, filtros de Vendas e Alunos, filtro por período personalizado, status de tarefas, permissões, responsividade mobile, relatórios em PDF, relatórios de acompanhamento, gráficos em relatórios, comunicação interna) **não foi tratada como fonte deste bloco** — cada um desses pontos já corresponde a uma etapa nomeada e maior no plano revisado (Etapa 1A, 2, 3, 4, 6B, 9, 13), não a um ajuste isolado de baixo risco.
- Não há confirmação sobre se o bug de rolagem mobile e o botão "Abrir metas" devem ser tratados agora (empacotados com este bloco ou com a Etapa 1A, como o diagnóstico sugere) ou deixados para a Etapa 13, como estava na ordem original antes da sugestão do diagnóstico.

---

## 4. Itens que exigem aprovação explícita antes de entrar na lista

Nenhum item da seção 2 deve ser implementado sem uma decisão sua específica sobre:
1. Se o bug de rolagem mobile entra neste bloco, na Etapa 1A (como o diagnóstico sugere), ou fica na Etapa 13 (posição original).
2. Se o botão "Abrir metas" entra neste bloco ou é tratado junto da Etapa 5 (Financeiro/Metas/Visão Geral), onde o restante dos problemas da Visão Geral está mapeado.
3. Se a Etapa 10 (Perfil) deve ser antecipada como "vitória rápida" ou seguir na posição original do roadmap.

Até essas decisões, o único item ativo neste bloco é o confirmado na seção 1.
