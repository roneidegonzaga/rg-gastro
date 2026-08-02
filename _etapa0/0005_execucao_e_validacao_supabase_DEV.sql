-- ============================================================
-- SCRIPT DE EXECUÇÃO E VALIDAÇÃO — Migration 0005 (Etapa 1B.3)
-- Rodar SOMENTE contra o projeto Supabase "rg-gastro-DEV",
-- confirmando visualmente o nome do projeto no painel antes de
-- colar qualquer coisa aqui.
--
-- Estratégia A (única transação): a função só permanece aplicada
-- se TODOS os testes passarem E toda a limpeza das fixtures for
-- confirmada. Qualquer reprovação — de teste ou de limpeza —
-- desfaz tudo, inclusive a criação da função, via ROLLBACK
-- automático de uma exceção não capturada.
--
-- NÃO é a migration em si — a migration "de verdade" continua
-- sendo _etapa0/migrations/0005_v8_rpc_reprocessamento_transacional.sql
-- (a função abaixo é uma cópia idêntica, incluindo as duas
-- correções mais recentes: bloco aninhado de exceção ao marcar
-- erro, e checagem de lote original sem vendas vinculadas).
--
-- Sobre o teste do caminho "falha real ao marcar erro" (não só
-- 0 linhas afetadas): não incluído como teste executável — exigiria
-- concorrência real de outra sessão ou enfraquecer RLS/schema
-- deliberadamente para provocar. Validado por inspeção do código
-- (ver bloco EXCEPTION aninhado na função), não por execução aqui.
--
-- PASSO 0 (autenticação de teste): a função exige rg_is_admin() =
-- true, que depende de auth.uid() — inexistente no contexto do SQL
-- Editor (conecta direto, fora do PostgREST). Por isso o bloco de
-- testes abaixo localiza dinamicamente um admin real e aprovado em
-- public.profiles e usa set_config('request.jwt.claim.sub', ...,
-- true) / set_config('request.jwt.claims', ..., true) — is_local=
-- true garante que a configuração vale só dentro desta transação,
-- revertendo sozinha no COMMIT ou ROLLBACK, sem exigir limpeza
-- manual. Se não houver admin aprovado no ambiente, o script falha
-- explicitamente antes de criar qualquer fixture (nenhuma venda ou
-- lote de teste chega a ser inserido).
--
-- TESTE L (checagem interna de não-admin): valida só o "if not
-- rg_is_admin() then raise exception" dentro da própria função,
-- usando um uid sem perfil correspondente. NÃO valida RLS real —
-- o SQL Editor roda como role privilegiada, que ignora RLS
-- independentemente do auth.uid() simulado. O teste de um usuário
-- authenticated não-admin sendo bloqueado pelas policies de RLS
-- continua obrigatório, feito separadamente pela aplicação.
--
-- CORREÇÃO DE PERMISSÕES (pós primeira execução real no DEV): o
-- REVOKE EXECUTE ... FROM PUBLIC sozinho não bastou — o Supabase
-- concede EXECUTE em toda função nova no schema public a
-- anon/authenticated/service_role via ALTER DEFAULT PRIVILEGES do
-- projeto, e esses são grants explícitos e individuais, não apenas
-- herdados de PUBLIC. Confirmado no DEV: a consulta de ACL mostrou
-- anon=X/postgres e service_role=X/postgres mesmo após o REVOKE FROM
-- PUBLIC. Corrigido nomeando public, anon e service_role
-- explicitamente no REVOKE (Parte 1) e validado agora por um teste
-- de catálogo (TESTE M, via has_function_privilege()/aclexplode() —
-- não por leitura manual do ACL).
-- ============================================================

BEGIN;

-- ===== PARTE 1: A FUNÇÃO (corpo integral, idêntico à migration) =====

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

    select (elem->>'venda_id')::bigint into v_dup_id
      from jsonb_array_elements(p_itens) elem
      group by (elem->>'venda_id')::bigint
      having count(*) > 1
      limit 1;
    if v_dup_id is not null then
      raise exception 'venda_id % aparece mais de uma vez em p_itens — cada venda só pode ser processada uma vez por chamada', v_dup_id;
    end if;

    for v_item in select * from jsonb_array_elements(p_itens)
    loop
      v_venda_id := (v_item->>'venda_id')::bigint;

      select id, status, valor, liquido, excluido, lote_id, fin_lancado
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
        update public.rg_vendas
          set status = v_final_status, valor = v_final_valor, liquido = v_final_liquido,
              ultima_atualizacao_lote_id = p_novo_lote_id, atualizado_em = now()
          where id = v_venda.id;
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
          alteracoes_status = v_alt_status, alteracoes_valor = v_alt_valor, alteracoes_liquido = v_alt_liquido
      where id = p_novo_lote_id;
    get diagnostics v_linhas = row_count;
    if v_linhas <> 1 then
      raise exception 'UPDATE de ativação do lote % afetou % linha(s) (esperado 1)', p_novo_lote_id, v_linhas;
    end if;

    return jsonb_build_object('ok', true, 'atualizadas', v_atualizadas, 'inalteradas', v_inalteradas,
      'alteracoes_status', v_alt_status, 'alteracoes_valor', v_alt_valor, 'alteracoes_liquido', v_alt_liquido,
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

-- ===== PARTE 2: FIXTURES, TESTES E LIMPEZA =====

DO $$
DECLARE
  v_lote_original bigint;
  v_lote_outro bigint;
  v_lote_vazio bigint;
  v_venda1 bigint; v_venda2 bigint; v_venda3 bigint; v_venda4_excluida bigint; v_venda5_outro_lote bigint;
  v_lote_novo bigint;
  v_resp jsonb;
  v_venda_check record;
  v_lote_check record;
  v_falhas int := 0;
  v_motivos text := '';
  v_vendas_teste bigint[];
  v_lotes_teste bigint[] := '{}';
  v_residual int;
  v_admin_id uuid;
  v_uid_falso uuid;
  v_proacl aclitem[];
  v_execute_public boolean;
  v_execute_anon boolean;
  v_execute_service boolean;
  v_execute_authenticated boolean;
BEGIN
  -- PASSO 0: localizar um admin real aprovado no próprio DEV.
  -- Sem isso, os testes da RPC (que exige rg_is_admin() = true) não
  -- podem prosseguir com segurança — e nenhuma fixture é criada.
  select user_id into v_admin_id
  from public.profiles
  where role = 'admin' and aprovado = true
  order by criado_em asc
  limit 1;

  if v_admin_id is null then
    raise exception 'MIGRATION 0005: nenhum perfil admin aprovado encontrado em public.profiles neste ambiente — impossível testar rg_reprocessar_lote() com segurança. Nenhuma fixture foi criada.';
  end if;

  -- contexto de autenticação válido SOMENTE dentro desta transação
  -- (set_config com is_local=true reverte sozinho no COMMIT/ROLLBACK,
  -- nada precisa ser limpo manualmente aqui)
  perform set_config('request.jwt.claim.sub', v_admin_id::text, true);
  perform set_config('request.jwt.claims', jsonb_build_object('sub', v_admin_id::text, 'role', 'authenticated')::text, true);

  raise notice '=== contexto de teste: autenticado como admin real user_id=% (válido só nesta transação) ===', v_admin_id;

  -- TESTE M: permissões da função, por catálogo (não por leitura
  -- manual do ACL). has_function_privilege() reflete o privilégio
  -- EFETIVO do role (inclui o que ele herdaria de PUBLIC); o grantee
  -- 0 em aclexplode() representa PUBLIC especificamente, que não tem
  -- um role real para consultar via has_function_privilege().
  select proacl into v_proacl
  from pg_proc
  where pronamespace = 'public'::regnamespace and proname = 'rg_reprocessar_lote';

  select coalesce(bool_or(a.privilege_type = 'EXECUTE'), false) into v_execute_public
  from aclexplode(v_proacl) a
  where a.grantee = 0;

  v_execute_anon := has_function_privilege('anon', 'public.rg_reprocessar_lote(bigint,bigint,int,jsonb,jsonb)', 'EXECUTE');
  v_execute_service := has_function_privilege('service_role', 'public.rg_reprocessar_lote(bigint,bigint,int,jsonb,jsonb)', 'EXECUTE');
  v_execute_authenticated := has_function_privilege('authenticated', 'public.rg_reprocessar_lote(bigint,bigint,int,jsonb,jsonb)', 'EXECUTE');

  if v_execute_public then
    v_falhas := v_falhas + 1; v_motivos := v_motivos || E'\n- TESTE M reprovado: PUBLIC possui EXECUTE';
  end if;
  if v_execute_anon then
    v_falhas := v_falhas + 1; v_motivos := v_motivos || E'\n- TESTE M reprovado: anon possui EXECUTE';
  end if;
  if v_execute_service then
    v_falhas := v_falhas + 1; v_motivos := v_motivos || E'\n- TESTE M reprovado: service_role possui EXECUTE';
  end if;
  if not v_execute_authenticated then
    v_falhas := v_falhas + 1; v_motivos := v_motivos || E'\n- TESTE M reprovado: authenticated NÃO possui EXECUTE (esperado ter)';
  end if;
  if not v_execute_public and not v_execute_anon and not v_execute_service and v_execute_authenticated then
    raise notice 'TESTE M (permissões: só authenticated com EXECUTE — public/anon/service_role sem) aprovado';
  end if;

  -- TESTE 0: formato canônico do histórico
  if trim(to_char(round(297::numeric,2), 'FM999999999990.00')) = '297.00'
     and trim(to_char(round(297.5::numeric,2), 'FM999999999990.00')) = '297.50'
     and trim(to_char(round(297.00::numeric,2), 'FM999999999990.00')) = '297.00'
     and trim(to_char(round(-10.25::numeric,2), 'FM999999999990.00')) = '-10.25'
     and trim(to_char(round(0::numeric,2), 'FM999999999990.00')) = '0.00'
  then raise notice 'TESTE 0 (formato canônico) aprovado';
  else v_falhas := v_falhas + 1; v_motivos := v_motivos || E'\n- TESTE 0 (formato canônico) reprovado'; end if;

  -- FIXTURES
  insert into public.rg_vendas_lotes (arquivo_nome, status) values ('__teste_1B3_lote_original__.csv', 'ativo') returning id into v_lote_original;
  insert into public.rg_vendas_lotes (arquivo_nome, status) values ('__teste_1B3_outro_lote__.csv', 'ativo') returning id into v_lote_outro;
  insert into public.rg_vendas_lotes (arquivo_nome, status) values ('__teste_1B3_lote_vazio__.csv', 'ativo') returning id into v_lote_vazio;
  v_lotes_teste := array[v_lote_original, v_lote_outro, v_lote_vazio];

  insert into public.rg_vendas (transacao, produto, nome, status, valor, liquido, fin_lancado, lote_id, importacao_concluida)
    values ('__TESTE1B3_TX1__','Produto Teste','Fulano','Completo',100.00,90.00,false,v_lote_original,true) returning id into v_venda1;
  insert into public.rg_vendas (transacao, produto, nome, status, valor, liquido, fin_lancado, lote_id, importacao_concluida)
    values ('__TESTE1B3_TX2__','Produto Teste','Fulano','Completo',50.00,45.00,false,v_lote_original,true) returning id into v_venda2;
  insert into public.rg_vendas (transacao, produto, nome, status, valor, liquido, fin_lancado, lote_id, importacao_concluida)
    values ('__TESTE1B3_TX3__','Produto Teste','Fulano','Aprovado',200.00,180.00,false,v_lote_original,true) returning id into v_venda3;
  insert into public.rg_vendas (transacao, produto, nome, status, valor, liquido, fin_lancado, lote_id, importacao_concluida, excluido)
    values ('__TESTE1B3_TX4__','Produto Teste','Fulano','Completo',10.00,9.00,false,v_lote_original,true,true) returning id into v_venda4_excluida;
  insert into public.rg_vendas (transacao, produto, nome, status, valor, liquido, fin_lancado, lote_id, importacao_concluida)
    values ('__TESTE1B3_TX5__','Produto Teste','Fulano','Completo',20.00,18.00,false,v_lote_outro,true) returning id into v_venda5_outro_lote;
  v_vendas_teste := array[v_venda1, v_venda2, v_venda3, v_venda4_excluida, v_venda5_outro_lote];

  raise notice '=== fixtures: lote_original=%, lote_outro=%, lote_vazio=%, vendas=%,%,%,%(excluída),%(outro lote) ===',
    v_lote_original, v_lote_outro, v_lote_vazio, v_venda1, v_venda2, v_venda3, v_venda4_excluida, v_venda5_outro_lote;

  -- TESTE A: item inalterado
  insert into public.rg_vendas_lotes (arquivo_nome, status, reprocessa_lote_id) values ('__teste_A__.csv','processando', v_lote_original) returning id into v_lote_novo;
  v_lotes_teste := v_lotes_teste || v_lote_novo;
  v_resp := public.rg_reprocessar_lote(v_lote_original, v_lote_novo, 1,
    jsonb_build_array(jsonb_build_object('venda_id', v_venda1, 'status', 'Completo', 'valor', '100.00', 'liquido', '90.00')), '[]'::jsonb);
  select * into v_venda_check from public.rg_vendas where id = v_venda1;
  select * into v_lote_check from public.rg_vendas_lotes where id = v_lote_novo;
  if (v_resp->>'ok')::boolean and (v_resp->>'inalteradas')::int = 1 and (v_resp->>'atualizadas')::int = 0
     and v_venda_check.status = 'Completo' and v_venda_check.valor = 100.00 and v_venda_check.liquido = 90.00
     and v_venda_check.ultima_atualizacao_lote_id is null
     and v_lote_check.status = 'ativo' and v_lote_check.inalteradas = 1 and v_lote_check.atualizadas = 0
  then raise notice 'TESTE A (inalterado) aprovado';
  else v_falhas := v_falhas + 1; v_motivos := v_motivos || E'\n- TESTE A reprovado: ' || v_resp::text; end if;

  -- TESTE B: alteração de status
  insert into public.rg_vendas_lotes (arquivo_nome, status, reprocessa_lote_id) values ('__teste_B__.csv','processando', v_lote_original) returning id into v_lote_novo;
  v_lotes_teste := v_lotes_teste || v_lote_novo;
  v_resp := public.rg_reprocessar_lote(v_lote_original, v_lote_novo, 1,
    jsonb_build_array(jsonb_build_object('venda_id', v_venda2, 'status', 'Aprovado', 'valor', '50.00', 'liquido', '45.00')), '[]'::jsonb);
  select * into v_venda_check from public.rg_vendas where id = v_venda2;
  select * into v_lote_check from public.rg_vendas_lotes where id = v_lote_novo;
  if (v_resp->>'ok')::boolean and (v_resp->>'atualizadas')::int = 1 and (v_resp->>'alteracoes_status')::int = 1
     and v_venda_check.status = 'Aprovado' and v_venda_check.valor = 50.00 and v_venda_check.liquido = 45.00
     and v_venda_check.lote_id = v_lote_original and v_venda_check.ultima_atualizacao_lote_id = v_lote_novo
     and v_venda_check.atualizado_em is not null
     and v_lote_check.status = 'ativo' and v_lote_check.atualizadas = 1 and v_lote_check.alteracoes_status = 1
     and v_lote_check.alteracoes_valor = 0 and v_lote_check.alteracoes_liquido = 0
  then raise notice 'TESTE B (status) aprovado';
  else v_falhas := v_falhas + 1; v_motivos := v_motivos || E'\n- TESTE B reprovado: ' || v_resp::text; end if;

  perform 1 from public.rg_vendas_alteracoes_historico
    where venda_id = v_venda2 and lote_id = v_lote_novo and campo = 'status'
      and valor_anterior = 'Completo' and valor_novo = 'Aprovado' and fin_lancado_no_momento = false;
  if found then raise notice 'TESTE B histórico OK';
  else v_falhas := v_falhas + 1; v_motivos := v_motivos || E'\n- TESTE B histórico ausente/incorreto'; end if;

  -- TESTE C: alteração de valor e líquido juntos
  insert into public.rg_vendas_lotes (arquivo_nome, status, reprocessa_lote_id) values ('__teste_C__.csv','processando', v_lote_original) returning id into v_lote_novo;
  v_lotes_teste := v_lotes_teste || v_lote_novo;
  v_resp := public.rg_reprocessar_lote(v_lote_original, v_lote_novo, 1,
    jsonb_build_array(jsonb_build_object('venda_id', v_venda3, 'status', 'Aprovado', 'valor', '210.00', 'liquido', '190.00')), '[]'::jsonb);
  select * into v_venda_check from public.rg_vendas where id = v_venda3;
  if (v_resp->>'ok')::boolean and (v_resp->>'atualizadas')::int = 1
     and (v_resp->>'alteracoes_valor')::int = 1 and (v_resp->>'alteracoes_liquido')::int = 1
     and v_venda_check.valor = 210.00 and v_venda_check.liquido = 190.00
     and v_venda_check.lote_id = v_lote_original and v_venda_check.ultima_atualizacao_lote_id = v_lote_novo
  then raise notice 'TESTE C (valor+líquido) aprovado';
  else v_falhas := v_falhas + 1; v_motivos := v_motivos || E'\n- TESTE C reprovado: ' || v_resp::text; end if;

  perform 1 from public.rg_vendas_alteracoes_historico where venda_id = v_venda3 and lote_id = v_lote_novo and campo = 'valor' and valor_anterior = '200.00' and valor_novo = '210.00';
  if not found then v_falhas := v_falhas + 1; v_motivos := v_motivos || E'\n- TESTE C histórico de valor incorreto'; end if;
  perform 1 from public.rg_vendas_alteracoes_historico where venda_id = v_venda3 and lote_id = v_lote_novo and campo = 'liquido' and valor_anterior = '180.00' and valor_novo = '190.00';
  if not found then v_falhas := v_falhas + 1; v_motivos := v_motivos || E'\n- TESTE C histórico de líquido incorreto'; end if;

  -- TESTE D: venda_id duplicado
  insert into public.rg_vendas_lotes (arquivo_nome, status, reprocessa_lote_id) values ('__teste_D__.csv','processando', v_lote_original) returning id into v_lote_novo;
  v_lotes_teste := v_lotes_teste || v_lote_novo;
  v_resp := public.rg_reprocessar_lote(v_lote_original, v_lote_novo, 2,
    jsonb_build_array(
      jsonb_build_object('venda_id', v_venda1, 'status', 'Completo', 'valor', '100.00', 'liquido', '90.00'),
      jsonb_build_object('venda_id', v_venda1, 'status', 'Aprovado', 'valor', '100.00', 'liquido', '90.00')
    ), '[]'::jsonb);
  select * into v_lote_check from public.rg_vendas_lotes where id = v_lote_novo;
  if not (v_resp->>'ok')::boolean and v_resp->>'erro' like '%mais de uma vez%' and v_lote_check.status = 'erro'
  then raise notice 'TESTE D (duplicado) aprovado';
  else v_falhas := v_falhas + 1; v_motivos := v_motivos || E'\n- TESTE D reprovado: ' || v_resp::text; end if;

  -- TESTE E: venda de outro lote
  insert into public.rg_vendas_lotes (arquivo_nome, status, reprocessa_lote_id) values ('__teste_E__.csv','processando', v_lote_original) returning id into v_lote_novo;
  v_lotes_teste := v_lotes_teste || v_lote_novo;
  v_resp := public.rg_reprocessar_lote(v_lote_original, v_lote_novo, 1,
    jsonb_build_array(jsonb_build_object('venda_id', v_venda5_outro_lote, 'status', 'Completo', 'valor', '20.00', 'liquido', '18.00')), '[]'::jsonb);
  select * into v_venda_check from public.rg_vendas where id = v_venda5_outro_lote;
  select * into v_lote_check from public.rg_vendas_lotes where id = v_lote_novo;
  if not (v_resp->>'ok')::boolean and v_resp->>'erro' like '%não pertence ao lote original%'
     and v_lote_check.status = 'erro' and v_venda_check.lote_id = v_lote_outro
  then raise notice 'TESTE E (outro lote) aprovado';
  else v_falhas := v_falhas + 1; v_motivos := v_motivos || E'\n- TESTE E reprovado: ' || v_resp::text; end if;

  -- TESTE F: venda excluída
  insert into public.rg_vendas_lotes (arquivo_nome, status, reprocessa_lote_id) values ('__teste_F__.csv','processando', v_lote_original) returning id into v_lote_novo;
  v_lotes_teste := v_lotes_teste || v_lote_novo;
  v_resp := public.rg_reprocessar_lote(v_lote_original, v_lote_novo, 1,
    jsonb_build_array(jsonb_build_object('venda_id', v_venda4_excluida, 'status', 'Completo', 'valor', '10.00', 'liquido', '9.00')), '[]'::jsonb);
  select * into v_venda_check from public.rg_vendas where id = v_venda4_excluida;
  select * into v_lote_check from public.rg_vendas_lotes where id = v_lote_novo;
  if not (v_resp->>'ok')::boolean and v_resp->>'erro' like '%excluída%'
     and v_lote_check.status = 'erro' and v_venda_check.excluido = true
  then raise notice 'TESTE F (excluída) aprovado';
  else v_falhas := v_falhas + 1; v_motivos := v_motivos || E'\n- TESTE F reprovado: ' || v_resp::text; end if;

  -- TESTE G: invariante de contagem violada
  insert into public.rg_vendas_lotes (arquivo_nome, status, reprocessa_lote_id) values ('__teste_G__.csv','processando', v_lote_original) returning id into v_lote_novo;
  v_lotes_teste := v_lotes_teste || v_lote_novo;
  v_resp := public.rg_reprocessar_lote(v_lote_original, v_lote_novo, 99,
    jsonb_build_array(jsonb_build_object('venda_id', v_venda1, 'status', 'Completo', 'valor', '100.00', 'liquido', '90.00')), '[]'::jsonb);
  select * into v_lote_check from public.rg_vendas_lotes where id = v_lote_novo;
  if not (v_resp->>'ok')::boolean and v_resp->>'erro' like '%invariante%' and v_lote_check.status = 'erro'
  then raise notice 'TESTE G (invariante) aprovado';
  else v_falhas := v_falhas + 1; v_motivos := v_motivos || E'\n- TESTE G reprovado: ' || v_resp::text; end if;

  -- TESTE H: valor numérico inválido
  insert into public.rg_vendas_lotes (arquivo_nome, status, reprocessa_lote_id) values ('__teste_H__.csv','processando', v_lote_original) returning id into v_lote_novo;
  v_lotes_teste := v_lotes_teste || v_lote_novo;
  v_resp := public.rg_reprocessar_lote(v_lote_original, v_lote_novo, 1,
    jsonb_build_array(jsonb_build_object('venda_id', v_venda1, 'status', 'Completo', 'valor', 'abc', 'liquido', '90.00')), '[]'::jsonb);
  select * into v_lote_check from public.rg_vendas_lotes where id = v_lote_novo;
  if not (v_resp->>'ok')::boolean and v_lote_check.status = 'erro'
  then raise notice 'TESTE H (valor inválido) aprovado';
  else v_falhas := v_falhas + 1; v_motivos := v_motivos || E'\n- TESTE H reprovado: ' || v_resp::text; end if;

  -- TESTE I: rollback integral (item válido + item inválido no mesmo payload)
  insert into public.rg_vendas_lotes (arquivo_nome, status, reprocessa_lote_id) values ('__teste_I__.csv','processando', v_lote_original) returning id into v_lote_novo;
  v_lotes_teste := v_lotes_teste || v_lote_novo;
  v_resp := public.rg_reprocessar_lote(v_lote_original, v_lote_novo, 2,
    jsonb_build_array(
      jsonb_build_object('venda_id', v_venda1, 'status', 'Aprovado', 'valor', '999.00', 'liquido', '999.00'),
      jsonb_build_object('venda_id', v_venda5_outro_lote, 'status', 'Completo', 'valor', '20.00', 'liquido', '18.00')
    ), '[]'::jsonb);
  select * into v_venda_check from public.rg_vendas where id = v_venda1;
  select count(*) into v_residual from public.rg_vendas_alteracoes_historico where venda_id = v_venda1 and lote_id = v_lote_novo;
  if not (v_resp->>'ok')::boolean
     and v_venda_check.status = 'Completo' and v_venda_check.valor = 100.00 and v_venda_check.liquido = 90.00
     and v_venda_check.ultima_atualizacao_lote_id is null and v_residual = 0
  then raise notice 'TESTE I (rollback integral) aprovado — venda1 intacta, sem histórico residual';
  else v_falhas := v_falhas + 1; v_motivos := v_motivos || E'\n- TESTE I reprovado: resp=' || v_resp::text || ', residual=' || v_residual; end if;

  -- TESTE K: lote original ativo sem vendas vinculadas
  insert into public.rg_vendas_lotes (arquivo_nome, status, reprocessa_lote_id) values ('__teste_K__.csv','processando', v_lote_vazio) returning id into v_lote_novo;
  v_lotes_teste := v_lotes_teste || v_lote_novo;
  v_resp := public.rg_reprocessar_lote(v_lote_vazio, v_lote_novo, 0, '[]'::jsonb, '[]'::jsonb);
  select * into v_lote_check from public.rg_vendas_lotes where id = v_lote_novo;
  if not (v_resp->>'ok')::boolean and v_resp->>'erro' like '%não possui nenhuma venda vinculada%' and v_lote_check.status = 'erro'
  then raise notice 'TESTE K (lote original sem vendas) aprovado';
  else v_falhas := v_falhas + 1; v_motivos := v_motivos || E'\n- TESTE K reprovado: ' || v_resp::text; end if;

  -- TESTE L: uid autenticado sem perfil correspondente é rejeitado
  -- pela checagem inicial (rg_is_admin() = false), sem tocar em
  -- nenhum lote/venda. NÃO substitui o teste via app — ver nota no
  -- cabeçalho do arquivo sobre a diferença entre esta checagem
  -- interna e a RLS real (ignorada pelo role do SQL Editor).
  v_uid_falso := gen_random_uuid(); -- não existe em public.profiles
  perform set_config('request.jwt.claim.sub', v_uid_falso::text, true);
  perform set_config('request.jwt.claims', jsonb_build_object('sub', v_uid_falso::text, 'role', 'authenticated')::text, true);

  begin
    v_resp := public.rg_reprocessar_lote(v_lote_original, -1, 0, '[]'::jsonb, '[]'::jsonb);
    v_falhas := v_falhas + 1;
    v_motivos := v_motivos || E'\n- TESTE L reprovado: deveria ter lançado exceção de admin, retornou: ' || coalesce(v_resp::text, 'null');
  exception when others then
    if SQLERRM like '%somente administradores%' then
      raise notice 'TESTE L (não-admin rejeitado pela checagem interna) aprovado';
    else
      v_falhas := v_falhas + 1;
      v_motivos := v_motivos || E'\n- TESTE L reprovado: erro inesperado — SQLSTATE=' || SQLSTATE || ', mensagem=' || SQLERRM;
    end if;
  end;

  -- restaura o contexto admin para o restante do script (limpeza)
  perform set_config('request.jwt.claim.sub', v_admin_id::text, true);
  perform set_config('request.jwt.claims', jsonb_build_object('sub', v_admin_id::text, 'role', 'authenticated')::text, true);

  raise notice '=== TESTE J (RLS real, role authenticated não-admin): não testável com segurança pelo SQL Editor, que ignora RLS por rodar com role privilegiada — TESTE L acima cobre só a checagem interna da função. Teste via app continua obrigatório antes de considerar a Etapa 1B.3 encerrada. ===';
  raise notice '=== Caminho "falha real ao marcar erro" (bloco EXCEPTION aninhado): não testável sem enfraquecer RLS/schema — validado por inspeção do código. ===';

  -- ===== LIMPEZA EXPLÍCITA DAS FIXTURES =====
  delete from public.rg_vendas_alteracoes_historico where venda_id = any(v_vendas_teste);
  delete from public.rg_vendas where id = any(v_vendas_teste);
  delete from public.rg_vendas_lotes where id = any(v_lotes_teste);

  perform 1 from public.rg_vendas where id = any(v_vendas_teste);
  if found then raise exception 'LIMPEZA INCOMPLETA: ainda existem vendas de teste'; end if;
  perform 1 from public.rg_vendas_lotes where id = any(v_lotes_teste);
  if found then raise exception 'LIMPEZA INCOMPLETA: ainda existem lotes de teste'; end if;
  perform 1 from public.rg_vendas_alteracoes_historico where venda_id = any(v_vendas_teste);
  if found then raise exception 'LIMPEZA INCOMPLETA: ainda existe histórico de teste'; end if;

  raise notice '=== limpeza confirmada: nenhuma fixture residual ===';

  -- ===== VEREDITO FINAL =====
  if v_falhas > 0 then
    raise exception 'MIGRATION 0005: % teste(s) reprovado(s):%', v_falhas, v_motivos;
  end if;

  raise notice 'TODOS OS TESTES DA MIGRATION 0005 FORAM APROVADOS';
END $$;

COMMIT;
-- Só chega aqui se: todos os testes passaram (v_falhas=0) E a limpeza
-- foi confirmada sem resíduo. Qualquer reprovação em qualquer ponto
-- acima já teria abortado a transação inteira antes deste COMMIT —
-- inclusive desfazendo a criação da função.
