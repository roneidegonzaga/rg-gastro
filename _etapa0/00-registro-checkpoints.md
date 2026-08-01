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
| 0.8 | Preview da Vercel | ⏸ Em andamento | Rota A (integração Git) aprovada. Push real de `master` e `desenvolvimento` para `origin` (`github.com/roneidegonzaga/rg-gastro`) autorizados e executados em 31/07/2026 — cada um só depois de confirmação explícita, um de cada vez. Push da tag `backup-original-2026-07-18` ainda **não autorizado**. Criação do projeto novo na Vercel, conexão ao repositório e configuração de variáveis de ambiente continuam pendentes de autorização |
| 0.9 | Teste de isolamento | Não iniciado | Depende do Checkpoint 0.8 estar concluído |

**Execução parada no Checkpoint 0.8** — `master` e `desenvolvimento` já estão em `origin`. Próxima decisão pendente: push da tag `backup-original-2026-07-18`, seguido (com autorização própria) da criação do projeto Vercel novo e dedicado.
