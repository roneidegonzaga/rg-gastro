-- ============================================================
-- MIGRATION 0002 — v5: categorias, vendas, equipe, visitas,
-- links, cursos e colunas extras
-- Extraida verbatim de setup-supabase.sql (bloco "NOVOS MODULOS v5")
-- Depende de: 0000_baseline.sql e 0001_v4_*.sql (usa
-- public.rg_clientes, public.rg_mentorados, public.rg_tarefas,
-- public.rg_documentos, public.rg_etapas, public.rg_processos,
-- public.rg_contas, public.rg_projetos, public.rg_is_member(),
-- public.rg_is_admin())
--
-- NAO EXECUTAR sem autorizacao explicita e sem antes validar
-- contra um projeto Supabase de desenvolvimento vazio.
-- ============================================================

BEGIN;

alter table public.rg_clientes add column if not exists nascimento date;
alter table public.rg_clientes add column if not exists aniversario_restaurante date;
alter table public.rg_clientes add column if not exists drive_url text;
alter table public.rg_clientes add column if not exists duracao_meses int;
alter table public.rg_mentorados add column if not exists encontros_total int;
alter table public.rg_tarefas add column if not exists curso_id bigint;
alter table public.rg_documentos add column if not exists projeto_id bigint;
alter table public.rg_documentos add column if not exists curso_id bigint;
alter table public.rg_etapas add column if not exists descricao text;
alter table public.rg_etapas add column if not exists atividades text;
alter table public.rg_processos add column if not exists acesso text default 'todos';
alter table public.rg_processos add column if not exists emails text;
alter table public.rg_contas add column if not exists recorrente_dias int;
alter table public.rg_projetos add column if not exists vinculo text;

create table if not exists public.rg_categorias (
  id bigint generated always as identity primary key,
  dominio text not null,                -- receita | despesa
  nome text not null,
  criado_em timestamptz default now()
);

create table if not exists public.rg_vendas (
  id bigint generated always as identity primary key,
  transacao text unique,
  produto text, nome text, email text, telefone text,
  valor numeric default 0, liquido numeric default 0,
  status text, data date, fin_lancado boolean default false,
  criado_em timestamptz default now()
);

create table if not exists public.rg_equipe (
  id bigint generated always as identity primary key,
  nome text not null, email text, cargo text, funcao text,
  tipo_contratacao text, salario numeric,
  nascimento date, admissao date, obs text,
  criado_em timestamptz default now()
);

create table if not exists public.rg_visitas (
  id bigint generated always as identity primary key,
  cliente_id bigint references public.rg_clientes(id) on delete cascade,
  data date not null default current_date,
  consultor text, atividades text, a_desenvolver text, obs text,
  fotos text,                           -- json de imagens pequenas
  criado_em timestamptz default now()
);

create table if not exists public.rg_links (
  id bigint generated always as identity primary key,
  titulo text not null, url text not null, area text,
  acesso text default 'todos',          -- todos | admin | especificos
  emails text,
  criado_em timestamptz default now()
);

create table if not exists public.rg_cursos (
  id bigint generated always as identity primary key,
  nome text not null, descricao text, drive_url text,
  status text default 'ativo',
  criado_em timestamptz default now()
);

do $$
declare t text;
begin
  foreach t in array array['rg_categorias','rg_visitas','rg_links','rg_cursos']
  loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists "membros acessam" on public.%I', t);
    execute format('create policy "membros acessam" on public.%I for all using (public.rg_is_member()) with check (public.rg_is_member())', t);
  end loop;
  -- equipe (salarios) e vendas (faturamento) so admins
  foreach t in array array['rg_equipe','rg_vendas']
  loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists "admin acessa" on public.%I', t);
    execute format('create policy "admin acessa" on public.%I for all using (public.rg_is_admin()) with check (public.rg_is_admin())', t);
  end loop;
end $$;

COMMIT;
