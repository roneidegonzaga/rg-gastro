# Plano de backup e restauração (Checkpoint 0.6)

**Nenhum backup foi executado. Nenhum comando abaixo foi rodado — são instruções.**

## 0. Plano do Supabase confirmado

Você confirmou: **plano Free.** Isso define diretamente a estratégia abaixo — o Supabase Free **não oferece backups automáticos gerenciados** (esse recurso começa no plano Pro, com retenção diária, e Point-in-Time Recovery em planos ainda mais altos). A estratégia de backup precisa ser manual.

## 1. Opções documentadas

| Opção | Disponível no plano Free? | O que cobre |
|---|---|---|
| Backup automático do Supabase (painel → Database → Backups) | **Não** | — |
| Point-in-Time Recovery | **Não** (recurso de planos superiores) | — |
| Exportação do schema (estrutura, sem dados) | **Sim**, manual — via painel (Database → Tables → botão de exportar SQL) ou via `supabase db dump --schema-only` (Supabase CLI) | Só estrutura (tabelas, funções, triggers, RLS) |
| Backup completo com `pg_dump` (schema + dados) | **Sim**, manual — exige a connection string do Postgres do projeto | Estrutura e dados completos |
| Backup seletivo de tabelas | **Sim**, manual — `pg_dump` aceita `--table=nome_da_tabela`, repetido para cada tabela desejada | Só as tabelas escolhidas |
| Restauração em ambiente de desenvolvimento | **Sim** — `psql` ou `pg_restore` contra a connection string do projeto de desenvolvimento | — |

## 2. Recomendação para este projeto (plano Free)

1. **Antes de qualquer migration de risco em produção** (ex.: Etapa 2/permissões, Etapa 6C/isolamento de processos): rodar um `pg_dump` completo (schema + dados) de produção, guardado localmente fora de qualquer pasta versionada pelo Git.
2. **Frequência mínima recomendada:** a cada migration de risco, e periodicamente (ex.: semanal) enquanto o plano continuar Free — já que não há rede de segurança automática.
3. **O dump nunca deve ser commitado** nem deixado dentro de `rg-gastro-dev` ou `rg-gastro-backup-INTOCAVEL-2026-07-18` — sugiro uma pasta separada, fora do controle de versão, com controle de acesso equivalente ao de uma credencial (ex.: `backups-supabase/` fora do OneDrive sincronizado publicamente, ou um local criptografado).

## 3. Comando de referência (não executado — só instrução)

```
pg_dump "<CONNECTION_STRING_DO_PROJETO>" \
  --format=custom \
  --file="backup-producao-AAAA-MM-DD.dump"
```

A `<CONNECTION_STRING_DO_PROJETO>` fica disponível no painel do Supabase em **Project Settings → Database → Connection string**. **Não cole essa string nesta conversa** — rode o comando você mesma localmente, ou me avise quando quiser que eu prepare o comando exato para você rodar, sem que a credencial passe por aqui.

## 4. Passos que exigem ação manual sua

- Gerar/copiar a connection string do painel do Supabase (nunca colada aqui)
- Rodar o `pg_dump` localmente (ou autorizar explicitamente, checkpoint a checkpoint, que eu rode um comando específico usando uma credencial que você tenha configurado localmente, nunca visível nesta conversa)
- Guardar o arquivo `.dump` gerado em local seguro, fora do controle de versão

## 5. Passos que posso preparar localmente

- Os comandos exatos de `pg_dump`/`pg_restore` prontos para copiar e colar
- A estrutura de pastas para guardar os backups fora do repositório
- O checklist abaixo

## 6. Como validar o procedimento de restauração

**Nunca contra produção.** Sempre: `pg_restore` do arquivo `.dump` contra a connection string do projeto de **desenvolvimento** (vazio ou recriado), seguido de conferência manual de uma amostra dos dados restaurados. Só depois disso o backup é considerado testado e confiável.

## 7. Checklist obrigatório antes de qualquer migration de risco

- [ ] Projeto-alvo confirmado (nome e URL, comparado visualmente com o de produção)
- [ ] Ambiente confirmado (desenvolvimento ou produção — nunca implícito)
- [ ] Backup disponível e com menos de X dias (definir X)
- [ ] Migration a executar identificada pelo número/arquivo
- [ ] Rollback documentado e revisado
- [ ] Pessoa que aprovou a execução identificada
- [ ] Resultado esperado descrito antes de rodar
- [ ] Validação posterior planejada (o que conferir depois de rodar)

**Nenhum backup real foi executado nesta etapa.**
