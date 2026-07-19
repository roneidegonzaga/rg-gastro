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
| 0.7 | Preparação do Supabase de desenvolvimento | ⏸ **Parado — depende de ação manual sua** | Não tenho acesso para criar o projeto; instruções entregues em `05-instrucoes-supabase-dev.md` |
| 0.8 | Preview da Vercel | ⏸ Proposta escrita, não configurada | Depende do Checkpoint 0.7 estar concluído; proposta em `06-instrucoes-preview-vercel.md` |
| 0.9 | Teste de isolamento | Não iniciado | Depende dos Checkpoints 0.7 e 0.8 |

**Execução parada no Checkpoint 0.7**, conforme instruído — aguardando você criar o projeto Supabase de desenvolvimento e confirmar (sem colar credenciais) que `config.dev.js` está preenchido localmente.
