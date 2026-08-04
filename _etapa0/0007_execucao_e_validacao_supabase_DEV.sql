-- ============================================================
-- SCRIPT DE EXECUÇÃO E VALIDAÇÃO — Migration 0007 (Etapa 1B.6)
-- Rodar SOMENTE contra o projeto Supabase "rg-gastro-DEV",
-- confirmando visualmente o nome do projeto no painel antes de
-- colar qualquer coisa aqui.
--
-- Estratégia A (única transação): a função só permanece aplicada
-- se TODOS os testes passarem E toda a limpeza das fixtures for
-- confirmada. Qualquer reprovação — de teste ou de limpeza —
-- desfaz tudo, inclusive a criação da função e a coluna nova, via
-- ROLLBACK automático de uma exceção não capturada.
--
-- NÃO é a migration em si — a migration "de verdade" continua
-- sendo _etapa0/migrations/0007_v11_desfazer_lote.sql (o corpo da
-- função abaixo é uma cópia idêntica).
--
-- PASSO 0 (autenticação de teste) e o teste de não-admin reaproveitam
-- exatamente a técnica já validada nas migrations 0005/0006:
-- set_config local à transação com um admin real do próprio DEV.
--
-- public.rg_desfazer_lote não tem um estado intermediário próprio
-- (diferente de rg_reprocessar_lote, que cria um lote 'processando'
-- antes de agir) — ela só transiciona o lote-alvo diretamente de
-- 'ativo' para 'desfeito', ou não faz nada. Por isso, ao contrário
-- da 0005/0006, não existe aqui um "lote a marcar como erro": se
-- qualquer validação falhar, a função retorna {ok:false,...} sem
-- alterar nem o lote nem nenhuma venda — o lote permanece 'ativo',
-- um estado de repouso seguro por si só.
-- ============================================================

BEGIN;

-- ===== PARTE 1: A FUNÇÃO (corpo integral, idêntico à migration) =====

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

-- ===== PARTE 2: FIXTURES, TESTES E LIMPEZA =====

DO $$
DECLARE
  v_admin_id uuid;
  v_uid_falso uuid;
  v_proacl aclitem[];
  v_execute_public boolean;
  v_execute_anon boolean;
  v_execute_service boolean;
  v_execute_authenticated boolean;
  v_falhas int := 0;
  v_motivos text := '';
  v_vendas_teste bigint[] := '{}';
  v_lotes_teste bigint[] := '{}';
  v_financeiro_antes text;
  v_financeiro_depois text;
  v_resp jsonb;
  v_lote_check record;
  v_venda_check record;
  v_hist_antes int;
  v_hist_depois int;

  v_lote_ok bigint;
  v_venda_a bigint;
  v_venda_b bigint;
  v_lote_reproc bigint;

  v_lote_fin bigint;
  v_venda_c bigint;

  v_lote_vazio bigint;

  v_lote_processando bigint;
  v_venda_d bigint;
BEGIN
  -- PASSO 0: localizar um admin real aprovado no próprio DEV.
  select user_id into v_admin_id
  from public.profiles
  where role = 'admin' and aprovado = true
  order by criado_em asc
  limit 1;

  if v_admin_id is null then
    raise exception 'MIGRATION 0007: nenhum perfil admin aprovado encontrado em public.profiles neste ambiente — impossível testar rg_desfazer_lote() com segurança. Nenhuma fixture foi criada.';
  end if;

  perform set_config('request.jwt.claim.sub', v_admin_id::text, true);
  perform set_config('request.jwt.claims', jsonb_build_object('sub', v_admin_id::text, 'role', 'authenticated')::text, true);

  raise notice '=== contexto de teste: autenticado como admin real user_id=% (válido só nesta transação) ===', v_admin_id;

  -- TESTE M: permissões da função, por catálogo (mesma técnica das
  -- migrations 0005/0006 — has_function_privilege()/aclexplode(),
  -- não leitura manual de ACL).
  select proacl into v_proacl
  from pg_proc
  where pronamespace = 'public'::regnamespace and proname = 'rg_desfazer_lote';

  select coalesce(bool_or(a.privilege_type = 'EXECUTE'), false) into v_execute_public
  from aclexplode(v_proacl) a
  where a.grantee = 0;

  v_execute_anon := has_function_privilege('anon', 'public.rg_desfazer_lote(bigint,text)', 'EXECUTE');
  v_execute_service := has_function_privilege('service_role', 'public.rg_desfazer_lote(bigint,text)', 'EXECUTE');
  v_execute_authenticated := has_function_privilege('authenticated', 'public.rg_desfazer_lote(bigint,text)', 'EXECUTE');

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

  -- ===== FIXTURES =====

  -- lote_ok: importação original, ativa, 2 vendas não lançadas.
  -- venda_b simula uma venda que já foi reprocessada uma vez antes
  -- (ultima_atualizacao_lote_id aponta para um lote de reprocessamento
  -- já existente, com histórico próprio) — o desfazimento do lote
  -- ORIGINAL precisa continuar encontrando e ocultando essa venda.
  insert into public.rg_vendas_lotes (arquivo_nome, status) values ('__teste_1B6_lote_ok__.csv', 'ativo') returning id into v_lote_ok;
  v_lotes_teste := v_lotes_teste || v_lote_ok;

  insert into public.rg_vendas (transacao, produto, nome, status, valor, liquido, fin_lancado, lote_id, importacao_concluida)
    values ('__TESTE1B6_TXA__','Produto Teste','Fulano','Completo',100.00,90.00,false,v_lote_ok,true) returning id into v_venda_a;
  insert into public.rg_vendas (transacao, produto, nome, status, valor, liquido, fin_lancado, lote_id, importacao_concluida)
    values ('__TESTE1B6_TXB__','Produto Teste','Fulano','Aprovado',200.00,180.00,false,v_lote_ok,true) returning id into v_venda_b;
  v_vendas_teste := v_vendas_teste || array[v_venda_a, v_venda_b];

  insert into public.rg_vendas_lotes (arquivo_nome, status, reprocessa_lote_id) values ('__teste_1B6_lote_reproc__.csv', 'ativo', v_lote_ok) returning id into v_lote_reproc;
  v_lotes_teste := v_lotes_teste || v_lote_reproc;

  update public.rg_vendas set ultima_atualizacao_lote_id = v_lote_reproc, atualizado_em = now() where id = v_venda_b;
  insert into public.rg_vendas_alteracoes_historico (venda_id, lote_id, campo, valor_anterior, valor_novo, fin_lancado_no_momento)
    values (v_venda_b, v_lote_reproc, 'status', 'Completo', 'Aprovado', false);

  -- lote_fin: 1 venda já lançada no financeiro — deve bloquear o
  -- desfazimento inteiro.
  insert into public.rg_vendas_lotes (arquivo_nome, status) values ('__teste_1B6_lote_fin__.csv', 'ativo') returning id into v_lote_fin;
  v_lotes_teste := v_lotes_teste || v_lote_fin;
  insert into public.rg_vendas (transacao, produto, nome, status, valor, liquido, fin_lancado, lote_id, importacao_concluida)
    values ('__TESTE1B6_TXC__','Produto Teste','Fulano','Completo',300.00,270.00,true,v_lote_fin,true) returning id into v_venda_c;
  v_vendas_teste := v_vendas_teste || v_venda_c;

  -- lote_vazio: ativo, sem vendas vinculadas.
  insert into public.rg_vendas_lotes (arquivo_nome, status) values ('__teste_1B6_lote_vazio__.csv', 'ativo') returning id into v_lote_vazio;
  v_lotes_teste := v_lotes_teste || v_lote_vazio;

  -- lote_processando: status diferente de 'ativo'.
  insert into public.rg_vendas_lotes (arquivo_nome, status) values ('__teste_1B6_lote_processando__.csv', 'processando') returning id into v_lote_processando;
  v_lotes_teste := v_lotes_teste || v_lote_processando;
  insert into public.rg_vendas (transacao, produto, nome, status, valor, liquido, fin_lancado, lote_id, importacao_concluida)
    values ('__TESTE1B6_TXD__','Produto Teste','Fulano','Completo',400.00,360.00,false,v_lote_processando,false) returning id into v_venda_d;
  v_vendas_teste := v_vendas_teste || v_venda_d;

  raise notice '=== fixtures: lote_ok=%, venda_a=%, venda_b=%(reprocessada), lote_reproc=%, lote_fin=%, venda_c=%(lançada), lote_vazio=%, lote_processando=% ===',
    v_lote_ok, v_venda_a, v_venda_b, v_lote_reproc, v_lote_fin, v_venda_c, v_lote_vazio, v_lote_processando;

  -- captura o estado de rg_financeiro ANTES de qualquer chamada da
  -- função (invariante: nunca é tocado)
  select md5(coalesce(string_agg(t::text, '|' order by id), '')) into v_financeiro_antes from public.rg_financeiro t;

  -- TESTE A: motivo vazio/nulo é rejeitado, nada é tocado
  v_resp := public.rg_desfazer_lote(v_lote_ok, null);
  select * into v_lote_check from public.rg_vendas_lotes where id = v_lote_ok;
  select * into v_venda_check from public.rg_vendas where id = v_venda_a;
  if not (v_resp->>'ok')::boolean and v_resp->>'erro' like '%motivo é obrigatório%'
     and v_lote_check.status = 'ativo' and v_venda_check.excluido = false
  then raise notice 'TESTE A (motivo obrigatório) aprovado';
  else v_falhas := v_falhas + 1; v_motivos := v_motivos || E'\n- TESTE A reprovado: ' || v_resp::text; end if;

  v_resp := public.rg_desfazer_lote(v_lote_ok, '   ');
  if not (v_resp->>'ok')::boolean and v_resp->>'erro' like '%motivo é obrigatório%'
  then raise notice 'TESTE A2 (motivo só espaços também rejeitado) aprovado';
  else v_falhas := v_falhas + 1; v_motivos := v_motivos || E'\n- TESTE A2 reprovado: ' || v_resp::text; end if;

  -- TESTE D: bloqueio por venda já lançada no financeiro (roda antes
  -- do sucesso, para não interferir com os lotes já desfeitos depois)
  v_resp := public.rg_desfazer_lote(v_lote_fin, 'teste — não deveria ser permitido');
  select * into v_lote_check from public.rg_vendas_lotes where id = v_lote_fin;
  select * into v_venda_check from public.rg_vendas where id = v_venda_c;
  if not (v_resp->>'ok')::boolean and v_resp->>'erro' like '%já lançada%no financeiro%'
     and v_lote_check.status = 'ativo' and v_venda_check.excluido = false and v_venda_check.fin_lancado = true
  then raise notice 'TESTE D (bloqueio por venda já lançada) aprovado';
  else v_falhas := v_falhas + 1; v_motivos := v_motivos || E'\n- TESTE D reprovado: ' || v_resp::text; end if;

  -- TESTE E: lote de reprocessamento não pode ser desfeito diretamente
  v_resp := public.rg_desfazer_lote(v_lote_reproc, 'teste — não deveria ser permitido');
  select * into v_lote_check from public.rg_vendas_lotes where id = v_lote_reproc;
  if not (v_resp->>'ok')::boolean and v_resp->>'erro' like '%lote de reprocessamento%'
     and v_lote_check.status = 'ativo'
  then raise notice 'TESTE E (lote de reprocessamento rejeitado) aprovado';
  else v_falhas := v_falhas + 1; v_motivos := v_motivos || E'\n- TESTE E reprovado: ' || v_resp::text; end if;

  -- TESTE F: lote com status diferente de 'ativo' é rejeitado
  v_resp := public.rg_desfazer_lote(v_lote_processando, 'teste — não deveria ser permitido');
  select * into v_lote_check from public.rg_vendas_lotes where id = v_lote_processando;
  if not (v_resp->>'ok')::boolean and v_resp->>'erro' like '%não está ativo%'
     and v_lote_check.status = 'processando'
  then raise notice 'TESTE F (status diferente de ativo rejeitado) aprovado';
  else v_falhas := v_falhas + 1; v_motivos := v_motivos || E'\n- TESTE F reprovado: ' || v_resp::text; end if;

  -- TESTE G: lote sem vendas vinculadas é rejeitado
  v_resp := public.rg_desfazer_lote(v_lote_vazio, 'teste — não deveria ser permitido');
  select * into v_lote_check from public.rg_vendas_lotes where id = v_lote_vazio;
  if not (v_resp->>'ok')::boolean and v_resp->>'erro' like '%não possui nenhuma venda vinculada%'
     and v_lote_check.status = 'ativo'
  then raise notice 'TESTE G (lote sem vendas rejeitado) aprovado';
  else v_falhas := v_falhas + 1; v_motivos := v_motivos || E'\n- TESTE G reprovado: ' || v_resp::text; end if;

  -- TESTE B: sucesso — lote_ok é desfeito, as 2 vendas ficam ocultas
  select count(*) into v_hist_antes from public.rg_vendas_alteracoes_historico where venda_id = v_venda_b;
  v_resp := public.rg_desfazer_lote(v_lote_ok, 'importação duplicada por engano — CSV errado');
  select * into v_lote_check from public.rg_vendas_lotes where id = v_lote_ok;
  select * into v_venda_check from public.rg_vendas where id = v_venda_a;
  if (v_resp->>'ok')::boolean and (v_resp->>'vendas_ocultadas')::int = 2
     and v_lote_check.status = 'desfeito'
     and v_lote_check.desfeito_por = v_admin_id and v_lote_check.desfeito_em is not null
     and v_lote_check.desfeito_motivo = 'importação duplicada por engano — CSV errado'
     and v_venda_check.excluido = true and v_venda_check.excluido_por = v_admin_id and v_venda_check.excluido_em is not null
  then raise notice 'TESTE B (desfazimento bem-sucedido, auditoria completa) aprovado';
  else v_falhas := v_falhas + 1; v_motivos := v_motivos || E'\n- TESTE B reprovado: ' || v_resp::text; end if;

  -- TESTE C: venda já reprocessada também é ocultada; o lote de
  -- reprocessamento e o histórico permanecem intocados
  select * into v_venda_check from public.rg_vendas where id = v_venda_b;
  select * into v_lote_check from public.rg_vendas_lotes where id = v_lote_reproc;
  select count(*) into v_hist_depois from public.rg_vendas_alteracoes_historico where venda_id = v_venda_b;
  if v_venda_check.excluido = true and v_venda_check.excluido_por = v_admin_id
     and v_lote_check.status = 'ativo' and v_lote_check.reprocessa_lote_id = v_lote_ok
     and v_hist_antes = 1 and v_hist_depois = 1
  then raise notice 'TESTE C (venda já reprocessada ocultada; lote de reprocessamento e histórico intocados) aprovado';
  else v_falhas := v_falhas + 1; v_motivos := v_motivos || E'\n- TESTE C reprovado: venda.excluido=%, lote_reproc.status=%, hist_antes=%, hist_depois=%',
    v_venda_check.excluido, v_lote_check.status, v_hist_antes, v_hist_depois; end if;

  -- TESTE H: lote já 'desfeito' não pode ser desfeito de novo
  v_resp := public.rg_desfazer_lote(v_lote_ok, 'segunda tentativa — não deveria ser permitido');
  if not (v_resp->>'ok')::boolean and v_resp->>'erro' like '%não está ativo%'
  then raise notice 'TESTE H (lote já desfeito rejeitado) aprovado';
  else v_falhas := v_falhas + 1; v_motivos := v_motivos || E'\n- TESTE H reprovado: ' || v_resp::text; end if;

  -- TESTE I: rg_financeiro nunca foi tocado por nenhuma das chamadas acima
  select md5(coalesce(string_agg(t::text, '|' order by id), '')) into v_financeiro_depois from public.rg_financeiro t;
  if v_financeiro_antes = v_financeiro_depois
  then raise notice 'TESTE I (rg_financeiro intocado durante todos os testes) aprovado';
  else v_falhas := v_falhas + 1; v_motivos := v_motivos || E'\n- TESTE I reprovado: rg_financeiro mudou durante os testes'; end if;

  -- TESTE J: uid autenticado sem perfil correspondente é rejeitado
  -- pela checagem inicial (rg_is_admin() = false), sem tocar em
  -- nenhum lote/venda. NÃO substitui o teste via app.
  v_uid_falso := gen_random_uuid();
  perform set_config('request.jwt.claim.sub', v_uid_falso::text, true);
  perform set_config('request.jwt.claims', jsonb_build_object('sub', v_uid_falso::text, 'role', 'authenticated')::text, true);

  begin
    v_resp := public.rg_desfazer_lote(v_lote_fin, 'teste não-admin');
    v_falhas := v_falhas + 1;
    v_motivos := v_motivos || E'\n- TESTE J reprovado: deveria ter lançado exceção de admin, retornou: ' || coalesce(v_resp::text, 'null');
  exception when others then
    if SQLERRM like '%somente administradores%' then
      raise notice 'TESTE J (não-admin rejeitado pela checagem interna) aprovado';
    else
      v_falhas := v_falhas + 1;
      v_motivos := v_motivos || E'\n- TESTE J reprovado: erro inesperado — SQLSTATE=' || SQLSTATE || ', mensagem=' || SQLERRM;
    end if;
  end;

  perform set_config('request.jwt.claim.sub', v_admin_id::text, true);
  perform set_config('request.jwt.claims', jsonb_build_object('sub', v_admin_id::text, 'role', 'authenticated')::text, true);

  raise notice '=== TESTE K (RLS real, role authenticated não-admin): não testável com segurança pelo SQL Editor, que ignora RLS por rodar com role privilegiada — TESTE J acima cobre só a checagem interna da função. Teste via app continua obrigatório antes de considerar a Etapa 1B.6 encerrada. ===';
  raise notice '=== Atomicidade entre o UPDATE de vendas e o UPDATE do lote: mesma garantia transacional já validada nas migrations 0005/0006 (bloco EXCEPTION único envolvendo ambos) — não há um segundo estado intermediário próprio nesta função para forçar uma falha sintética entre os dois UPDATEs sem enfraquecer o schema; validado por inspeção do código. O TESTE D acima já comprova, na prática, que uma reprovação de validação não deixa nem vendas nem o lote alterados. ===';

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
    raise exception 'MIGRATION 0007: % teste(s) reprovado(s):%', v_falhas, v_motivos;
  end if;

  raise notice 'TODOS OS TESTES DA MIGRATION 0007 FORAM APROVADOS';
END $$;

COMMIT;
-- Só chega aqui se: todos os testes passaram (v_falhas=0) E a limpeza
-- foi confirmada sem resíduo. Qualquer reprovação em qualquer ponto
-- acima já teria abortado a transação inteira antes deste COMMIT —
-- inclusive desfazendo a criação da função e a coluna nova.
