-- ============================================================
-- MIGRATION 0006 — v10: pendência financeira no reprocessamento (Etapa 1B.5)
-- Estende public.rg_reprocessar_lote (criada na 0005) para sinalizar
-- pendencia_financeira quando uma venda já lançada no financeiro
-- (fin_lancado=true) sofre alteração real de status/valor/liquido
-- num reprocessamento. Nenhuma tabela nova.
--
-- Colunas usadas que já existiam desde a 0003, sem uso até agora:
-- public.rg_vendas.pendencia_financeira,
-- public.rg_vendas_lotes.pendencias_financeiras.
--
-- Colunas novas nesta migration (aditivas, nullable, auditoria de
-- resolução manual — nunca preenchidas pela função, só pela ação
-- de "marcar como resolvida" feita depois, fora desta função):
-- public.rg_vendas.pendencia_financeira_resolvida_por (uuid);
-- public.rg_vendas.pendencia_financeira_resolvida_em (timestamptz).
--
-- INVARIANTE — esta migration e a função que ela recria NUNCA
-- inserem, atualizam ou de qualquer forma tocam public.rg_financeiro.
-- Nenhum ajuste financeiro automático é criado. A correção do
-- lançamento já existente é sempre manual, fora do escopo desta
-- função — a função só sinaliza a pendência.
--
-- NAO EXECUTAR sem autorizacao explicita. Validar exclusivamente
-- no projeto Supabase DEV antes de qualquer aplicação em produção.
--
-- Depende de: 0003_v6_lotes_importacao_hotmart.sql (colunas
-- pendencia_financeira/pendencias_financeiras), 0005_v8_...sql
-- (public.rg_reprocessar_lote, que esta migration substitui por
-- create or replace — mesma assinatura, mesma segurança).
-- ============================================================

BEGIN;

-- ===== AUDITORIA DE RESOLUÇÃO DE PENDÊNCIA (aditivo, nullable) =====
alter table public.rg_vendas add column if not exists pendencia_financeira_resolvida_por uuid references public.profiles(user_id) on delete set null;
alter table public.rg_vendas add column if not exists pendencia_financeira_resolvida_em timestamptz;

create or replace function public.rg_reprocessar_lote(
  p_lote_original_id bigint,
  p_novo_lote_id bigint,
  p_total_linhas int,
  p_itens jsonb,
  p_rejeicoes jsonb
)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_lote_original record;
  v_lote_novo record;
  v_item jsonb;
  v_venda record;
  v_venda_id bigint;
  v_dup_id bigint;
  v_total_vendas_lote int;
  v_atualizadas int := 0;
  v_alt_status int := 0;
  v_alt_valor int := 0;
  v_alt_liquido int := 0;
  v_inalteradas int := 0;
  v_pendencias int := 0;
  v_status_atual text;
  v_novo_status text;
  v_novo_valor numeric;
  v_novo_liquido numeric;
  v_final_status text;
  v_final_valor numeric;
  v_final_liquido numeric;
  v_mudou boolean;
  v_linhas int;
  v_linhas_erro int;
  v_erro_original text;
  v_sqlstate_original text;
begin
  if not public.rg_is_admin() then
    raise exception 'somente administradores podem reprocessar importações';
  end if;

  select * into v_lote_novo from public.rg_vendas_lotes where id = p_novo_lote_id for update;
  if not found then
    raise exception 'lote de reprocessamento % não encontrado', p_novo_lote_id;
  end if;
  if v_lote_novo.status <> 'processando' then
    raise exception 'lote de reprocessamento % não está em processando (status atual: %) — não será modificado', p_novo_lote_id, v_lote_novo.status;
  end if;

  -- a partir daqui o lote novo existe e está genuinamente 'processando':
  -- é seguro tentar marcá-lo como 'erro' se qualquer coisa a seguir falhar
  begin
    if v_lote_novo.reprocessa_lote_id is distinct from p_lote_original_id then
      raise exception 'lote de reprocessamento % não referencia o lote original % informado', p_novo_lote_id, p_lote_original_id;
    end if;

    select * into v_lote_original from public.rg_vendas_lotes where id = p_lote_original_id for update;
    if not found then
      raise exception 'lote original % não encontrado', p_lote_original_id;
    end if;
    if v_lote_original.status <> 'ativo' then
      raise exception 'lote original % não está ativo (status atual: %)', p_lote_original_id, v_lote_original.status;
    end if;

    select count(*) into v_total_vendas_lote from public.rg_vendas where lote_id = p_lote_original_id;
    if v_total_vendas_lote = 0 then
      raise exception 'lote original % não possui nenhuma venda vinculada — sem escopo para reprocessamento', p_lote_original_id;
    end if;

    if p_itens is null or jsonb_typeof(p_itens) <> 'array' then
      raise exception 'p_itens deve ser um array JSON, recebido: %', coalesce(jsonb_typeof(p_itens), 'null');
    end if;
    p_rejeicoes := coalesce(p_rejeicoes, '[]'::jsonb);
    if jsonb_typeof(p_rejeicoes) <> 'array' then
      raise exception 'p_rejeicoes deve ser um array JSON, recebido: %', jsonb_typeof(p_rejeicoes);
    end if;
    if p_total_linhas is null or p_total_linhas < 0 then
      raise exception 'p_total_linhas inválido: %', p_total_linhas;
    end if;
    if jsonb_array_length(p_itens) + jsonb_array_length(p_rejeicoes) <> p_total_linhas then
      raise exception 'invariante de contagem violada: p_itens (%) + p_rejeicoes (%) != p_total_linhas (%)',
        jsonb_array_length(p_itens), jsonb_array_length(p_rejeicoes), p_total_linhas;
    end if;

    -- passo 1: valida estrutura de cada item, sem processar ainda
    for v_item in select * from jsonb_array_elements(p_itens)
    loop
      if jsonb_typeof(v_item) <> 'object' then
        raise exception 'item de p_itens não é um objeto JSON válido: %', v_item;
      end if;
      if not (v_item ? 'venda_id') or trim(coalesce(v_item->>'venda_id', '')) = '' then
        raise exception 'item de p_itens sem venda_id válido: %', v_item;
      end if;
      if not (v_item ? 'status') then
        raise exception 'item de p_itens (venda_id=%) sem a chave "status" — payload incompleto', v_item->>'venda_id';
      end if;
      if not (v_item ? 'valor') then
        raise exception 'item de p_itens (venda_id=%) sem a chave "valor" — payload incompleto', v_item->>'venda_id';
      end if;
      if not (v_item ? 'liquido') then
        raise exception 'item de p_itens (venda_id=%) sem a chave "liquido" — payload incompleto', v_item->>'venda_id';
      end if;
      perform (v_item->>'venda_id')::bigint;
    end loop;

    -- passo 2: só agora, com todo item validado, detectar duplicata
    select (elem->>'venda_id')::bigint into v_dup_id
      from jsonb_array_elements(p_itens) elem
      group by (elem->>'venda_id')::bigint
      having count(*) > 1
      limit 1;
    if v_dup_id is not null then
      raise exception 'venda_id % aparece mais de uma vez em p_itens — cada venda só pode ser processada uma vez por chamada', v_dup_id;
    end if;

    -- passo 3: processamento real
    for v_item in select * from jsonb_array_elements(p_itens)
    loop
      v_venda_id := (v_item->>'venda_id')::bigint;

      select id, status, valor, liquido, excluido, lote_id, fin_lancado, pendencia_financeira
        into v_venda from public.rg_vendas where id = v_venda_id for update;

      if not found then
        raise exception 'venda_id % informado em p_itens não existe em rg_vendas', v_venda_id;
      end if;
      if v_venda.lote_id is distinct from p_lote_original_id then
        raise exception 'venda_id % não pertence ao lote original % (lote atual: %)', v_venda_id, p_lote_original_id, v_venda.lote_id;
      end if;
      if v_venda.excluido then
        raise exception 'venda_id % está marcada como excluída e não pode ser reprocessada', v_venda_id;
      end if;

      v_status_atual := nullif(trim(coalesce(v_venda.status, '')), '');
      v_novo_status := nullif(trim(coalesce(v_item->>'status', '')), '');
      v_novo_valor := nullif(trim(v_item->>'valor'), '')::numeric;
      v_novo_liquido := nullif(trim(v_item->>'liquido'), '')::numeric;

      v_final_status := v_venda.status;
      v_final_valor := v_venda.valor;
      v_final_liquido := v_venda.liquido;
      v_mudou := false;

      if v_novo_status is not null and v_novo_status is distinct from v_status_atual then
        insert into public.rg_vendas_alteracoes_historico (venda_id, lote_id, campo, valor_anterior, valor_novo, fin_lancado_no_momento)
        values (v_venda.id, p_novo_lote_id, 'status', v_venda.status, v_novo_status, v_venda.fin_lancado);
        v_final_status := v_novo_status; v_alt_status := v_alt_status + 1; v_mudou := true;
      end if;

      if v_novo_valor is not null and (v_venda.valor is null or abs(v_venda.valor - v_novo_valor) > 0.005) then
        insert into public.rg_vendas_alteracoes_historico (venda_id, lote_id, campo, valor_anterior, valor_novo, fin_lancado_no_momento)
        values (
          v_venda.id, p_novo_lote_id, 'valor',
          case when v_venda.valor is null then null else trim(to_char(round(v_venda.valor,2), 'FM999999999990.00')) end,
          trim(to_char(round(v_novo_valor,2), 'FM999999999990.00')),
          v_venda.fin_lancado
        );
        v_final_valor := v_novo_valor; v_alt_valor := v_alt_valor + 1; v_mudou := true;
      end if;

      if v_novo_liquido is not null and (v_venda.liquido is null or abs(v_venda.liquido - v_novo_liquido) > 0.005) then
        insert into public.rg_vendas_alteracoes_historico (venda_id, lote_id, campo, valor_anterior, valor_novo, fin_lancado_no_momento)
        values (
          v_venda.id, p_novo_lote_id, 'liquido',
          case when v_venda.liquido is null then null else trim(to_char(round(v_venda.liquido,2), 'FM999999999990.00')) end,
          trim(to_char(round(v_novo_liquido,2), 'FM999999999990.00')),
          v_venda.fin_lancado
        );
        v_final_liquido := v_novo_liquido; v_alt_liquido := v_alt_liquido + 1; v_mudou := true;
      end if;

      if v_mudou then
        -- pendência financeira: só quando a venda já estava lançada no
        -- financeiro E realmente mudou algo agora. Nunca toca em
        -- rg_financeiro, nunca cria ajuste — só sinaliza. Uma pendência
        -- nova sempre limpa qualquer resolução anterior (resolvida_por/
        -- resolvida_em), porque essa resolução não se aplica mais à
        -- divergência atual.
        if v_venda.fin_lancado then
          if not v_venda.pendencia_financeira then
            v_pendencias := v_pendencias + 1;
          end if;
          update public.rg_vendas
            set status = v_final_status, valor = v_final_valor, liquido = v_final_liquido,
                ultima_atualizacao_lote_id = p_novo_lote_id, atualizado_em = now(),
                pendencia_financeira = true,
                pendencia_financeira_resolvida_por = null,
                pendencia_financeira_resolvida_em = null
            where id = v_venda.id;
        else
          update public.rg_vendas
            set status = v_final_status, valor = v_final_valor, liquido = v_final_liquido,
                ultima_atualizacao_lote_id = p_novo_lote_id, atualizado_em = now()
            where id = v_venda.id;
        end if;
        get diagnostics v_linhas = row_count;
        if v_linhas <> 1 then
          raise exception 'UPDATE da venda_id % afetou % linha(s) (esperado 1)', v_venda.id, v_linhas;
        end if;
        v_atualizadas := v_atualizadas + 1;
      else
        v_inalteradas := v_inalteradas + 1;
      end if;
    end loop;

    update public.rg_vendas_lotes
      set status = 'ativo', total_linhas = p_total_linhas,
          atualizadas = v_atualizadas, inalteradas = v_inalteradas,
          rejeitadas = jsonb_array_length(p_rejeicoes), rejeicoes = p_rejeicoes::text,
          alteracoes_status = v_alt_status, alteracoes_valor = v_alt_valor, alteracoes_liquido = v_alt_liquido,
          pendencias_financeiras = v_pendencias
      where id = p_novo_lote_id;
    get diagnostics v_linhas = row_count;
    if v_linhas <> 1 then
      raise exception 'UPDATE de ativação do lote % afetou % linha(s) (esperado 1)', p_novo_lote_id, v_linhas;
    end if;

    return jsonb_build_object('ok', true, 'atualizadas', v_atualizadas, 'inalteradas', v_inalteradas,
      'alteracoes_status', v_alt_status, 'alteracoes_valor', v_alt_valor, 'alteracoes_liquido', v_alt_liquido,
      'pendencias_financeiras', v_pendencias,
      'rejeitadas', jsonb_array_length(p_rejeicoes));

  exception when others then
    v_erro_original := SQLERRM;
    v_sqlstate_original := SQLSTATE;

    begin
      update public.rg_vendas_lotes
        set status = 'erro', erro_detalhe = v_erro_original
        where id = p_novo_lote_id;

      get diagnostics v_linhas_erro = row_count;

      if v_linhas_erro = 1 then
        return jsonb_build_object(
          'ok', false,
          'erro', v_erro_original,
          'sqlstate', v_sqlstate_original,
          'lote_marcado_como_erro', true
        );
      end if;

      return jsonb_build_object(
        'ok', false,
        'erro', v_erro_original,
        'sqlstate', v_sqlstate_original,
        'lote_marcado_como_erro', false,
        'detalhe_marcacao',
        'UPDATE afetou ' || v_linhas_erro || ' linha(s) (esperado 1)'
      );

    exception when others then
      return jsonb_build_object(
        'ok', false,
        'erro', v_erro_original,
        'sqlstate', v_sqlstate_original,
        'lote_marcado_como_erro', false,
        'erro_ao_marcar', SQLERRM
      );
    end;
  end;
end;
$$;

revoke execute on function public.rg_reprocessar_lote(
  bigint,bigint,int,jsonb,jsonb
) from public, anon, service_role;

grant execute on function public.rg_reprocessar_lote(
  bigint,bigint,int,jsonb,jsonb
) to authenticated;

COMMIT;
