-- ============================================================
-- MIGRATION 0003 — v6: lotes de importacao da Hotmart (Etapa 1B.1)
-- Schema e seguranca apenas — nenhuma alteracao funcional em
-- app.html acompanha esta migration. Prepara a base de dados
-- para as subetapas 1B.2 a 1B.6 (importacao com lote, atualizacao
-- com historico por campo, vinculo com o Financeiro, pendencia
-- financeira e "desfazer importacao").
--
-- Depende de: 0000_baseline.sql (public.profiles, public.rg_is_admin(),
-- public.rg_financeiro), 0002_v5_...sql (public.rg_vendas)
--
-- NAO EXECUTAR sem autorizacao explicita e sem antes validar
-- contra um projeto Supabase de desenvolvimento vazio.
-- Todas as alteracoes sao aditivas: nenhuma coluna existente e
-- removida, renomeada ou tem seu tipo alterado; nenhuma linha
-- existente de rg_vendas ou rg_financeiro e modificada por esta
-- migration.
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
