-- ============================================================
-- MIGRATION 0007 — v11: desfazer lote de importação (Etapa 1B.6)
-- Cria public.rg_desfazer_lote — segunda RPC de negócio do projeto
-- (a primeira foi public.rg_reprocessar_lote, na 0005/0006).
--
-- Escopo: só lotes de importação ORIGINAL (reprocessa_lote_id IS
-- NULL), com status='ativo' e pelo menos 1 venda vinculada, e
-- SOMENTE se nenhuma dessas vendas já tiver fin_lancado=true.
-- "Desfazer um reprocessamento" (reverter campos a partir do
-- histórico) é uma operação diferente, fora do escopo desta função
-- — decisão de negócio já registrada na conversa que aprovou este
-- plano.
--
-- Mecânica: soft delete, nunca DELETE. Vendas do lote recebem
-- excluido=true/excluido_em/excluido_por (colunas já existentes
-- desde a 0003, nunca usadas até agora). O lote recebe
-- status='desfeito', desfeito_por/desfeito_em (também já existentes
-- desde a 0003) e desfeito_motivo (nova coluna nesta migration).
-- rg_vendas_alteracoes_historico NUNCA é tocado — preserva
-- integralmente o histórico de qualquer reprocessamento anterior.
--
-- INVARIANTE — esta função NUNCA insere, atualiza ou de qualquer
-- forma toca public.rg_financeiro.
--
-- NAO EXECUTAR sem autorizacao explicita. Validar exclusivamente
-- no projeto Supabase DEV antes de qualquer aplicação em produção.
--
-- Depende de: 0003_v6_lotes_importacao_hotmart.sql (rg_vendas.
-- excluido/excluido_em/excluido_por, rg_vendas_lotes.desfeito_por/
-- desfeito_em, public.rg_is_admin()), 0004_v7_...sql (constraint de
-- status já inclui 'desfeito').
-- ============================================================

BEGIN;

-- ===== MOTIVO DO DESFAZIMENTO (aditivo, nullable no banco — o
-- client sempre exige preenchimento antes de chamar a função) =====
alter table public.rg_vendas_lotes add column if not exists desfeito_motivo text;

create or replace function public.rg_desfazer_lote(
  p_lote_id bigint,
  p_motivo text
)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_lote record;
  v_motivo text;
  v_total_vendas int;
  v_fin_count int;
  v_vendas_afetadas int := 0;
  v_linhas int;
  v_erro_original text;
  v_sqlstate_original text;
begin
  if not public.rg_is_admin() then
    raise exception 'somente administradores podem desfazer importações';
  end if;

  begin
    v_motivo := nullif(trim(coalesce(p_motivo, '')), '');
    if v_motivo is null then
      raise exception 'motivo é obrigatório para desfazer um lote';
    end if;

    select * into v_lote from public.rg_vendas_lotes where id = p_lote_id for update;
    if not found then
      raise exception 'lote % não encontrado', p_lote_id;
    end if;
    if v_lote.status <> 'ativo' then
      raise exception 'lote % não está ativo (status atual: %) — não pode ser desfeito', p_lote_id, v_lote.status;
    end if;
    if v_lote.reprocessa_lote_id is not null then
      raise exception 'lote % é um lote de reprocessamento, não uma importação original — não pode ser desfeito por esta função', p_lote_id;
    end if;

    -- trava todas as vendas do lote antes de checar/alterar, para
    -- que um fin_lancado concorrente não escape da checagem abaixo
    perform 1 from public.rg_vendas where lote_id = p_lote_id for update;

    select count(*) into v_total_vendas from public.rg_vendas where lote_id = p_lote_id;
    if v_total_vendas = 0 then
      raise exception 'lote % não possui nenhuma venda vinculada — sem escopo para desfazer', p_lote_id;
    end if;

    select count(*) into v_fin_count from public.rg_vendas where lote_id = p_lote_id and fin_lancado = true;
    if v_fin_count > 0 then
      raise exception 'lote % possui % venda(s) já lançada(s) no financeiro (fin_lancado=true) — desfazer está bloqueado; resolva manualmente antes', p_lote_id, v_fin_count;
    end if;

    update public.rg_vendas
      set excluido = true, excluido_em = now(), excluido_por = auth.uid()
      where lote_id = p_lote_id and excluido = false;
    get diagnostics v_vendas_afetadas = row_count;

    update public.rg_vendas_lotes
      set status = 'desfeito', desfeito_por = auth.uid(), desfeito_em = now(), desfeito_motivo = v_motivo
      where id = p_lote_id;
    get diagnostics v_linhas = row_count;
    if v_linhas <> 1 then
      raise exception 'UPDATE do lote % afetou % linha(s) (esperado 1)', p_lote_id, v_linhas;
    end if;

    return jsonb_build_object('ok', true, 'vendas_ocultadas', v_vendas_afetadas);

  exception when others then
    v_erro_original := SQLERRM;
    v_sqlstate_original := SQLSTATE;
    return jsonb_build_object('ok', false, 'erro', v_erro_original, 'sqlstate', v_sqlstate_original);
  end;
end;
$$;

revoke execute on function public.rg_desfazer_lote(
  bigint, text
) from public, anon, service_role;

grant execute on function public.rg_desfazer_lote(
  bigint, text
) to authenticated;

COMMIT;
