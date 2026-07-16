-- ============================================================
-- PAINEL RG GASTRO | Setup do banco de dados
-- Cole este arquivo inteiro no SQL Editor do Supabase e rode.
-- ============================================================

-- ===== PERFIS E PAPEIS =====
create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  nome text,
  email text,
  role text not null default 'pendente',   -- admin | equipe | pendente
  aprovado boolean not null default false,
  criado_em timestamptz not null default now()
);

-- primeiro usuario cadastrado vira admin automaticamente
create or replace function public.rg_first_admin()
returns trigger language plpgsql security definer as $$
begin
  if (select count(*) from public.profiles) = 0 then
    new.role := 'admin';
    new.aprovado := true;
  end if;
  return new;
end $$;
drop trigger if exists trg_first_admin on public.profiles;
create trigger trg_first_admin before insert on public.profiles
  for each row execute function public.rg_first_admin();

-- helpers de permissao (security definer evita recursao de RLS)
create or replace function public.rg_is_member() returns boolean
language sql security definer stable as
$$ select exists(select 1 from public.profiles where user_id = auth.uid() and aprovado) $$;

create or replace function public.rg_is_admin() returns boolean
language sql security definer stable as
$$ select exists(select 1 from public.profiles where user_id = auth.uid() and aprovado and role = 'admin') $$;

alter table public.profiles enable row level security;
drop policy if exists "perfil proprio ou admin le" on public.profiles;
create policy "perfil proprio ou admin le" on public.profiles
  for select using (user_id = auth.uid() or public.rg_is_admin());
drop policy if exists "criar proprio perfil" on public.profiles;
create policy "criar proprio perfil" on public.profiles
  for insert with check (user_id = auth.uid());
drop policy if exists "editar perfil" on public.profiles;
create policy "editar perfil" on public.profiles
  for update using (user_id = auth.uid() or public.rg_is_admin());
drop policy if exists "admin remove perfil" on public.profiles;
create policy "admin remove perfil" on public.profiles
  for delete using (public.rg_is_admin());

-- ===== TABELAS DO PAINEL =====
create table if not exists public.rg_financeiro (
  id bigint generated always as identity primary key,
  tipo text not null,                -- receita | despesa
  categoria text,                    -- infoproduto | consultoria | mentoria | outros | custo fixo | custo variavel
  descricao text,
  valor numeric not null default 0,
  data date not null default current_date,
  criado_em timestamptz default now()
);

create table if not exists public.rg_contas (
  id bigint generated always as identity primary key,
  tipo text not null,                -- pagar | receber
  descricao text,
  categoria text,
  valor numeric not null default 0,
  vencimento date not null,
  status text not null default 'aberto',  -- aberto | pago
  recorrente text,                   -- null | mensal
  ref text,                          -- cliente/mentorado/fornecedor
  criado_em timestamptz default now()
);

create table if not exists public.rg_metas (
  id bigint generated always as identity primary key,
  mes text not null,                 -- formato 2026-07
  categoria text not null,           -- infoproduto | consultoria | mentoria | total
  valor numeric not null default 0
);

create table if not exists public.rg_crm (
  id bigint generated always as identity primary key,
  nome text not null,
  contato text,
  origem text,
  interesse text,                    -- consultoria | mentoria | infoproduto
  valor numeric default 0,
  etapa text not null default 'novo', -- novo | conversa | proposta | fechado | perdido
  obs text,
  atualizado timestamptz default now()
);

create table if not exists public.rg_clientes (
  id bigint generated always as identity primary key,
  nome text not null,
  restaurante text,
  contato text,
  cidade text,
  status text not null default 'ativo',  -- ativo | pausado | encerrado
  inicio date,
  valor_mensal numeric default 0,
  obs text
);

create table if not exists public.rg_mentorados (
  id bigint generated always as identity primary key,
  nome text not null,
  contato text,
  produto text,                      -- CCP | mentoria individual | outro
  status text not null default 'ativo',
  inicio date,
  obs text
);

create table if not exists public.rg_sessoes (
  id bigint generated always as identity primary key,
  mentorado_id bigint references public.rg_mentorados(id) on delete cascade,
  data date,
  hora text,
  resumo text,
  status text not null default 'agendada'  -- agendada | realizada | cancelada
);

create table if not exists public.rg_plano_itens (
  id bigint generated always as identity primary key,
  mentorado_id bigint references public.rg_mentorados(id) on delete cascade,
  cliente_id bigint references public.rg_clientes(id) on delete cascade,
  item text not null,
  prazo date,
  status text not null default 'aberto'   -- aberto | fazendo | feito
);

create table if not exists public.rg_projetos (
  id bigint generated always as identity primary key,
  nome text not null,
  cliente_id bigint references public.rg_clientes(id) on delete set null,
  status text not null default 'ativo',   -- ativo | concluido | pausado
  prazo date
);

create table if not exists public.rg_tarefas (
  id bigint generated always as identity primary key,
  titulo text not null,
  projeto_id bigint references public.rg_projetos(id) on delete set null,
  cliente_id bigint references public.rg_clientes(id) on delete set null,
  responsavel text,
  prazo date,
  status text not null default 'aberta'   -- aberta | fazendo | feita
);

create table if not exists public.rg_agenda (
  id bigint generated always as identity primary key,
  titulo text not null,
  data date not null,
  hora text,
  tipo text,                         -- sessao | reuniao | prazo | outro
  ref text,
  obs text
);

-- dados do Sistema D.O.S.E. de cada cliente (isolados por cliente)
create table if not exists public.rg_dose (
  cliente_id bigint not null references public.rg_clientes(id) on delete cascade,
  key text not null,
  value text,
  updated_at timestamptz not null default now(),
  primary key (cliente_id, key)
);

-- ===== RLS: membros aprovados acessam; financeiro e contas so admin =====
do $$
declare t text;
begin
  foreach t in array array['rg_crm','rg_clientes','rg_mentorados','rg_sessoes','rg_plano_itens','rg_projetos','rg_tarefas','rg_agenda','rg_dose']
  loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists "membros acessam" on public.%I', t);
    execute format('create policy "membros acessam" on public.%I for all using (public.rg_is_member()) with check (public.rg_is_member())', t);
  end loop;
  foreach t in array array['rg_financeiro','rg_contas','rg_metas']
  loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists "admin acessa" on public.%I', t);
    execute format('create policy "admin acessa" on public.%I for all using (public.rg_is_admin()) with check (public.rg_is_admin())', t);
  end loop;
end $$;


-- ============================================================
-- NOVOS MODULOS (v4): cursos, processos, documentos e linha do tempo
-- Pode rodar este bloco sozinho se o banco ja existir.
-- ============================================================
alter table public.rg_clientes add column if not exists tipo_consultoria text;

create table if not exists public.rg_alunos (
  id bigint generated always as identity primary key,
  nome text not null,
  contato text,
  curso text,
  inicio date,
  etapa int not null default 0,        -- 0 a 9 etapas concluidas (9 = certificado emitido)
  obs text,
  criado_em timestamptz default now()
);

create table if not exists public.rg_processos (
  id bigint generated always as identity primary key,
  nome text not null,
  area text,                            -- comercial | financeiro | infoprodutos | clientes de consultoria | mentoria | cursos | geral
  blocos text,                          -- json: [{t:'texto'|'fluxo'|'mapa'|'img', v:'...'}]
  atualizado timestamptz default now(),
  criado_em timestamptz default now()
);

create table if not exists public.rg_documentos (
  id bigint generated always as identity primary key,
  cliente_id bigint references public.rg_clientes(id) on delete cascade,
  nome text,
  tipo text not null default 'link',    -- link | arquivo (data url ate 1,5MB)
  url text,
  criado_em timestamptz default now()
);

create table if not exists public.rg_etapas (
  id bigint generated always as identity primary key,
  cliente_id bigint references public.rg_clientes(id) on delete cascade,
  nome text not null,
  prazo date,
  status text not null default 'aberto',  -- aberto | fazendo | feito
  ordem int not null default 0,
  criado_em timestamptz default now()
);

do $$
declare t text;
begin
  foreach t in array array['rg_alunos','rg_processos','rg_documentos','rg_etapas']
  loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists "membros acessam" on public.%I', t);
    execute format('create policy "membros acessam" on public.%I for all using (public.rg_is_member()) with check (public.rg_is_member())', t);
  end loop;
end $$;


-- ============================================================
-- NOVOS MODULOS (v5): categorias, vendas, equipe, visitas,
-- links, cursos e colunas extras. Pode rodar sozinho.
-- ============================================================
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
