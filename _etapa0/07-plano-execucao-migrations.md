# Plano de execução das migrations no Supabase DEV (Checkpoint 0.7 — preparação)

**Nada neste documento foi executado.** É o procedimento a seguir quando a execução da `0000_baseline.sql` for autorizada.

## Regra geral

Uma migration por vez. **Nunca seguir para a próxima se a anterior falhar ou tiver qualquer resultado inesperado.** Em caso de dúvida, parar e trazer o erro exato para revisão antes de tentar de novo.

## Antes de cada uma das 3 execuções (repetir sempre, não só na primeira)

1. Confirmar visualmente, no painel do Supabase, que o projeto aberto é o de **desenvolvimento** (nome com sufixo DEV) — nunca o de produção.
2. Confirmar que a URL do projeto (visível em Project Settings) é diferente da URL de produção que já está em `config.js`.
3. Abrir o SQL Editor a partir dessa aba do projeto DEV especificamente — nunca reaproveitar uma aba que já esteve em produção.

## Passo a passo

### 1) `0000_baseline.sql`
- **Resultado esperado:** 13 tabelas novas no schema `public` (`profiles` + as 12 do bloco base), 3 funções (`rg_first_admin`, `rg_is_member`, `rg_is_admin`), 1 trigger (`trg_first_admin`), RLS habilitada nas 13 tabelas, políticas criadas (4 em `profiles`, "membros acessam" em 9 tabelas, "admin acessa" em 3 tabelas).
- **Consultas de verificação (somente leitura) depois de rodar:**
  ```sql
  -- tabelas criadas no schema public
  select table_name from information_schema.tables
  where table_schema = 'public' order by table_name;

  -- funcoes rg_*
  select routine_name, security_type
  from information_schema.routines
  where routine_schema = 'public' and routine_name like 'rg_%';

  -- trigger
  select tgname, tgrelid::regclass
  from pg_trigger
  where tgname = 'trg_first_admin';

  -- RLS habilitada
  select relname, relrowsecurity
  from pg_class
  where relname in (
    'profiles','rg_financeiro','rg_contas','rg_metas','rg_crm','rg_clientes',
    'rg_mentorados','rg_sessoes','rg_plano_itens','rg_projetos','rg_tarefas',
    'rg_agenda','rg_dose'
  );

  -- politicas criadas
  select tablename, policyname
  from pg_policies
  where schemaname = 'public'
  order by tablename;
  ```
- **Se der erro:** rodar `ROLLBACK;` explicitamente (mesmo que o erro já tenha abortado a transação), copiar a mensagem de erro exata, parar e trazer para revisão. Não tentar "consertar e continuar" dentro da mesma sessão.

### 2) `0001_v4_cursos_processos_documentos_timeline.sql`
- **Só rodar depois de confirmar o resultado esperado da 0000 acima.**
- **Resultado esperado:** coluna `tipo_consultoria` em `rg_clientes`; 4 tabelas novas (`rg_alunos`, `rg_processos`, `rg_documentos`, `rg_etapas`); RLS + política "membros acessam" nas 4.
- **Consulta de verificação:**
  ```sql
  select column_name from information_schema.columns
  where table_schema='public' and table_name='rg_clientes' and column_name='tipo_consultoria';

  select table_name from information_schema.tables
  where table_schema='public' and table_name in ('rg_alunos','rg_processos','rg_documentos','rg_etapas');
  ```

### 3) `0002_v5_categorias_vendas_equipe_visitas_links_cursos.sql`
- **Só rodar depois de confirmar o resultado esperado da 0001 acima.**
- **Resultado esperado:** 14 colunas novas distribuídas em `rg_clientes`, `rg_mentorados`, `rg_tarefas`, `rg_documentos`, `rg_etapas`, `rg_processos`, `rg_contas`, `rg_projetos`; 6 tabelas novas (`rg_categorias`, `rg_vendas`, `rg_equipe`, `rg_visitas`, `rg_links`, `rg_cursos`); RLS + "membros acessam" em 4 delas, "admin acessa" em `rg_equipe`/`rg_vendas`.
- **Consulta de verificação:**
  ```sql
  select table_name from information_schema.tables
  where table_schema='public' and table_name in
    ('rg_categorias','rg_vendas','rg_equipe','rg_visitas','rg_links','rg_cursos');

  select tablename, policyname from pg_policies
  where schemaname='public' and tablename in ('rg_equipe','rg_vendas');
  ```

## Sobre o trigger `trg_first_admin`

- **A primeira conta criada no ambiente DEV vira admin automaticamente**, sem nenhuma etapa manual — é assim que o sistema já funciona hoje em produção, e o comportamento é preservado de propósito na migration.
- **Nenhuma conta deve ser criada no Supabase DEV antes de decidirmos, juntas, qual e-mail de teste será esse primeiro admin.**
- **Nunca usar uma conta real** de cliente, aluno, mentorado ou membro da equipe para esse teste — só um e-mail de teste dedicado.
- Isso vale para o Checkpoint 0.9 (teste de isolamento), não para agora — mas fica registrado aqui porque a decisão precisa ser tomada antes de qualquer cadastro, inclusive antes de "só testar rapidinho".
