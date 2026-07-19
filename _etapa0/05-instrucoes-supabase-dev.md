# Instruções para criar o projeto Supabase de desenvolvimento (Checkpoint 0.7)

## Consigo criar o projeto diretamente?

**Não.** Não tenho nenhuma ferramenta autenticada de Supabase disponível nesta sessão (sem CLI configurada, sem MCP, sem API key). A criação do projeto precisa ser feita manualmente por você, pelo painel do Supabase.

## Passo a passo recomendado

1. Acesse [supabase.com](https://supabase.com) com a mesma conta/organização usada para o projeto de produção (ou uma separada, se preferir isolamento ainda maior).
2. **New Project**.
3. **Nome sugerido:** `rg-gastro-DEV` (em maiúsculas na parte "DEV" — para nunca ser confundido visualmente com o projeto de produção nas listagens).
4. **Região:** a mesma região do projeto de produção, para o comportamento de latência ser comparável em testes (não é obrigatório, mas recomendado).
5. **Senha do banco:** gere uma senha forte só para este projeto — nunca reaproveite a senha do banco de produção.
6. **Plano:** Free é suficiente para desenvolvimento e testes.
7. **Cuidados para diferenciar visualmente de produção:**
   - Nome do projeto com sufixo `DEV` bem visível
   - Se o Supabase permitir, use uma cor/ícone de organização diferente
   - Evite deixar as duas abas do painel (produção e dev) abertas lado a lado sem essa distinção clara no título

## O que fazer depois de criado

**Não me envie a URL nem a chave anônima diretamente na conversa.** Em vez disso:

1. Copie `config.dev.example.js` (já criado nesta pasta) para `config.dev.js`.
2. Preencha `config.dev.js` localmente, no seu computador, com a URL e a chave anônima do novo projeto — esse arquivo já está preparado para nunca ser commitado (será adicionado ao `.gitignore` quando você confirmar que ele existe).
3. Volte para mim e confirme apenas: **"o projeto de desenvolvimento foi criado e config.dev.js está preenchido localmente"** — sem colar os valores.

## O que NÃO será feito ainda, mesmo depois da criação do projeto

- **Não vou rodar `setup-supabase.sql` nem as migrations imediatamente.** Antes de qualquer execução no projeto novo, vou:
  - validar o conteúdo dos 3 arquivos de migration já preparados (`_etapa0/migrations/`);
  - apresentar exatamente os comandos que seriam executados;
  - identificar qualquer falha potencial;
  - propor a ordem de aplicação da baseline;
  - **aguardar sua autorização explícita antes de rodar qualquer SQL**, mesmo contra o projeto de desenvolvimento.

---

## ⏸ Este é o ponto de parada desta execução

Meu próximo passo depende de três coisas que só você pode fazer:
1. Criar o projeto Supabase de desenvolvimento (passo a passo acima)
2. Confirmar o plano do Supabase de desenvolvimento (Free, presumivelmente, mas confirme)
3. Preencher `config.dev.js` localmente e me avisar que está pronto — sem colar valores

Assim que confirmar isso, sigo para validar e apresentar (sem executar) os comandos de aplicação da baseline no projeto novo — o próprio Checkpoint 0.7, na parte que ainda falta, seguido do Checkpoint 0.8 (preview da Vercel, cuja proposta já está pronta no documento `06-instrucoes-preview-vercel.md`) e do Checkpoint 0.9 (teste de isolamento).
