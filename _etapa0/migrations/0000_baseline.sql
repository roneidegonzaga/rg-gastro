-- ============================================================
-- MIGRATION 0000 — BASELINE
-- Extraida verbatim do bloco inicial de setup-supabase.sql
-- (linhas 1-189 do arquivo original, checksum de referencia:
-- 528a9a545c2067d2aeb8fd5764b7cbe6c609756cc2f2c71dba592aab57c01f5f)
--
-- NAO EXECUTAR sem autorizacao explicita e sem antes validar
-- contra um projeto Supabase de desenvolvimento vazio.
--
-- Endurecida em 31/07/2026: funcoes SECURITY DEFINER passaram a
-- fixar search_path = '' (todas as referencias ja eram totalmente
-- qualificadas por schema). Nenhuma regra de negocio foi alterada.
-- ============================================================

BEGIN;

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
returns trigger language plpgsql security definer
set search_path = ''
as $$
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
language sql security definer stable
set search_path = ''
as
$$ select exists(select 1 from public.profiles where user_id = auth.uid() and aprovado) $$;

create or replace function public.rg_is_admin() returns boolean
language sql security definer stable
set search_path = ''
as
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

COMMIT;
