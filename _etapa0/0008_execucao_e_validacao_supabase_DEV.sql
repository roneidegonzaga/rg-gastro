-- ============================================================
-- SCRIPT DE EXECUÇÃO E VALIDAÇÃO — Migration 0008 (Etapa 1C)
-- Rodar SOMENTE contra o projeto Supabase "rg-gastro-DEV",
-- confirmando visualmente o nome do projeto no painel antes de
-- colar qualquer coisa aqui.
--
-- Estratégia A (única transação): as funções e os índices só
-- permanecem aplicados se TODOS os testes passarem E toda a
-- limpeza das fixtures for confirmada. Qualquer reprovação desfaz
-- tudo, inclusive a extensão pg_trgm, os índices e as 3 funções,
-- via ROLLBACK automático de uma exceção não capturada.
--
-- NÃO é a migration em si — a migration "de verdade" continua
-- sendo _etapa0/migrations/0008_v12_vendas_paginacao_escalavel.sql
-- (o corpo das funções abaixo é uma cópia idêntica).
--
-- PASSO 0 (autenticação de teste) reaproveita a técnica já validada
-- nas migrations 0005–0007: set_config local à transação com um
-- admin real do próprio DEV.
--
-- Este script inclui, além dos testes com fixtures isoladas
-- (prefixo __TESTE1C_), dois testes contra os DADOS REAIS já
-- existentes no DEV (sem inserir nem alterar nada): confirma que o
-- total retornado por rg_vendas_listar bate com uma contagem de
-- referência independente, e que os IDs 1193–1198 (lote #78, o caso
-- real que originou esta migration) aparecem percorrendo as
-- páginas — prova direta de que o corte de 1000 linhas do
-- PostgREST deixou de afetar a listagem.
--
-- NOVO nesta revisão: validação de par de datas (p_ini/p_fim ambos
-- nulos ou ambos preenchidos; p_ini nunca posterior a p_fim) em
-- rg_vendas_listar e rg_vendas_kpis; rg_vendas_kpis passou a
-- retornar também total_registros e pendencias_financeiras
-- (independentes de status), e por isso deixou de ser "language
-- sql" (que não suporta RAISE/IF) e passou a ser "language plpgsql".
-- ============================================================

BEGIN;

-- ===== PARTE 1: EXTENSÃO, ÍNDICES E FUNÇÕES (idênticos à migration) =====

create extension if not exists pg_trgm;

create index if not exists idx_vendas_nome_trgm on public.rg_vendas using gin (nome gin_trgm_ops);
create index if not exists idx_vendas_transacao_trgm on public.rg_vendas using gin (transacao gin_trgm_ops);
create index if not exists idx_vendas_data_id on public.rg_vendas (data desc nulls last, id desc);
create index if not exists idx_vendas_produto on public.rg_vendas (produto);
create index if not exists idx_vendas_status on public.rg_vendas (status);

create or replace function public.rg_vendas_listar(
  p_ini date,
  p_fim date,
  p_produtos text[],
  p_filtro text,
  p_busca text,
  p_pagina int,
  p_por_pagina int
)
returns jsonb
language plpgsql
security invoker
set search_path = ''
stable
as $$
declare
  v_filtro text;
  v_busca text;
  v_por_pagina int;
  v_pagina int;
  v_offset int;
  v_total int;
  v_total_paginas int;
  v_dados jsonb;
begin
  v_filtro := nullif(trim(coalesce(p_filtro, '')), '');
  if v_filtro is not null and v_filtro not in ('Aprovado', 'Pendencia') then
    raise exception 'p_filtro inválido: % — esperado ''Aprovado'', ''Pendencia'' ou nulo/vazio para "Todas"', p_filtro;
  end if;

  if (p_ini is null) <> (p_fim is null) then
    raise exception 'p_ini e p_fim devem ser ambos nulos (todo o período) ou ambos preenchidos (período definido)';
  end if;
  if p_ini is not null and p_fim is not null and p_ini > p_fim then
    raise exception 'p_ini (%) não pode ser posterior a p_fim (%)', p_ini, p_fim;
  end if;

  v_busca := nullif(trim(coalesce(p_busca, '')), '');
  v_por_pagina := greatest(1, least(coalesce(p_por_pagina, 50), 100));
  v_pagina := greatest(1, coalesce(p_pagina, 1));
  v_offset := (v_pagina - 1) * v_por_pagina;

  select count(*) into v_total
  from public.rg_vendas v
  left join public.rg_vendas_lotes l on l.id = v.lote_id
  where v.excluido = false
    and (v.lote_id is null or (l.status = 'ativo' and v.importacao_concluida = true))
    and (v_filtro is distinct from 'Aprovado' or v.status in ('Aprovado','Completo'))
    and (v_filtro is distinct from 'Pendencia' or v.pendencia_financeira = true)
    and (p_produtos is null or v.produto = any(p_produtos))
    and ((p_ini is null and p_fim is null) or (v.data is not null and v.data >= p_ini and v.data <= p_fim))
    and (v_busca is null or v.nome ilike '%' || v_busca || '%' or v.transacao ilike '%' || v_busca || '%');

  select coalesce(jsonb_agg(t order by t.data desc nulls last, t.id desc), '[]'::jsonb)
  into v_dados
  from (
    select v.*
    from public.rg_vendas v
    left join public.rg_vendas_lotes l on l.id = v.lote_id
    where v.excluido = false
      and (v.lote_id is null or (l.status = 'ativo' and v.importacao_concluida = true))
      and (v_filtro is distinct from 'Aprovado' or v.status in ('Aprovado','Completo'))
      and (v_filtro is distinct from 'Pendencia' or v.pendencia_financeira = true)
      and (p_produtos is null or v.produto = any(p_produtos))
      and ((p_ini is null and p_fim is null) or (v.data is not null and v.data >= p_ini and v.data <= p_fim))
      and (v_busca is null or v.nome ilike '%' || v_busca || '%' or v.transacao ilike '%' || v_busca || '%')
    order by v.data desc nulls last, v.id desc
    limit v_por_pagina offset v_offset
  ) t;

  v_total_paginas := greatest(1, ceil(v_total::numeric / v_por_pagina)::int);

  return jsonb_build_object(
    'dados', v_dados,
    'total', v_total,
    'pagina', v_pagina,
    'total_paginas', v_total_paginas,
    'por_pagina', v_por_pagina
  );
end;
$$;

revoke execute on function public.rg_vendas_listar(
  date, date, text[], text, text, int, int
) from public, anon, service_role;

grant execute on function public.rg_vendas_listar(
  date, date, text[], text, text, int, int
) to authenticated;

create or replace function public.rg_vendas_kpis(
  p_ini date,
  p_fim date,
  p_produtos text[]
)
returns jsonb
language plpgsql
security invoker
set search_path = ''
stable
as $$
declare
  v_resultado jsonb;
begin
  if (p_ini is null) <> (p_fim is null) then
    raise exception 'p_ini e p_fim devem ser ambos nulos (todo o período) ou ambos preenchidos (período definido)';
  end if;
  if p_ini is not null and p_fim is not null and p_ini > p_fim then
    raise exception 'p_ini (%) não pode ser posterior a p_fim (%)', p_ini, p_fim;
  end if;

  select jsonb_build_object(
    'faturamento_liquido', coalesce(sum(v.liquido) filter (where v.status in ('Aprovado','Completo')), 0),
    'vendas_aprovadas', count(*) filter (where v.status in ('Aprovado','Completo')),
    'alunos_unicos', count(distinct lower(v.email)) filter (where v.status in ('Aprovado','Completo') and v.email is not null),
    'ticket_medio', case when count(distinct lower(v.email)) filter (where v.status in ('Aprovado','Completo') and v.email is not null) > 0
      then coalesce(sum(v.liquido) filter (where v.status in ('Aprovado','Completo')), 0)
           / count(distinct lower(v.email)) filter (where v.status in ('Aprovado','Completo') and v.email is not null)
      else 0 end,
    'total_registros', count(*),
    'pendencias_financeiras', count(*) filter (where v.pendencia_financeira = true)
  )
  into v_resultado
  from public.rg_vendas v
  left join public.rg_vendas_lotes l on l.id = v.lote_id
  where v.excluido = false
    and (v.lote_id is null or (l.status = 'ativo' and v.importacao_concluida = true))
    and ((p_ini is null and p_fim is null) or (v.data is not null and v.data >= p_ini and v.data <= p_fim))
    and (p_produtos is null or v.produto = any(p_produtos));

  return v_resultado;
end;
$$;

revoke execute on function public.rg_vendas_kpis(
  date, date, text[]
) from public, anon, service_role;

grant execute on function public.rg_vendas_kpis(
  date, date, text[]
) to authenticated;

create or replace function public.rg_vendas_produtos_distintos()
returns text[]
language sql
security invoker
set search_path = ''
stable
as $$
  select coalesce(array_agg(distinct v.produto order by v.produto), '{}')
  from public.rg_vendas v
  left join public.rg_vendas_lotes l on l.id = v.lote_id
  where v.produto is not null and v.excluido = false
    and (v.lote_id is null or (l.status = 'ativo' and v.importacao_concluida = true))
$$;

revoke execute on function public.rg_vendas_produtos_distintos(
) from public, anon, service_role;

grant execute on function public.rg_vendas_produtos_distintos(
) to authenticated;

-- ===== PARTE 2: FIXTURES, TESTES E LIMPEZA =====

DO $$
DECLARE
  v_admin_id uuid;
  v_proacl aclitem[];
  v_execute_public boolean;
  v_execute_anon boolean;
  v_execute_service boolean;
  v_execute_authenticated boolean;
  v_falhas int := 0;
  v_motivos text := '';
  v_vendas_teste bigint[] := '{}';
  v_lotes_teste bigint[] := '{}';
  v_resp jsonb;
  v_produtos text[];

  v_lote_ok bigint;
  v_lote_erro bigint;
  v_lote_processando bigint;
  v_data_fixa date := '2026-01-10';

  v1 bigint; v2 bigint; v3 bigint; v7 bigint; v8 bigint;
  v4 bigint; v5 bigint; v6 bigint;

  v_ref_total int;
  v_ids_coletados bigint[] := '{}';
  v_pagina_atual int;
  v_total_paginas_reais int;
  v_pagina_resp jsonb;
  v_item jsonb;
BEGIN
  -- PASSO 0: localizar um admin real aprovado no próprio DEV.
  select user_id into v_admin_id
  from public.profiles
  where role = 'admin' and aprovado = true
  order by criado_em asc
  limit 1;

  if v_admin_id is null then
    raise exception 'MIGRATION 0008: nenhum perfil admin aprovado encontrado em public.profiles neste ambiente — impossível testar com segurança. Nenhuma fixture foi criada.';
  end if;

  perform set_config('request.jwt.claim.sub', v_admin_id::text, true);
  perform set_config('request.jwt.claims', jsonb_build_object('sub', v_admin_id::text, 'role', 'authenticated')::text, true);

  raise notice '=== contexto de teste: autenticado como admin real user_id=% (válido só nesta transação) ===', v_admin_id;

  -- TESTE PERM: permissões das 3 funções novas, por catálogo.
  select proacl into v_proacl from pg_proc where pronamespace = 'public'::regnamespace and proname = 'rg_vendas_listar';
  select coalesce(bool_or(a.privilege_type = 'EXECUTE'), false) into v_execute_public from aclexplode(v_proacl) a where a.grantee = 0;
  v_execute_anon := has_function_privilege('anon', 'public.rg_vendas_listar(date,date,text[],text,text,int,int)', 'EXECUTE');
  v_execute_service := has_function_privilege('service_role', 'public.rg_vendas_listar(date,date,text[],text,text,int,int)', 'EXECUTE');
  v_execute_authenticated := has_function_privilege('authenticated', 'public.rg_vendas_listar(date,date,text[],text,text,int,int)', 'EXECUTE');
  if v_execute_public or v_execute_anon or v_execute_service or not v_execute_authenticated then
    v_falhas := v_falhas + 1; v_motivos := v_motivos || E'\n- TESTE PERM (rg_vendas_listar) reprovado: public=' || v_execute_public || ' anon=' || v_execute_anon || ' service=' || v_execute_service || ' authenticated=' || v_execute_authenticated;
  else
    raise notice 'TESTE PERM (rg_vendas_listar: só authenticated com EXECUTE) aprovado';
  end if;

  select proacl into v_proacl from pg_proc where pronamespace = 'public'::regnamespace and proname = 'rg_vendas_kpis';
  select coalesce(bool_or(a.privilege_type = 'EXECUTE'), false) into v_execute_public from aclexplode(v_proacl) a where a.grantee = 0;
  v_execute_anon := has_function_privilege('anon', 'public.rg_vendas_kpis(date,date,text[])', 'EXECUTE');
  v_execute_service := has_function_privilege('service_role', 'public.rg_vendas_kpis(date,date,text[])', 'EXECUTE');
  v_execute_authenticated := has_function_privilege('authenticated', 'public.rg_vendas_kpis(date,date,text[])', 'EXECUTE');
  if v_execute_public or v_execute_anon or v_execute_service or not v_execute_authenticated then
    v_falhas := v_falhas + 1; v_motivos := v_motivos || E'\n- TESTE PERM (rg_vendas_kpis) reprovado: public=' || v_execute_public || ' anon=' || v_execute_anon || ' service=' || v_execute_service || ' authenticated=' || v_execute_authenticated;
  else
    raise notice 'TESTE PERM (rg_vendas_kpis: só authenticated com EXECUTE) aprovado';
  end if;

  select proacl into v_proacl from pg_proc where pronamespace = 'public'::regnamespace and proname = 'rg_vendas_produtos_distintos';
  select coalesce(bool_or(a.privilege_type = 'EXECUTE'), false) into v_execute_public from aclexplode(v_proacl) a where a.grantee = 0;
  v_execute_anon := has_function_privilege('anon', 'public.rg_vendas_produtos_distintos()', 'EXECUTE');
  v_execute_service := has_function_privilege('service_role', 'public.rg_vendas_produtos_distintos()', 'EXECUTE');
  v_execute_authenticated := has_function_privilege('authenticated', 'public.rg_vendas_produtos_distintos()', 'EXECUTE');
  if v_execute_public or v_execute_anon or v_execute_service or not v_execute_authenticated then
    v_falhas := v_falhas + 1; v_motivos := v_motivos || E'\n- TESTE PERM (rg_vendas_produtos_distintos) reprovado: public=' || v_execute_public || ' anon=' || v_execute_anon || ' service=' || v_execute_service || ' authenticated=' || v_execute_authenticated;
  else
    raise notice 'TESTE PERM (rg_vendas_produtos_distintos: só authenticated com EXECUTE) aprovado';
  end if;

  -- ===== FIXTURES =====
  -- Visíveis: v1, v2, v3, v7, v8 (5 vendas). Escondidas: v4 (lote
  -- 'erro'), v5 (importacao_concluida=false), v6 (excluido=true) —
  -- nunca devem aparecer em nenhum teste abaixo, mesmo quando
  -- filtradas explicitamente pelo seu próprio produto.
  insert into public.rg_vendas_lotes (arquivo_nome, status) values ('__teste_1C_lote_ok__.csv', 'ativo') returning id into v_lote_ok;
  insert into public.rg_vendas_lotes (arquivo_nome, status) values ('__teste_1C_lote_erro__.csv', 'erro') returning id into v_lote_erro;
  insert into public.rg_vendas_lotes (arquivo_nome, status) values ('__teste_1C_lote_processando__.csv', 'processando') returning id into v_lote_processando;
  v_lotes_teste := array[v_lote_ok, v_lote_erro, v_lote_processando];

  insert into public.rg_vendas (transacao, produto, nome, email, status, valor, liquido, data, fin_lancado, pendencia_financeira, lote_id, importacao_concluida)
    values ('__TESTE1C_TX1__','__PRODUTO_TESTE_1C_VISIVEL__','Zeta Ultima','zeta1c@teste.com','Completo',100,90,v_data_fixa,false,false,v_lote_ok,true) returning id into v1;
  insert into public.rg_vendas (transacao, produto, nome, email, status, valor, liquido, data, fin_lancado, pendencia_financeira, lote_id, importacao_concluida)
    values ('__TESTE1C_TX2__','__PRODUTO_TESTE_1C_VISIVEL__','Ana Pendente','ana1c@teste.com','Aprovado',200,180,v_data_fixa,true,true,v_lote_ok,true) returning id into v2;
  insert into public.rg_vendas (transacao, produto, nome, email, status, valor, liquido, data, fin_lancado, pendencia_financeira, lote_id, importacao_concluida)
    values ('__TESTE1C_TX3__','__PRODUTO_TESTE_1C_VISIVEL__','Bruno SemData, (Especial)','bruno1c@teste.com','Cancelado',50,45,null,false,false,v_lote_ok,true) returning id into v3;
  insert into public.rg_vendas (transacao, produto, nome, email, status, valor, liquido, data, fin_lancado, pendencia_financeira, lote_id, importacao_concluida)
    values ('__TESTE1C_TX7__','__PRODUTO_TESTE_1C_OUTRO__','Fabio OutroProduto','fabio1c@teste.com','Completo',300,270,v_data_fixa,false,false,v_lote_ok,true) returning id into v7;
  insert into public.rg_vendas (transacao, produto, nome, email, status, valor, liquido, data, fin_lancado, pendencia_financeira, lote_id, importacao_concluida)
    values ('__TESTE1C_TX8__','__PRODUTO_TESTE_1C_VISIVEL__','Gabi ApteroSemData','gabi1c@teste.com','Completo',400,360,null,false,false,v_lote_ok,true) returning id into v8;

  insert into public.rg_vendas (transacao, produto, nome, email, status, valor, liquido, data, lote_id, importacao_concluida)
    values ('__TESTE1C_TX4__','__PRODUTO_TESTE_1C_ESCONDIDO__','Carla Escondida','carla1c@teste.com','Completo',10,9,v_data_fixa,v_lote_erro,true) returning id into v4;
  insert into public.rg_vendas (transacao, produto, nome, email, status, valor, liquido, data, lote_id, importacao_concluida)
    values ('__TESTE1C_TX5__','__PRODUTO_TESTE_1C_ESCONDIDO__','Davi Processando','davi1c@teste.com','Completo',10,9,v_data_fixa,v_lote_processando,false) returning id into v5;
  insert into public.rg_vendas (transacao, produto, nome, email, status, valor, liquido, data, lote_id, importacao_concluida, excluido)
    values ('__TESTE1C_TX6__','__PRODUTO_TESTE_1C_ESCONDIDO__','Elis Excluida','elis1c@teste.com','Completo',10,9,v_data_fixa,v_lote_ok,true,true) returning id into v6;

  v_vendas_teste := array[v1,v2,v3,v7,v8,v4,v5,v6];

  raise notice '=== fixtures: lote_ok=%, lote_erro=%, lote_processando=%, visiveis(v1,v2,v3,v7,v8)=%,%,%,%,%, escondidas(v4,v5,v6)=%,%,% ===',
    v_lote_ok, v_lote_erro, v_lote_processando, v1,v2,v3,v7,v8, v4,v5,v6;

  -- TESTE 1: Todas, busca=TX -> os 5 visíveis, nenhuma escondida
  v_resp := public.rg_vendas_listar(null, null, null, null, '__TESTE1C_TX', 1, 50);
  if (v_resp->>'total')::int = 5 then raise notice 'TESTE 1 (Todas, 5 visíveis) aprovado';
  else v_falhas := v_falhas + 1; v_motivos := v_motivos || E'\n- TESTE 1 reprovado: total=' || (v_resp->>'total'); end if;

  -- TESTE 2: Aprovadas -> v1,v2,v7,v8 (Cancelado de v3 fica de fora)
  v_resp := public.rg_vendas_listar(null, null, null, 'Aprovado', '__TESTE1C_TX', 1, 50);
  if (v_resp->>'total')::int = 4 then raise notice 'TESTE 2 (Aprovadas) aprovado';
  else v_falhas := v_falhas + 1; v_motivos := v_motivos || E'\n- TESTE 2 reprovado: total=' || (v_resp->>'total'); end if;

  -- TESTE 3: Pendencia -> só v2
  v_resp := public.rg_vendas_listar(null, null, null, 'Pendencia', '__TESTE1C_TX', 1, 50);
  if (v_resp->>'total')::int = 1 and (v_resp->'dados'->0->>'id')::bigint = v2
  then raise notice 'TESTE 3 (Pendencia) aprovado';
  else v_falhas := v_falhas + 1; v_motivos := v_motivos || E'\n- TESTE 3 reprovado: ' || v_resp::text; end if;

  -- TESTE 4: produto=[VISIVEL] -> v1,v2,v3,v8 (v7 é OUTRO, fica de fora)
  v_resp := public.rg_vendas_listar(null, null, array['__PRODUTO_TESTE_1C_VISIVEL__'], null, '__TESTE1C_TX', 1, 50);
  if (v_resp->>'total')::int = 4 then raise notice 'TESTE 4 (produto único) aprovado';
  else v_falhas := v_falhas + 1; v_motivos := v_motivos || E'\n- TESTE 4 reprovado: total=' || (v_resp->>'total'); end if;

  -- TESTE 5: produto=[VISIVEL,OUTRO] -> todos os 5
  v_resp := public.rg_vendas_listar(null, null, array['__PRODUTO_TESTE_1C_VISIVEL__','__PRODUTO_TESTE_1C_OUTRO__'], null, '__TESTE1C_TX', 1, 50);
  if (v_resp->>'total')::int = 5 then raise notice 'TESTE 5 (produto múltiplo) aprovado';
  else v_falhas := v_falhas + 1; v_motivos := v_motivos || E'\n- TESTE 5 reprovado: total=' || (v_resp->>'total'); end if;

  -- TESTE 6: produto=[ESCONDIDO] -> 0 (visibilidade tem precedência sobre produto)
  v_resp := public.rg_vendas_listar(null, null, array['__PRODUTO_TESTE_1C_ESCONDIDO__'], null, '__TESTE1C_TX', 1, 50);
  if (v_resp->>'total')::int = 0 then raise notice 'TESTE 6 (produto de vendas escondidas nunca vaza) aprovado';
  else v_falhas := v_falhas + 1; v_motivos := v_motivos || E'\n- TESTE 6 reprovado: total=' || (v_resp->>'total'); end if;

  -- TESTE 7: busca por nome, sem tocar em transação
  v_resp := public.rg_vendas_listar(null, null, null, null, 'Zeta Ultima', 1, 50);
  if (v_resp->>'total')::int = 1 and (v_resp->'dados'->0->>'id')::bigint = v1
  then raise notice 'TESTE 7 (busca por nome) aprovado';
  else v_falhas := v_falhas + 1; v_motivos := v_motivos || E'\n- TESTE 7 reprovado: ' || v_resp::text; end if;

  -- TESTE 8: busca com vírgula e parênteses não quebra a consulta
  v_resp := public.rg_vendas_listar(null, null, null, null, 'SemData, (Especial', 1, 50);
  if (v_resp->>'total')::int = 1 and (v_resp->'dados'->0->>'id')::bigint = v3
  then raise notice 'TESTE 8 (busca com caracteres especiais) aprovado';
  else v_falhas := v_falhas + 1; v_motivos := v_motivos || E'\n- TESTE 8 reprovado: ' || v_resp::text; end if;

  -- TESTE 9: todo período (p_ini/p_fim nulos) inclui data nula
  v_resp := public.rg_vendas_listar(null, null, null, null, '__TESTE1C_TX', 1, 50);
  if (v_resp->>'total')::int = 5 then raise notice 'TESTE 9 (todo período inclui data nula) aprovado';
  else v_falhas := v_falhas + 1; v_motivos := v_motivos || E'\n- TESTE 9 reprovado: total=' || (v_resp->>'total'); end if;

  -- TESTE 10: período definido EXCLUI data nula -> v3 e v8 somem, sobram v1,v2,v7
  v_resp := public.rg_vendas_listar(v_data_fixa, v_data_fixa, null, null, '__TESTE1C_TX', 1, 50);
  if (v_resp->>'total')::int = 3 then raise notice 'TESTE 10 (período definido exclui data nula) aprovado';
  else v_falhas := v_falhas + 1; v_motivos := v_motivos || E'\n- TESTE 10 reprovado: total=' || (v_resp->>'total'); end if;

  -- TESTE 11a: KPIs em período definido não somam venda com data nula (v8).
  -- total_registros/pendencias_financeiras aqui: v1,v2,v7 têm data=D
  -- (v3,v8 ficam de fora pela mesma regra de data nula); dos três,
  -- só v2 tem pendencia_financeira=true.
  v_produtos := array['__PRODUTO_TESTE_1C_VISIVEL__','__PRODUTO_TESTE_1C_OUTRO__'];
  v_resp := public.rg_vendas_kpis(v_data_fixa, v_data_fixa, v_produtos);
  if (v_resp->>'faturamento_liquido')::numeric = 540 and (v_resp->>'vendas_aprovadas')::int = 3
     and (v_resp->>'alunos_unicos')::int = 3 and (v_resp->>'ticket_medio')::numeric = 180
     and (v_resp->>'total_registros')::int = 3 and (v_resp->>'pendencias_financeiras')::int = 1
  then raise notice 'TESTE 11a (KPIs período definido, sem v8/v3; total_registros e pendencias_financeiras corretos) aprovado';
  else v_falhas := v_falhas + 1; v_motivos := v_motivos || E'\n- TESTE 11a reprovado: ' || v_resp::text; end if;

  -- TESTE 11b: KPIs em todo período incluem v8 (data nula) nos 4 KPIs
  -- originais (v3 continua fora deles por status='Cancelado', não por
  -- data). total_registros aqui PRECISA ser maior que vendas_aprovadas
  -- (5 contra 4) — é a prova de que total_registros independe do
  -- status: inclui v3 (Cancelado), que os 4 KPIs originais não contam.
  v_resp := public.rg_vendas_kpis(null, null, v_produtos);
  if (v_resp->>'faturamento_liquido')::numeric = 900 and (v_resp->>'vendas_aprovadas')::int = 4
     and (v_resp->>'alunos_unicos')::int = 4 and (v_resp->>'ticket_medio')::numeric = 225
     and (v_resp->>'total_registros')::int = 5 and (v_resp->>'pendencias_financeiras')::int = 1
  then raise notice 'TESTE 11b (KPIs todo período; total_registros=5 > vendas_aprovadas=4, prova independência de status) aprovado';
  else v_falhas := v_falhas + 1; v_motivos := v_motivos || E'\n- TESTE 11b reprovado: ' || v_resp::text; end if;

  -- TESTE 12: por_pagina acima de 100 é limitado a 100
  v_resp := public.rg_vendas_listar(null, null, null, null, '__TESTE1C_TX', 1, 500);
  if (v_resp->>'por_pagina')::int = 100 then raise notice 'TESTE 12 (por_pagina limitado a 100) aprovado';
  else v_falhas := v_falhas + 1; v_motivos := v_motivos || E'\n- TESTE 12 reprovado: por_pagina=' || (v_resp->>'por_pagina'); end if;

  -- TESTE 13: página muito além do total não gera erro, retorna vazio
  v_resp := public.rg_vendas_listar(null, null, null, null, '__TESTE1C_TX', 99, 50);
  if (v_resp->>'total')::int = 5 and (v_resp->>'total_paginas')::int = 1 and jsonb_array_length(v_resp->'dados') = 0
  then raise notice 'TESTE 13 (página além do total, vazio sem erro) aprovado';
  else v_falhas := v_falhas + 1; v_motivos := v_motivos || E'\n- TESTE 13 reprovado: ' || v_resp::text; end if;

  -- TESTE 14: total_paginas correto com por_pagina pequeno (5 itens, 2 por página = 3 páginas)
  v_resp := public.rg_vendas_listar(null, null, null, null, '__TESTE1C_TX', 1, 2);
  if (v_resp->>'total')::int = 5 and (v_resp->>'total_paginas')::int = 3 and jsonb_array_length(v_resp->'dados') = 2
  then raise notice 'TESTE 14a (página 1 de 3, 2 itens) aprovado';
  else v_falhas := v_falhas + 1; v_motivos := v_motivos || E'\n- TESTE 14a reprovado: ' || v_resp::text; end if;

  v_resp := public.rg_vendas_listar(null, null, null, null, '__TESTE1C_TX', 3, 2);
  if jsonb_array_length(v_resp->'dados') = 1
  then raise notice 'TESTE 14b (última página com o resto, 1 item) aprovado';
  else v_falhas := v_falhas + 1; v_motivos := v_motivos || E'\n- TESTE 14b reprovado: ' || v_resp::text; end if;

  -- TESTE 15: ordenação determinística — data desc nulls last, id desc.
  -- Ordem esperada entre os 5 visíveis: v7,v2,v1 (mesma data, id desc),
  -- depois v8,v3 (data nula, id desc).
  v_resp := public.rg_vendas_listar(null, null, null, null, '__TESTE1C_TX', 1, 50);
  if (v_resp->'dados'->0->>'id')::bigint = v7 and (v_resp->'dados'->1->>'id')::bigint = v2
     and (v_resp->'dados'->2->>'id')::bigint = v1 and (v_resp->'dados'->3->>'id')::bigint = v8
     and (v_resp->'dados'->4->>'id')::bigint = v3
  then raise notice 'TESTE 15 (ordenação data desc nulls last, id desc) aprovado';
  else v_falhas := v_falhas + 1; v_motivos := v_motivos || E'\n- TESTE 15 reprovado: ' || v_resp::text; end if;

  -- TESTE 16: vendas escondidas nunca aparecem, nem buscando por elas diretamente
  v_resp := public.rg_vendas_listar(null, null, null, null, '__TESTE1C_TX4__', 1, 50);
  if (v_resp->>'total')::int = 0 then raise notice 'TESTE 16 (venda de lote erro nunca aparece) aprovado';
  else v_falhas := v_falhas + 1; v_motivos := v_motivos || E'\n- TESTE 16 reprovado: total=' || (v_resp->>'total'); end if;

  -- TESTE 17: p_filtro inválido lança erro claro, não vira "Todas" silenciosamente
  begin
    v_resp := public.rg_vendas_listar(null, null, null, 'StatusQualquer', null, 1, 50);
    v_falhas := v_falhas + 1;
    v_motivos := v_motivos || E'\n- TESTE 17 reprovado: deveria ter lançado exceção, retornou: ' || coalesce(v_resp::text, 'null');
  exception when others then
    if SQLERRM like '%p_filtro inválido%' then
      raise notice 'TESTE 17 (p_filtro inválido rejeitado) aprovado';
    else
      v_falhas := v_falhas + 1;
      v_motivos := v_motivos || E'\n- TESTE 17 reprovado: erro inesperado — ' || SQLERRM;
    end if;
  end;

  -- TESTE 21: rg_vendas_listar rejeita p_ini preenchido sem p_fim
  begin
    v_resp := public.rg_vendas_listar(v_data_fixa, null, null, null, null, 1, 50);
    v_falhas := v_falhas + 1;
    v_motivos := v_motivos || E'\n- TESTE 21 reprovado: deveria ter lançado exceção, retornou: ' || coalesce(v_resp::text, 'null');
  exception when others then
    if SQLERRM like '%ambos nulos%' then
      raise notice 'TESTE 21 (rg_vendas_listar rejeita p_ini sem p_fim) aprovado';
    else
      v_falhas := v_falhas + 1;
      v_motivos := v_motivos || E'\n- TESTE 21 reprovado: erro inesperado — ' || SQLERRM;
    end if;
  end;

  -- TESTE 22: rg_vendas_listar rejeita p_ini > p_fim
  begin
    v_resp := public.rg_vendas_listar(v_data_fixa, v_data_fixa - 1, null, null, null, 1, 50);
    v_falhas := v_falhas + 1;
    v_motivos := v_motivos || E'\n- TESTE 22 reprovado: deveria ter lançado exceção, retornou: ' || coalesce(v_resp::text, 'null');
  exception when others then
    if SQLERRM like '%não pode ser posterior%' then
      raise notice 'TESTE 22 (rg_vendas_listar rejeita p_ini > p_fim) aprovado';
    else
      v_falhas := v_falhas + 1;
      v_motivos := v_motivos || E'\n- TESTE 22 reprovado: erro inesperado — ' || SQLERRM;
    end if;
  end;

  -- TESTE 23: rg_vendas_kpis rejeita p_fim preenchido sem p_ini
  begin
    v_resp := public.rg_vendas_kpis(null, v_data_fixa, null);
    v_falhas := v_falhas + 1;
    v_motivos := v_motivos || E'\n- TESTE 23 reprovado: deveria ter lançado exceção, retornou: ' || coalesce(v_resp::text, 'null');
  exception when others then
    if SQLERRM like '%ambos nulos%' then
      raise notice 'TESTE 23 (rg_vendas_kpis rejeita p_fim sem p_ini) aprovado';
    else
      v_falhas := v_falhas + 1;
      v_motivos := v_motivos || E'\n- TESTE 23 reprovado: erro inesperado — ' || SQLERRM;
    end if;
  end;

  -- TESTE 24: rg_vendas_kpis rejeita p_ini > p_fim
  begin
    v_resp := public.rg_vendas_kpis(v_data_fixa, v_data_fixa - 1, null);
    v_falhas := v_falhas + 1;
    v_motivos := v_motivos || E'\n- TESTE 24 reprovado: deveria ter lançado exceção, retornou: ' || coalesce(v_resp::text, 'null');
  exception when others then
    if SQLERRM like '%não pode ser posterior%' then
      raise notice 'TESTE 24 (rg_vendas_kpis rejeita p_ini > p_fim) aprovado';
    else
      v_falhas := v_falhas + 1;
      v_motivos := v_motivos || E'\n- TESTE 24 reprovado: erro inesperado — ' || SQLERRM;
    end if;
  end;

  -- TESTE 18: produtos distintos contêm os visíveis, não contêm o escondido
  v_produtos := public.rg_vendas_produtos_distintos();
  if '__PRODUTO_TESTE_1C_VISIVEL__' = any(v_produtos) and '__PRODUTO_TESTE_1C_OUTRO__' = any(v_produtos)
     and not ('__PRODUTO_TESTE_1C_ESCONDIDO__' = any(v_produtos))
  then raise notice 'TESTE 18 (produtos distintos: visíveis presentes, escondido ausente) aprovado';
  else v_falhas := v_falhas + 1; v_motivos := v_motivos || E'\n- TESTE 18 reprovado: ' || array_to_string(v_produtos, ','); end if;

  -- TESTE 19: dados reais — total do RPC bate com contagem de referência
  -- independente (inclui as fixtures acima, que ainda não foram limpas)
  select count(*) into v_ref_total
  from public.rg_vendas v
  left join public.rg_vendas_lotes l on l.id = v.lote_id
  where v.excluido = false
    and (v.lote_id is null or (l.status = 'ativo' and v.importacao_concluida = true));
  v_resp := public.rg_vendas_listar(null, null, null, null, null, 1, 1);
  if (v_resp->>'total')::int = v_ref_total
  then raise notice 'TESTE 19 (contagem total bate com referência independente: %) aprovado', v_ref_total;
  else v_falhas := v_falhas + 1; v_motivos := v_motivos || E'\n- TESTE 19 reprovado: rpc=' || (v_resp->>'total') || ', referência=' || v_ref_total; end if;

  -- TESTE 20: dados reais — os IDs 1193 a 1198 (lote #78) aparecem
  -- percorrendo as páginas de rg_vendas_listar (o caso real que
  -- originou esta migration — sem paginação, ficavam além do corte
  -- de 1000 linhas do PostgREST e nunca chegavam ao navegador).
  v_pagina_atual := 1;
  loop
    v_pagina_resp := public.rg_vendas_listar(null, null, null, null, null, v_pagina_atual, 100);
    v_total_paginas_reais := (v_pagina_resp->>'total_paginas')::int;
    for v_item in select * from jsonb_array_elements(v_pagina_resp->'dados')
    loop
      v_ids_coletados := v_ids_coletados || (v_item->>'id')::bigint;
    end loop;
    exit when v_pagina_atual >= v_total_paginas_reais;
    v_pagina_atual := v_pagina_atual + 1;
  end loop;

  if v_ids_coletados @> array[1193,1194,1195,1196,1197,1198]::bigint[]
  then raise notice 'TESTE 20 (IDs 1193-1198 do lote #78 aparecem percorrendo as páginas) aprovado';
  else
    v_falhas := v_falhas + 1;
    v_motivos := v_motivos || E'\n- TESTE 20 reprovado: nem todos os IDs 1193-1198 apareceram nas ' || v_total_paginas_reais || ' páginas percorridas';
  end if;

  -- ===== LIMPEZA EXPLÍCITA DAS FIXTURES (não toca nos dados reais) =====
  delete from public.rg_vendas_alteracoes_historico where venda_id = any(v_vendas_teste);
  delete from public.rg_vendas where id = any(v_vendas_teste);
  delete from public.rg_vendas_lotes where id = any(v_lotes_teste);

  perform 1 from public.rg_vendas where id = any(v_vendas_teste);
  if found then raise exception 'LIMPEZA INCOMPLETA: ainda existem vendas de teste'; end if;
  perform 1 from public.rg_vendas_lotes where id = any(v_lotes_teste);
  if found then raise exception 'LIMPEZA INCOMPLETA: ainda existem lotes de teste'; end if;
  perform 1 from public.rg_vendas_alteracoes_historico where venda_id = any(v_vendas_teste);
  if found then raise exception 'LIMPEZA INCOMPLETA: ainda existe histórico de teste'; end if;

  raise notice '=== RLS (única barreira de acesso das 3 funções novas — elas não têm checagem interna de rg_is_admin() própria, por decisão de design registrada na migration): não testável com segurança pelo SQL Editor, que roda como role privilegiada e ignora RLS. Teste via app com um usuário authenticated não-admin continua obrigatório antes de considerar esta migration encerrada. ===';

  raise notice '=== limpeza confirmada: nenhuma fixture residual ===';

  -- ===== VEREDITO FINAL =====
  if v_falhas > 0 then
    raise exception 'MIGRATION 0008: % teste(s) reprovado(s):%', v_falhas, v_motivos;
  end if;

  raise notice 'TODOS OS TESTES DA MIGRATION 0008 FORAM APROVADOS';
END $$;

COMMIT;
-- Só chega aqui se: todos os testes passaram (v_falhas=0) E a limpeza
-- foi confirmada sem resíduo. Qualquer reprovação em qualquer ponto
-- acima já teria abortado a transação inteira antes deste COMMIT —
-- inclusive desfazendo a extensão pg_trgm, os índices e as 3 funções.
-- Os dados reais (fora do prefixo __TESTE1C_) usados nos TESTES 19/20
-- nunca são alterados — só lidos.
