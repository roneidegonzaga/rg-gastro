# Preview da Vercel (Checkpoint 0.8) — decisões tomadas em 31/07/2026

**Nada aqui foi publicado, conectado ou implantado.** Este documento substitui as duas versões anteriores — as decisões abaixo já foram aprovadas, mas a execução (criar remoto, dar push, criar projeto na Vercel, configurar variáveis) continua pendente de autorização, checkpoint a checkpoint.

## ⚠ Fato importante registrado

O projeto `rg-gastro` que já existe na conta Vercel, ligado a `painel.roneidegonzaga.com`, **é uma versão legada que não corresponde ao código atual** (o de `C:\Projetos\rg-gastro-dev`). Ele deve ser tratado como independente:
- Não será conectado ao novo repositório
- Não será alterado
- O domínio `painel.roneidegonzaga.com` não será tocado
- Um **projeto novo e separado** será criado na Vercel, exclusivamente para desenvolvimento, quando essa etapa for autorizada

## Decisões aprovadas para a implementação futura

| Tema | Decisão |
|---|---|
| Rota de Preview | **A — Integração Git**, não a CLI local |
| Onde a credencial DEV fica | **Variáveis de ambiente da Vercel**, nunca commitada em `config.js` |
| Geração do `config.js` | Passo mínimo de build (`scripts/generate-config.js`, já criado e testado) |
| Fallback para produção | Proibido — o script falha explicitamente para qualquer valor de ambiente fora da lista de permissão |
| Projeto Vercel | **Novo, dedicado só a desenvolvimento** — nunca o projeto legado `rg-gastro`/`painel.roneidegonzaga.com` |

## O que já foi preparado localmente (não commitado até este checkpoint ser fechado)

- `scripts/generate-config.js` — endurecido: só gera `config.js` quando `VERCEL_ENV=preview` ou `LOCAL_TEST_MODE=true` (modo de teste local deliberado); `VERCEL_ENV=production` é tratado como no-op seguro (preserva o `config.js` do repositório); qualquer outro valor falha explicitamente, sem gerar nada. Testado com 5 cenários — todos passaram (ver commit desta etapa).
- Faixa "AMBIENTE DE DESENVOLVIMENTO" em `app.html` e `index.html` — só aparece quando `cfg.APP_ENV === 'development'`, testada com 5 cenários de valor (inclusive variação de maiúscula/minúscula) — todos passaram.

## Variáveis de ambiente propostas (a configurar só quando o novo projeto Vercel existir)

| Escopo | Variável | Valor |
|---|---|---|
| Production (do projeto **novo**, não o legado) | `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `APP_ENV=production` | A definir quando esse projeto for criado |
| Preview (branch `desenvolvimento`) | `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY` (projeto `rg-gastro-DEV`), `APP_ENV=development` | Já disponíveis localmente em `config.dev.js` |

`GOOGLE_CLIENT_ID` fica de fora em ambos por enquanto — só entra na Etapa 4.

## Pendente de autorização (próximos checkpoints, não agora)

1. Criar repositório privado no GitHub e fazer os primeiros pushes (`master`, depois `desenvolvimento`, depois a tag)
2. Criar o projeto novo e dedicado na Vercel (nunca o legado)
3. Conectar esse projeto novo ao repositório
4. Configurar as variáveis de ambiente (tabela acima)
5. Configurar o Build Command (`node scripts/generate-config.js`) e Output Directory (raiz)

## Riscos

- Nenhum risco para o projeto legado/domínio real, porque ele não será tocado em nenhuma etapa deste plano
- Erro humano ao configurar o escopo de uma variável de ambiente (Production vs. Preview) na Vercel — mitigado revisando cada variável no momento da criação
- `scripts/generate-config.js` precisa ser validado de verdade dentro do ambiente de build real da Vercel (containers podem se comportar diferente do terminal local) — só será confirmado quando o projeto novo existir

## Rollback

- Remover `scripts/generate-config.js` e a faixa dev de `app.html`/`index.html` reverte tudo sem deixar resíduo — nenhuma das duas mudanças depende de infraestrutura externa
- Se o projeto Vercel novo for criado e precisar ser desfeito, isso é uma ação na conta da Vercel, sem nenhum efeito sobre o projeto legado

---

**Nada foi publicado.** Próximo passo: sua aprovação para criar o repositório GitHub privado e fazer os primeiros pushes.
