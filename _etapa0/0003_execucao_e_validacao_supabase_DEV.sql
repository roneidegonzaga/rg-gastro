-- ============================================================
-- SCRIPT DE EXECUÇÃO E VALIDAÇÃO — Etapa 1B.1 (migration 0003)
-- Rodar SOMENTE contra o projeto Supabase "rg-gastro-DEV",
-- confirmando visualmente o nome do projeto no painel antes de
-- colar qualquer coisa aqui.
--
-- NÃO é um arquivo de migration por si só — é um roteiro de
-- execução. A migration "de verdade" continua sendo
-- _etapa0/migrations/0003_v6_lotes_importacao_hotmart.sql
-- (o Bloco 1 abaixo é uma cópia idêntica dela, não alterada).
--
-- REVISÃO: o arquivo inteiro pode ser colado e executado de UMA
-- VEZ no SQL Editor. Os testes (Blocos 3-6) e as validações
-- (Bloco 2) usam DO $$ ... END $$ com RAISE NOTICE, então nenhum
-- erro esperado interrompe o restante do script — tudo aparece
-- no painel de Mensagens/Notices, em ordem, de cima pra baixo.
--
-- LEGENDA DE RESULTADO ESPERADO POR BLOCO:
--   Bloco 1 — migration completa            → SUCESSO (COMMIT),
--                                              sem mensagem especial
--   Bloco 2 — 9 validações via RAISE NOTICE  → SUCESSO; leia cada
--                                              linha "2.x" no painel
--                                              de Mensagens e confira
--                                              contra o "esperado"
--   Bloco 3 — teste válido, campo='valor'    → NOTICE "teste aprovado"
--   Bloco 4 — teste inválido, valor nulo     → NOTICE "teste aprovado"
--                                              (a constraint É QUEM
--                                              bloqueia; o bloqueio
--                                              em si é o sucesso)
--   Bloco 5 — teste inválido, "R$ 297,00"    → NOTICE "teste aprovado"
--   Bloco 6 — teste válido, campo='status'   → NOTICE "teste aprovado"
--
-- Se QUALQUER bloco 3-6 imprimir "TESTE REPROVADO" ou "TESTE
-- INCONCLUSIVO" em vez de "teste aprovado", ou se a execução parar
-- de vez com um ERROR não capturado, pare e me avise — não é
-- esperado, e eu não devo prosseguir escrevendo código em cima
-- disso sem entender a causa primeiro.
--
-- Nenhum bloco de teste (3 a 6) deixa dado persistido em nenhum
-- cenário — nem no caminho esperado, nem no inesperado.
-- ============================================================


-- ============================================================
-- INÍCIO DO BLOCO 1 — MIGRATION 0003 COMPLETA (idêntica ao arquivo
-- _etapa0/migrations/0003_v6_lotes_importacao_hotmart.sql)
-- Resultado esperado: SUCESSO — sem erro.
-- ============================================================

BEGIN;

-- ===== LOTES DE IMPORTACAO =====
create table if not exists public.rg_vendas_lotes (
  id bigint generated always as identity primary key,
  arquivo_nome text,
  importado_em timestamptz not null default now(),
  importado_por uuid references public.profiles(user_id) on delete set null,
  importado_por_nome text,

  -- contadores de resultado das linhas processadas
  total_linhas int not null default 0,
  inseridas int not null default 0,
  atualizadas int not null default 0,
  inalteradas int not null default 0,
  rejeitadas int not null default 0,

  -- contadores de alteracoes encontradas, por campo (uma venda
  -- pode contribuir para mais de um destes na mesma importacao)
  alteracoes_status int not null default 0,
  alteracoes_valor int not null default 0,
  alteracoes_liquido int not null default 0,

  -- pendencias financeiras geradas por este lote
  pendencias_financeiras int not null default 0,

  rejeicoes text,   -- json: [{linha, motivo}]

  -- reprocessamento: preenchido só pelo fluxo explicito "Reprocessar"
  -- a partir de um lote especifico (nunca inferido automaticamente)
  reprocessa_lote_id bigint references public.rg_vendas_lotes(id) on delete set null,

  status text not null default 'ativo',
  desfeito_em timestamptz,
  desfeito_por uuid references public.profiles(user_id) on delete set null,

  constraint rg_vendas_lotes_status_check check (status in ('ativo','desfeito'))
);

create index if not exists idx_vendas_lotes_status on public.rg_vendas_lotes(status);
create index if not exists idx_vendas_lotes_reprocessa on public.rg_vendas_lotes(reprocessa_lote_id);

-- ===== VINCULO E SOFT DELETE EM rg_vendas =====
alter table public.rg_vendas add column if not exists lote_id bigint references public.rg_vendas_lotes(id) on delete set null;
alter table public.rg_vendas add column if not exists ultima_atualizacao_lote_id bigint references public.rg_vendas_lotes(id) on delete set null;
alter table public.rg_vendas add column if not exists atualizado_em timestamptz;
alter table public.rg_vendas add column if not exists excluido boolean not null default false;
alter table public.rg_vendas add column if not exists excluido_em timestamptz;
alter table public.rg_vendas add column if not exists excluido_por uuid references public.profiles(user_id) on delete set null;
alter table public.rg_vendas add column if not exists pendencia_financeira boolean not null default false;

create index if not exists idx_vendas_lote on public.rg_vendas(lote_id);
create index if not exists idx_vendas_ultima_atualizacao_lote on public.rg_vendas(ultima_atualizacao_lote_id);
create index if not exists idx_vendas_excluido on public.rg_vendas(excluido);
create index if not exists idx_vendas_pendencia_financeira on public.rg_vendas(pendencia_financeira);

-- ===== VINCULO EM rg_financeiro =====
alter table public.rg_financeiro add column if not exists origem_venda_id bigint references public.rg_vendas(id) on delete set null;
create index if not exists idx_financeiro_origem_venda on public.rg_financeiro(origem_venda_id);

-- ===== HISTORICO GENERICO DE ALTERACOES (status | valor | liquido) =====
create table if not exists public.rg_vendas_alteracoes_historico (
  id bigint generated always as identity primary key,
  venda_id bigint not null references public.rg_vendas(id) on delete cascade,
  lote_id bigint references public.rg_vendas_lotes(id) on delete set null,
  campo text not null,
  -- status: texto livre (mesmo formato que rg_vendas.status).
  -- valor/liquido: representacao numerica canonica, sem "R$",
  -- sem separador de milhar, ponto como separador decimal
  -- (ex.: "297.00") — nunca o texto formatado exibido na tela.
  valor_anterior text,
  valor_novo text,
  fin_lancado_no_momento boolean not null default false,
  alterado_em timestamptz not null default now(),

  constraint rg_vendas_alteracoes_campo_check check (campo in ('status','valor','liquido')),
  -- NULL numa CHECK conta como "passa" no Postgres — por isso o
  -- "is not null" explícito abaixo, sem ele um valor_anterior/
  -- valor_novo nulo escaparia da validação de formato numérico
  constraint rg_vendas_alteracoes_numerico_check check (
    campo = 'status'
    or (
      valor_anterior is not null and valor_novo is not null
      and valor_anterior ~ '^-?\d+(\.\d{1,2})?$'
      and valor_novo ~ '^-?\d+(\.\d{1,2})?$'
    )
  )
);

create index if not exists idx_alteracoes_venda on public.rg_vendas_alteracoes_historico(venda_id);
create index if not exists idx_alteracoes_lote on public.rg_vendas_alteracoes_historico(lote_id);
create index if not exists idx_alteracoes_campo on public.rg_vendas_alteracoes_historico(campo);

-- ===== RLS — mesmo padrao ja aplicado a rg_vendas (admin-only,
-- por ser dado de faturamento; ver 0002_v5...sql, bloco "equipe
-- (salarios) e vendas (faturamento) so admins") =====
do $$
declare t text;
begin
  foreach t in array array['rg_vendas_lotes','rg_vendas_alteracoes_historico']
  loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists "admin acessa" on public.%I', t);
    execute format('create policy "admin acessa" on public.%I for all using (public.rg_is_admin()) with check (public.rg_is_admin())', t);
  end loop;
end $$;

COMMIT;

-- ============================================================
-- FIM DO BLOCO 1
-- ============================================================


-- ============================================================
-- INÍCIO DO BLOCO 2 — VALIDAÇÕES PÓS-EXECUÇÃO (via RAISE NOTICE,
-- pra tudo aparecer no painel de Mensagens numa execução única)
-- ============================================================

DO $$
DECLARE v_count int;
BEGIN
  select count(*) into v_count from information_schema.tables
  where table_schema = 'public' and table_name in ('rg_vendas_lotes','rg_vendas_alteracoes_historico');
  raise notice '2.1 tabelas novas encontradas: % (esperado: 2)', v_count;
END $$;

DO $$
DECLARE v_count int; v_list text;
BEGIN
  select count(*), string_agg(column_name, ', ' order by column_name) into v_count, v_list
  from information_schema.columns
  where table_schema = 'public' and table_name = 'rg_vendas'
    and column_name in ('lote_id','ultima_atualizacao_lote_id','atualizado_em','excluido','excluido_em','excluido_por','pendencia_financeira');
  raise notice '2.2 colunas novas em rg_vendas: % (esperado: 7) — %', v_count, v_list;
END $$;

DO $$
DECLARE v_count int;
BEGIN
  select count(*) into v_count from information_schema.columns
  where table_schema = 'public' and table_name = 'rg_financeiro' and column_name = 'origem_venda_id';
  raise notice '2.3 coluna origem_venda_id em rg_financeiro: % (esperado: 1)', v_count;
END $$;

DO $$
DECLARE v_list text;
BEGIN
  select string_agg(conname, ', ' order by conname) into v_list
  from pg_constraint
  where conrelid in ('public.rg_vendas_lotes'::regclass, 'public.rg_vendas_alteracoes_historico'::regclass);
  raise notice '2.4 constraints encontradas: %', v_list;
END $$;

DO $$
DECLARE v_count int; v_list text;
BEGIN
  select count(*), string_agg(indexname, ', ' order by indexname) into v_count, v_list
  from pg_indexes
  where schemaname = 'public' and indexname like 'idx_%'
    and tablename in ('rg_vendas_lotes','rg_vendas_alteracoes_historico','rg_vendas','rg_financeiro');
  raise notice '2.5 índices encontrados: % (esperado: 10) — %', v_count, v_list;
END $$;

DO $$
DECLARE v_count int;
BEGIN
  select count(*) into v_count from pg_class
  where relname in ('rg_vendas_lotes','rg_vendas_alteracoes_historico')
    and relnamespace = 'public'::regnamespace and relrowsecurity = true;
  raise notice '2.6 tabelas com RLS habilitado: % (esperado: 2)', v_count;
END $$;

DO $$
DECLARE v_count int; v_list text;
BEGIN
  select count(*), string_agg(polname || ' em ' || polrelid::regclass::text, ', ') into v_count, v_list
  from pg_policy
  where polrelid in ('public.rg_vendas_lotes'::regclass, 'public.rg_vendas_alteracoes_historico'::regclass);
  raise notice '2.7 policies encontradas: % (esperado: 2) — %', v_count, v_list;
END $$;

DO $$
DECLARE v_total int; v_com_lote int; v_excluidas int; v_pendentes int;
BEGIN
  select count(*), count(*) filter (where lote_id is not null),
         count(*) filter (where excluido), count(*) filter (where pendencia_financeira)
  into v_total, v_com_lote, v_excluidas, v_pendentes
  from public.rg_vendas;
  raise notice '2.8 rg_vendas: total=%, com_lote=% (esperado 0), excluidas=% (esperado 0), pendentes=% (esperado 0)',
    v_total, v_com_lote, v_excluidas, v_pendentes;
END $$;

DO $$
DECLARE v_total int; v_com_origem int;
BEGIN
  select count(*), count(*) filter (where origem_venda_id is not null)
  into v_total, v_com_origem
  from public.rg_financeiro;
  raise notice '2.9 rg_financeiro: total=%, com_origem=% (esperado 0)', v_total, v_com_origem;
END $$;

-- ============================================================
-- FIM DO BLOCO 2
-- ============================================================


-- ============================================================
-- INÍCIO DO BLOCO 3 — TESTE VÁLIDO: campo = 'valor', formato canônico
-- Isolamento: INSERT + DELETE da mesma linha, dentro do mesmo
-- bloco DO — não depende de ROLLBACK externo, não sobrevive além
-- deste bloco em nenhum cenário.
-- Pressupõe que já existe pelo menos 1 venda em rg_vendas (já é
-- o caso no DEV, com os dados de teste da Etapa 1A/0.9).
-- ============================================================

DO $$
DECLARE
  v_venda_id bigint;
  v_novo_id bigint;
BEGIN
  select id into v_venda_id from public.rg_vendas limit 1;
  if v_venda_id is null then
    raise exception 'TESTE INCONCLUSIVO (bloco 3): nao ha nenhuma venda em rg_vendas para usar como referencia.';
  end if;

  insert into public.rg_vendas_alteracoes_historico
    (venda_id, lote_id, campo, valor_anterior, valor_novo, fin_lancado_no_momento)
  values
    (v_venda_id, null, 'valor', '297.00', '250.00', false)
  returning id into v_novo_id;

  raise notice 'teste aprovado: constraint aceitou o valor válido (campo=valor, "297.00" -> "250.00"), linha temporária id=%', v_novo_id;

  delete from public.rg_vendas_alteracoes_historico where id = v_novo_id;

EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'TESTE INCONCLUSIVO (bloco 3, campo=valor válido): erro inesperado — SQLSTATE=%, mensagem=%', SQLSTATE, SQLERRM;
END $$;

-- ============================================================
-- FIM DO BLOCO 3
-- ============================================================


-- ============================================================
-- INÍCIO DO BLOCO 4 — TESTE INVÁLIDO: campo = 'valor', valor_novo nulo
-- Isolamento: a exceção da constraint é capturada dentro do
-- próprio DO — nunca propaga pro resto do script.
-- ============================================================

DO $$
DECLARE v_venda_id bigint;
BEGIN
  select id into v_venda_id from public.rg_vendas limit 1;

  insert into public.rg_vendas_alteracoes_historico
    (venda_id, lote_id, campo, valor_anterior, valor_novo, fin_lancado_no_momento)
  values
    (v_venda_id, null, 'valor', '297.00', null, false);

  -- se chegou até aqui, o INSERT não foi bloqueado — falha do teste
  raise exception 'nao deveria ter sido aceito';

EXCEPTION
  WHEN check_violation THEN
    RAISE NOTICE 'teste aprovado: constraint bloqueou o valor inválido (valor_novo nulo) — %', SQLERRM;
  WHEN OTHERS THEN
    RAISE EXCEPTION 'TESTE REPROVADO OU INCONCLUSIVO (bloco 4, valor_novo nulo): esperava check_violation — SQLSTATE=%, mensagem=%', SQLSTATE, SQLERRM;
END $$;

-- ============================================================
-- FIM DO BLOCO 4
-- ============================================================


-- ============================================================
-- INÍCIO DO BLOCO 5 — TESTE INVÁLIDO: campo = 'valor', formato "R$ 297,00"
-- Isolamento: mesma técnica do Bloco 4.
-- ============================================================

DO $$
DECLARE v_venda_id bigint;
BEGIN
  select id into v_venda_id from public.rg_vendas limit 1;

  insert into public.rg_vendas_alteracoes_historico
    (venda_id, lote_id, campo, valor_anterior, valor_novo, fin_lancado_no_momento)
  values
    (v_venda_id, null, 'valor', '297.00', 'R$ 297,00', false);

  raise exception 'nao deveria ter sido aceito';

EXCEPTION
  WHEN check_violation THEN
    RAISE NOTICE 'teste aprovado: constraint bloqueou o valor inválido (formato "R$ 297,00") — %', SQLERRM;
  WHEN OTHERS THEN
    RAISE EXCEPTION 'TESTE REPROVADO OU INCONCLUSIVO (bloco 5, formato "R$ 297,00"): esperava check_violation — SQLSTATE=%, mensagem=%', SQLSTATE, SQLERRM;
END $$;

-- ============================================================
-- FIM DO BLOCO 5
-- ============================================================


-- ============================================================
-- INÍCIO DO BLOCO 6 — TESTE VÁLIDO: campo = 'status', texto livre
-- Isolamento: mesma técnica do Bloco 3 (INSERT + DELETE no mesmo DO).
-- ============================================================

DO $$
DECLARE
  v_venda_id bigint;
  v_novo_id bigint;
BEGIN
  select id into v_venda_id from public.rg_vendas limit 1;
  if v_venda_id is null then
    raise exception 'TESTE INCONCLUSIVO (bloco 6): nao ha nenhuma venda em rg_vendas para usar como referencia.';
  end if;

  insert into public.rg_vendas_alteracoes_historico
    (venda_id, lote_id, campo, valor_anterior, valor_novo, fin_lancado_no_momento)
  values
    (v_venda_id, null, 'status', 'Completo', 'Aprovado', false)
  returning id into v_novo_id;

  raise notice 'teste aprovado: constraint aceitou o status como texto livre, linha temporária id=%', v_novo_id;

  delete from public.rg_vendas_alteracoes_historico where id = v_novo_id;

EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'TESTE INCONCLUSIVO (bloco 6, campo=status válido): erro inesperado — SQLSTATE=%, mensagem=%', SQLSTATE, SQLERRM;
END $$;

-- ============================================================
-- FIM DO BLOCO 6
-- ============================================================

-- ============================================================
-- FIM DO SCRIPT — se todos os 4 blocos de teste imprimiram
-- "teste aprovado", e o Bloco 2 bateu com os valores esperados,
-- a subetapa 1B.1 está pronta para eu apresentar o restante do
-- checklist (diff final, confirmação de produção intocada).
-- ============================================================
