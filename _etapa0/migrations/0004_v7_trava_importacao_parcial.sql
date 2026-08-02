-- ============================================================
-- MIGRATION 0004 — v7: trava contra importacao parcial (Etapa 1B.2)
-- Amplia o status de rg_vendas_lotes (processando/ativo/erro/desfeito)
-- e adiciona rg_vendas.importacao_concluida, para impedir que vendas
-- de uma importacao interrompida no meio apareçam em KPIs, listas,
-- filtros ou no botao "Lançar no financeiro" antes da confirmacao
-- final do lote inteiro.
--
-- Depende de: 0003_v6_lotes_importacao_hotmart.sql
--
-- NAO EXECUTAR sem autorizacao explicita. Validar exclusivamente
-- no projeto Supabase DEV antes de qualquer aplicação em produção.
--
-- Aditiva: nenhuma coluna existente removida, renomeada ou com
-- tipo alterado. rg_vendas_lotes ainda esta vazia (a Etapa 1B.2
-- nao foi implementada em app.html ainda) — a troca da constraint
-- de status nao afeta nenhum dado existente ali. rg_vendas ja tem
-- dados reais de teste; a coluna nova nasce com default true, sem
-- mudar o comportamento de nenhuma linha existente.
-- ============================================================

BEGIN;

-- ===== STATUS AMPLIADO EM rg_vendas_lotes =====
alter table public.rg_vendas_lotes drop constraint if exists rg_vendas_lotes_status_check;
alter table public.rg_vendas_lotes add constraint rg_vendas_lotes_status_check
  check (status in ('processando','ativo','erro','desfeito'));

alter table public.rg_vendas_lotes add column if not exists erro_linha int;
alter table public.rg_vendas_lotes add column if not exists erro_detalhe text;

-- ===== TRAVA DE CONFIRMACAO EM rg_vendas =====
-- default true: toda venda ja existente antes desta migration ja
-- e considerada valida. So a Etapa 1B.2 vai gravar 'false'
-- explicitamente, no INSERT de cada venda nova, ate a confirmacao
-- final do lote — que segue a ordem aprovada: (a) lote vira 'ativo'
-- primeiro, com os contadores atualizados; (b) so entao as vendas
-- daquele lote viram 'true' numa unica operacao; (c) uma consulta
-- de conferencia confirma zero vendas 'false' restantes antes de
-- informar sucesso ao usuario.
alter table public.rg_vendas add column if not exists importacao_concluida boolean not null default true;

-- indice parcial: só as linhas incompletas (false) sao o caso raro
-- e interessante de consultar no futuro (ex.: rotina de identificacao
-- de lotes ativos com vendas incompletas, ja registrada como
-- necessidade futura). Hoje DB.list busca a tabela inteira e filtra
-- no JS, sem WHERE no Supabase — este indice nao acelera nenhuma
-- consulta existente agora, e preparo de custo praticamente nulo.
create index if not exists idx_vendas_importacao_incompleta
  on public.rg_vendas(lote_id) where importacao_concluida = false;

COMMIT;
