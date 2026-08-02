-- ============================================================
-- SCRIPT DE EXECUÇÃO E VALIDAÇÃO — Etapa 1B.2 (migration 0004)
-- Rodar SOMENTE contra o projeto Supabase "rg-gastro-DEV",
-- confirmando visualmente o nome do projeto no painel antes de
-- colar qualquer coisa aqui.
--
-- NÃO é um arquivo de migration por si só — é um roteiro de
-- execução. A migration "de verdade" continua sendo
-- _etapa0/migrations/0004_v7_trava_importacao_parcial.sql
-- (o Bloco 1 abaixo é uma cópia idêntica dela, não alterada).
--
-- O arquivo inteiro pode ser colado e executado de UMA VEZ no SQL
-- Editor — os testes (Blocos 3 e 4) e as validações (Bloco 2) usam
-- DO $$ ... END $$ com RAISE NOTICE, então nenhum erro esperado
-- interrompe o restante do script.
--
-- LEGENDA DE RESULTADO ESPERADO POR BLOCO:
--   Bloco 1 — migration completa             → SUCESSO, sem erro
--   Bloco 2 — 7 validações via RAISE NOTICE   → SUCESSO; leia cada
--                                               linha "2.x" no painel
--                                               de Mensagens e confira
--                                               contra o "esperado"
--   Bloco 3 — teste válido, os 4 status       → NOTICE "teste aprovado"
--   Bloco 4 — teste inválido, status fora     → NOTICE "teste aprovado"
--             da lista                          (a constraint É QUEM
--                                                 bloqueia — o bloqueio
--                                                 em si é o sucesso)
--
-- Se QUALQUER bloco 3-4 imprimir "TESTE REPROVADO" ou "TESTE
-- INCONCLUSIVO", ou a execução parar de vez com um ERROR não
-- capturado, pare e me avise — não é esperado.
--
-- Nenhum bloco de teste (3-4) deixa dado persistido em nenhum
-- cenário — nem no caminho esperado, nem no inesperado.
-- ============================================================


-- ============================================================
-- INÍCIO DO BLOCO 1 — MIGRATION 0004 COMPLETA (idêntica ao arquivo
-- _etapa0/migrations/0004_v7_trava_importacao_parcial.sql)
-- Resultado esperado: SUCESSO — sem erro.
-- ============================================================

BEGIN;

-- ===== STATUS AMPLIADO EM rg_vendas_lotes =====
alter table public.rg_vendas_lotes drop constraint if exists rg_vendas_lotes_status_check;
alter table public.rg_vendas_lotes add constraint rg_vendas_lotes_status_check
  check (status in ('processando','ativo','erro','desfeito'));

alter table public.rg_vendas_lotes add column if not exists erro_linha int;
alter table public.rg_vendas_lotes add column if not exists erro_detalhe text;

-- ===== TRAVA DE CONFIRMACAO EM rg_vendas =====
alter table public.rg_vendas add column if not exists importacao_concluida boolean not null default true;

create index if not exists idx_vendas_importacao_incompleta
  on public.rg_vendas(lote_id) where importacao_concluida = false;

COMMIT;

-- ============================================================
-- FIM DO BLOCO 1
-- ============================================================


-- ============================================================
-- INÍCIO DO BLOCO 2 — VALIDAÇÕES PÓS-EXECUÇÃO (via RAISE NOTICE)
-- ============================================================

DO $$
DECLARE v_def text;
BEGIN
  select pg_get_constraintdef(oid) into v_def
  from pg_constraint where conname = 'rg_vendas_lotes_status_check';
  raise notice '2.1 constraint rg_vendas_lotes_status_check: %', v_def;
  -- esperado: contém processando, ativo, erro, desfeito
END $$;

DO $$
DECLARE v_count int; v_list text;
BEGIN
  select count(*), string_agg(column_name || ':' || data_type, ', ' order by column_name)
  into v_count, v_list
  from information_schema.columns
  where table_schema = 'public' and table_name = 'rg_vendas_lotes'
    and column_name in ('erro_linha', 'erro_detalhe');
  raise notice '2.2 colunas erro_linha/erro_detalhe em rg_vendas_lotes: % (esperado: 2) — %', v_count, v_list;
END $$;

DO $$
DECLARE v_data_type text; v_nullable text; v_default text;
BEGIN
  select data_type, is_nullable, column_default
  into v_data_type, v_nullable, v_default
  from information_schema.columns
  where table_schema = 'public' and table_name = 'rg_vendas' and column_name = 'importacao_concluida';
  raise notice '2.3 rg_vendas.importacao_concluida: tipo=%, nullable=% (esperado NO), default=% (esperado true)', v_data_type, v_nullable, v_default;
END $$;

DO $$
DECLARE v_count int;
BEGIN
  select count(*) into v_count from pg_indexes where indexname = 'idx_vendas_importacao_incompleta';
  raise notice '2.4 índice parcial idx_vendas_importacao_incompleta encontrado: % (esperado: 1)', v_count;
END $$;

DO $$
DECLARE v_total int; v_true int; v_false int;
BEGIN
  select count(*),
         count(*) filter (where importacao_concluida = true),
         count(*) filter (where importacao_concluida = false)
  into v_total, v_true, v_false
  from public.rg_vendas;
  raise notice '2.5 rg_vendas: total=%, importacao_concluida=true em % linhas (esperado: igual ao total), false em % linhas (esperado: 0)', v_total, v_true, v_false;
END $$;

DO $$
DECLARE v_count int;
BEGIN
  select count(*) into v_count from public.rg_vendas_lotes;
  raise notice '2.6 rg_vendas_lotes: % linhas (esperado: 0 — Etapa 1B.2 ainda não implementada)', v_count;
END $$;

-- ============================================================
-- FIM DO BLOCO 2
-- ============================================================


-- ============================================================
-- INÍCIO DO BLOCO 3 — TESTE VÁLIDO: os 4 status aceitos
-- Isolamento: cada INSERT é imediatamente seguido de DELETE da
-- mesma linha, dentro do mesmo bloco DO — nada sobrevive além
-- deste bloco em nenhum cenário.
-- ============================================================

DO $$
DECLARE v_id bigint;
BEGIN
  insert into public.rg_vendas_lotes (arquivo_nome, status)
  values ('teste-migration-0004.csv', 'processando') returning id into v_id;
  delete from public.rg_vendas_lotes where id = v_id;

  insert into public.rg_vendas_lotes (arquivo_nome, status)
  values ('teste-migration-0004.csv', 'ativo') returning id into v_id;
  delete from public.rg_vendas_lotes where id = v_id;

  insert into public.rg_vendas_lotes (arquivo_nome, status)
  values ('teste-migration-0004.csv', 'erro') returning id into v_id;
  delete from public.rg_vendas_lotes where id = v_id;

  insert into public.rg_vendas_lotes (arquivo_nome, status)
  values ('teste-migration-0004.csv', 'desfeito') returning id into v_id;
  delete from public.rg_vendas_lotes where id = v_id;

  raise notice 'teste aprovado: os 4 status (processando, ativo, erro, desfeito) foram aceitos pela constraint, nenhum registro de teste permaneceu';

EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'TESTE INCONCLUSIVO (bloco 3, 4 status válidos): erro inesperado — SQLSTATE=%, mensagem=%', SQLSTATE, SQLERRM;
END $$;

-- ============================================================
-- FIM DO BLOCO 3
-- ============================================================


-- ============================================================
-- INÍCIO DO BLOCO 4 — TESTE INVÁLIDO: status fora da lista
-- Isolamento: a exceção da constraint é capturada dentro do
-- próprio DO — nunca propaga pro resto do script.
-- ============================================================

DO $$
BEGIN
  insert into public.rg_vendas_lotes (arquivo_nome, status)
  values ('teste-migration-0004-invalido.csv', 'concluido_errado');

  -- se chegou até aqui, o INSERT não foi bloqueado — falha do teste
  raise exception 'nao deveria ter sido aceito';

EXCEPTION
  WHEN check_violation THEN
    RAISE NOTICE 'teste aprovado: constraint bloqueou o status inválido ("concluido_errado") — %', SQLERRM;
  WHEN OTHERS THEN
    RAISE EXCEPTION 'TESTE REPROVADO OU INCONCLUSIVO (bloco 4, status inválido): esperava check_violation — SQLSTATE=%, mensagem=%', SQLSTATE, SQLERRM;
END $$;

-- ============================================================
-- FIM DO BLOCO 4
-- ============================================================

-- ============================================================
-- FIM DO SCRIPT — se os Blocos 3 e 4 imprimiram "teste aprovado",
-- e o Bloco 2 bateu com os valores esperados, a migration 0004
-- está pronta para eu registrar como aplicada e seguir para a
-- implementação da Etapa 1B.2 em app.html (com sua aprovação).
-- ============================================================
