# Proposta de preview da Vercel (Checkpoint 0.8) — revisada em 31/07/2026

**Nada aqui foi executado.** Esta versão substitui o rascunho anterior, escrito antes do schema DEV existir — a análise de hoje encontrou um bloqueio real que o rascunho anterior não tinha identificado, e corrige uma afirmação que se mostrou incorreta ao verificar o código.

## ⚠ Bloqueio real identificado antes de qualquer outra coisa

**Este repositório não tem remoto Git configurado** (`git remote -v` vazio, confirmado agora). A forma padrão de Preview da Vercel — vinculada a um push de branch — depende de a Vercel enxergar o repositório via GitHub/GitLab/Bitbucket. Sem um remoto, e sem autorização para `git push` (proibido pelas suas regras gerais desde o início desta etapa), **esse caminho não está disponível hoje.**

Existem duas rotas possíveis. Nenhuma foi executada — é uma decisão sua.

| Rota | Como funciona | O que exige |
|---|---|---|
| **A — Integração Git** | Conectar este repositório a um remoto (GitHub, por exemplo) e deixar a Vercel observar a branch `desenvolvimento`; todo push nela gera um Preview automaticamente | Criar o remoto + autorizar explicitamente um `git push` — hoje fora de escopo, exigiria você revisitar essa regra |
| **B — Vercel CLI local** | Rodar `vercel deploy` (sem `--prod`) direto da pasta local, sem depender de nenhum remoto Git | Instalar e autenticar a Vercel CLI localmente — ferramenta que não tenho nesta sessão; precisa da sua aprovação explícita para eu instalar algo, ou você mesma roda |

## Correção importante em relação ao rascunho anterior

O rascunho anterior deste documento dizia que o ambiente apareceria identificado visualmente através de `NOME_SISTEMA`/`NOME_SUB` do `config.js`. **Isso estava errado — verifiquei agora e nem `app.html` nem `index.html` usam esses dois campos em lugar nenhum.** A marca "RG Gastrô" está escrita direto no HTML (texto fixo e SVG), não é dinâmica. Ou seja: hoje, preencher `NOME_SISTEMA`/`NOME_SUB` no `config.dev.js` não muda nada visível na tela.

Duas formas honestas de resolver isso:
1. **Sem tocar no código** (recomendado para agora): confiar na própria **URL do preview**, que a Vercel gera automaticamente e é visivelmente diferente do domínio de produção (`painel.roneidegonzaga.com`) — isso já é um sinal visual forte, só olhando a barra de endereço, sem precisar de nenhuma mudança em `app.html`/`index.html`.
2. **Com uma pequena mudança de código** (fora do escopo da Etapa 0, exigiria aprovação própria): fazer `app.html`/`index.html` exibirem um aviso ou trocarem o título com base em algum indicador de ambiente. Não recomendo fazer isso agora — é alteração funcional do sistema, e a Etapa 0 foi definida desde o início como "não altere a lógica funcional de `app.html`".

## O que precisa ser configurado na Vercel (independente da rota escolhida)

Como o projeto **não tem etapa de build** (é HTML/CSS/JS puro, servido como está), variáveis de ambiente configuradas no painel da Vercel **não são injetadas automaticamente** em `config.js` — não existe nenhum passo de build que faça essa substituição hoje. Isso muda a proposta original: em vez de "variáveis de ambiente na Vercel", a forma que realmente funciona com a arquitetura atual é **o próprio arquivo `config.js` ter conteúdo diferente por branch**:

- Branch de produção (a que a Vercel já usa hoje) → `config.js` com as credenciais reais de produção, exatamente como já está
- Branch `desenvolvimento` → `config.js` com as credenciais do projeto `rg-gastro-DEV`

Como a Vercel publica cada branch com o conteúdo que está *naquela branch*, isso garante isolamento por construção — não é uma lógica condicional que possa falhar, é literalmente um arquivo diferente.

## Como garantir que o preview use exclusivamente o Supabase DEV

Só existe um `config.js` por branch — não há dois valores concorrendo, não há lógica de "qual usar". Sem etapa de build, sem variável de ambiente, sem `if`. O `config.js` da branch `desenvolvimento` conteria diretamente os valores do projeto DEV.

## Como impedir fallback para produção

Por construção, não existe fallback possível nesse modelo — não há um valor "padrão" para o qual o código possa recorrer se algo estiver ausente; o arquivo simplesmente contém um valor ou outro, nunca os dois. O único risco real é **erro humano**: alguém copiar o `config.js` errado para a branch errada. Mitigação proposta: nunca copiar `config.js` entre as branches manualmente — sempre usar `config.dev.js` (que já existe, local, fora do Git) como a única fonte dos valores de desenvolvimento, e só então decidir (ver "Decisão pendente" abaixo) se ele deve ou não ser promovido a `config.js` na branch `desenvolvimento`.

## ⚠ Trade-off sobre onde a credencial DEV fica registrada — decisão pendente

Se a `config.js` da branch `desenvolvimento` passar a conter os valores do projeto DEV, isso significa **commitar a URL e a chave anônima do projeto DEV no histórico do Git local** (não no de produção, e sem nenhum push, mas ainda assim fora do padrão de "nenhuma credencial no Git" que seguimos até aqui).

Duas coisas atenuam esse risco, mas não o eliminam:
- A **chave anônima (publishable key)** do Supabase é projetada, por padrão, para ser pública em código de frontend — a segurança real vem do RLS no banco, não de esconder essa chave. É uma categoria de credencial bem menos sensível que a `service_role key` ou a senha do Postgres.
- Nada disso sai do seu computador enquanto não houver `push` para um remoto.

Ainda assim, é uma mudança de padrão em relação ao que fizemos até aqui, e por isso não decidi sozinho: **prefere que eu prepare o `config.js` da branch `desenvolvimento` com os valores do DEV (copiando localmente de `config.dev.js`, sem exibir nada aqui), ou prefere manter os dois arquivos fora do Git e resolver isso de outra forma (ex.: só depois de decidir a Rota A ou B acima)?**

## Arquivos locais que precisarão ser ajustados (quando autorizado)

| Arquivo | Ajuste |
|---|---|
| `config.js` (só na branch `desenvolvimento`) | Substituído pelo conteúdo de `config.dev.js` — só depois da decisão acima |
| Nenhum outro arquivo do projeto | `app.html`/`index.html` não precisam de nenhuma alteração para esse esquema funcionar, exatamente porque não há lógica condicional nova — só o conteúdo do `config.js` muda por branch |

## Riscos

- Bloqueio de infraestrutura (sem remoto) precisa ser resolvido antes de qualquer preview real existir — rota A ou B, ambas fora do escopo já autorizado até agora
- Rota B exige instalar uma ferramenta nova (Vercel CLI) — sujeita à regra de sempre apresentar a necessidade antes
- Commitar a chave anônima DEV no `config.js` da branch de desenvolvimento é uma mudança de padrão, ainda que de risco relativamente baixo (ver acima)
- Erro humano ao copiar `config.js` entre branches — mitigado por nunca fazer isso manualmente, só a partir de `config.dev.js`

## Testes (a fazer só depois de um preview real existir — não agora)

- Abrir a URL de preview e confirmar visualmente que o domínio é diferente do de produção
- Inspecionar a aba de rede do navegador (sem registrar nada sensível) e confirmar que as chamadas de API vão para o domínio do projeto `rg-gastro-DEV`, nunca para o de produção
- Confirmar que a branch de produção continua publicando com as credenciais de produção, sem nenhuma interferência

## Rollback

- Reverter o `config.js` da branch `desenvolvimento` para um estado anterior (ou removê-lo do rastreamento) não afeta produção em nenhum cenário, já que produção vive só na branch/config próprios, nunca tocados nesta etapa
- Um deploy de preview feito via Vercel CLI pode ser removido diretamente no painel da Vercel (ação da sua conta, não local)

---

**Nada foi configurado ainda.** Aguardando decisão sobre: (1) Rota A ou B para viabilizar o preview; (2) se o `config.js` da branch `desenvolvimento` deve ou não receber os valores DEV agora.
