-- ============================================================
-- MIGRATION 0008 — v12: paginação escalável de Vendas (Etapa 1C —
-- "Filtros, indicadores e funcionamento de Vendas e Alunos", conforme
-- Plano_Revisado_Painel_RG_Gastro.md; é a subetapa seguinte natural
-- depois de 1B.1–1B.6, não uma continuação numerada de 1B).
--
-- Origem: DB.list('rg_vendas') carrega a tabela inteira num único
-- select sem paginação — o PostgREST do Supabase corta a resposta
-- no "Max Rows" do projeto (1000 por padrão). Com 1167+ linhas no
-- DEV, vendas recentes (id mais alto, ex.: lote #78, ids 1193–1198)
-- nunca chegavam ao navegador, em nenhum filtro. Confirmado por
-- consulta direta antes desta migration.
--
-- Terceira RPC de negócio do projeto (rg_vendas_listar), mais duas
-- funções de leitura auxiliares (rg_vendas_kpis, rg_vendas_produtos_
-- distintos). Todas security invoker: são só leitura, e a RLS já
-- existente em rg_vendas/rg_vendas_lotes (admin-only, desde a 0002)
-- já barra qualquer não-admin de ver qualquer linha — diferente de
-- rg_reprocessar_lote/rg_desfazer_lote (que executam ações e por
-- isso têm checagem explícita de rg_is_admin() redundante), aqui a
-- RLS sozinha já é suficiente.
--
-- Regra de visibilidade replicada aqui (idêntica à vendaVisivel() do
-- app.html): excluido=false AND (lote_id IS NULL OR (lote.status=
-- 'ativo' AND importacao_concluida=true)).
--
-- Regra de data nula (decisão de negócio aprovada): "Todo o período"
-- (p_ini e p_fim nulos) inclui venda sem data; um período definido
-- EXCLUI venda sem data — nunca distorce KPI de um período específico.
--
-- p_filtro aceita somente 'Aprovado', 'Pendencia', ou nulo/vazio
-- ("Todas") — qualquer outro valor lança exceção clara, nunca cai
-- silenciosamente em "Todas".
--
-- p_ini/p_fim: ou os dois são nulos (todo o período) ou os dois são
-- preenchidos (período definido) — um só preenchido, ou p_ini
-- posterior a p_fim, lança exceção clara, em rg_vendas_listar e em
-- rg_vendas_kpis.
--
-- rg_vendas_kpis passou a ser plpgsql (não mais sql puro) — a
-- validação acima exige RAISE/IF, que uma função "language sql" não
-- suporta. Além dos 4 KPIs originais (sempre sobre "aprovadas"),
-- retorna agora também total_registros e pendencias_financeiras,
-- ambos sobre as vendas visíveis no período/produto SEM filtro de
-- status — evita o app precisar chamar rg_vendas_listar só para
-- obter "N registros no período" e a contagem da aba Pendências.
--
-- NAO EXECUTAR sem autorizacao explicita. Validar exclusivamente
-- no projeto Supabase DEV antes de qualquer aplicação em produção.
--
-- Depende de: 0002 (public.rg_vendas, RLS admin-only), 0003 (rg_vendas
-- .excluido/pendencia_financeira, rg_vendas_lotes.status).
-- ============================================================

BEGIN;

-- ===== EXTENSÃO PARA BUSCA POR TEXTO ESCALÁVEL =====
create extension if not exists pg_trgm;

-- ===== ÍNDICES =====
-- nome/transacao: ILIKE '%termo%' (wildcard à esquerda) não usa
-- índice btree comum — precisa de índice trigram (GIN) para escalar.
-- transacao já tem UNIQUE (índice btree implícito) desde a 0002, que
-- acelera igualdade exata mas não ILIKE — o índice trigram é
-- adicional, não substitui o unique.
create index if not exists idx_vendas_nome_trgm on public.rg_vendas using gin (nome gin_trgm_ops);
create index if not exists idx_vendas_transacao_trgm on public.rg_vendas using gin (transacao gin_trgm_ops);
create index if not exists idx_vendas_data_id on public.rg_vendas (data desc nulls last, id desc);
create index if not exists idx_vendas_produto on public.rg_vendas (produto);
create index if not exists idx_vendas_status on public.rg_vendas (status);
-- pendencia_financeira já tem índice desde a 0003 (idx_vendas_pendencia_financeira)

-- ===== LISTAGEM PAGINADA, FILTRADA E COM BUSCA =====
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

-- ===== KPIs AGREGADOS =====
-- faturamento_liquido/vendas_aprovadas/alunos_unicos/ticket_medio
-- continuam sempre sobre "aprovadas" (status Aprovado/Completo),
-- igual ao app hoje. total_registros e pendencias_financeiras são
-- calculados sobre as MESMAS vendas visíveis no período/produto,
-- mas SEM esse filtro de status — por isso usam FILTER (WHERE ...)
-- nos agregados que precisam de "aprovadas", em vez de um WHERE
-- geral, que excluiria linhas dos dois campos novos.
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

-- ===== PRODUTOS DISTINTOS (para o filtro de produto na tela) =====
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

COMMIT;
