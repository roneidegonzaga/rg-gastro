# Registro de execução — Etapa 0 (ambiente seguro, backup e recuperação)

Autorização recebida em: 18/07/2026. Execução restrita à Etapa 0, com parada obrigatória em qualquer checkpoint que dependa de ação manual, acesso externo, credencial ou decisão.

| Checkpoint | Descrição | Status | Observação |
|---|---|---|---|
| 0.1 | Preservação local e pasta de trabalho | ✅ Concluído | Cópia intocável e cópia de desenvolvimento criadas; 90/90 arquivos confirmados byte-a-byte idênticos por SHA-256 |
| 0.2 | Git e ponto de restauração | ✅ Concluído | Tag `backup-original-2026-07-18` e branch `desenvolvimento` criadas; histórico preservado; nenhum comando destrutivo usado; sem remoto configurado |
| 0.3 | Inventário das configurações | ✅ Concluído | Nenhum valor de credencial reproduzido; `config.dev.example.js` criado só com placeholders |
| 0.4 | Inventário do schema local | ✅ Concluído | Documento "Inventário do schema descrito no backup" produzido a partir da leitura integral de `setup-supabase.sql` |
| 0.5 | Estratégia de migrations | ✅ Concluído (preparação, sem execução) | Três migrations numeradas extraídas verbatim; nenhuma executada |
| 0.6 | Plano de backup e restauração | ✅ Concluído (documentação, sem execução) | Plano Free confirmado por você; nenhum `pg_dump` executado |
| 0.7 | Preparação do Supabase de desenvolvimento | ✅ **Concluído em 31/07/2026** | Projeto `rg-gastro-DEV` (plano Free) criado por você; `config.dev.js` preenchido localmente; as 3 migrations aplicadas e validadas uma a uma, cada uma em sua própria transação — ver `migrations/status.md` |
| 0.8 | Preview da Vercel | ✅ **Concluído em 31/07/2026** | Rota A (integração Git) executada. `master`, `desenvolvimento` e a tag `backup-original-2026-07-18` enviados a `origin`, cada push autorizado individualmente. Projeto novo e dedicado `painel-rg-gastro-dev` criado na Vercel (Framework Other, Build Command `node scripts/generate-config.js`, Output Directory raiz, Install Command vazio), importado do mesmo repositório, sem domínio customizado. Duas correções de variável necessárias no caminho (chave Publishable e URL base do Supabase, sem barra `/rest/v1/`), cada uma seguida de um commit vazio dedicado e push isolado para redisparar o Preview. Projeto legado `rg-gastro`/`painel.roneidegonzaga.com` não foi tocado em nenhum momento |
| 0.9 | Teste de isolamento | ✅ **Concluído em 31/07/2026** | Preview DEV (`*.vercel.app`, branch `desenvolvimento`) validado: faixa "AMBIENTE DE DESENVOLVIMENTO" visível, cadastro e login funcionais. Primeiro usuário de teste criado; `public.profiles` validado com `role='admin'` e `aprovado=true`, confirmando o trigger `trg_first_admin`. Cliente Supabase do Preview aponta exclusivamente para o projeto `rg-gastro-DEV` (sem fallback de produção, sem URL hardcoded no código) |

## Etapa 0 encerrada em 31/07/2026

Todos os 9 checkpoints concluídos. Ambiente de desenvolvimento isolado, funcional e verificado: GitHub (`master`, `desenvolvimento`, tag), Vercel (`painel-rg-gastro-dev`) e Supabase (`rg-gastro-DEV`) sincronizados entre si. Projeto legado e produção (`rg-gastro`/`painel.roneidegonzaga.com`, Supabase de produção) intactos durante toda a execução — nenhuma ação desta etapa os tocou.
