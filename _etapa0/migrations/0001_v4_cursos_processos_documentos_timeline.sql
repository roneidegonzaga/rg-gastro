-- ============================================================
-- MIGRATION 0001 — v4: cursos, processos, documentos e linha do tempo
-- Extraida verbatim de setup-supabase.sql (bloco "NOVOS MODULOS v4")
-- Depende de: 0000_baseline.sql (usa public.rg_clientes,
-- public.rg_is_member())
--
-- NAO EXECUTAR sem autorizacao explicita e sem antes validar
-- contra um projeto Supabase de desenvolvimento vazio.
-- ============================================================

BEGIN;

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

COMMIT;
