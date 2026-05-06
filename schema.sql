-- =============================================================================
-- BOX JM — Schema inicial
-- Cole isso no SQL Editor do Supabase (projeto bbfseptqqaowqfejwovy) e execute.
-- Seguro rodar múltiplas vezes (idempotente).
-- =============================================================================

-- ── Tabela: services ────────────────────────────────────────────────────────
create table if not exists public.services (
  id          text primary key,
  name        text not null,
  base_price  numeric(10,2) not null check (base_price >= 0),
  category    text not null check (category in ('exterior','interior','protection','detailing')),
  description text,
  created_at  timestamptz not null default now()
);

create index if not exists services_category_idx on public.services (category);
create index if not exists services_created_at_idx on public.services (created_at);

-- ── Tabela: budgets ─────────────────────────────────────────────────────────
create table if not exists public.budgets (
  id             text primary key,
  client_name    text not null default '',
  client_phone   text not null default '',
  vehicle_brand  text not null default '',
  vehicle_model  text not null default '',
  vehicle_type   text not null default 'medium'
                   check (vehicle_type in ('small','medium','large','suv','truck')),
  items          jsonb not null default '[]'::jsonb,
  subtotal       numeric(10,2) not null default 0,
  multiplier     numeric(4,2)  not null default 1,
  total          numeric(10,2) not null default 0,
  status         text not null default 'draft'
                   check (status in ('draft','sent','approved','completed')),
  notes          text,
  created_at     timestamptz not null default now()
);

create index if not exists budgets_status_idx on public.budgets (status);
create index if not exists budgets_created_at_idx on public.budgets (created_at desc);

-- ── RLS ─────────────────────────────────────────────────────────────────────
-- Ativa RLS e permite tudo pra anon (sem auth por enquanto).
-- Quando você adicionar login, basta trocar as policies pra filtrar por auth.uid().

alter table public.services enable row level security;
alter table public.budgets  enable row level security;

drop policy if exists "anon all access" on public.services;
create policy "anon all access" on public.services
  for all using (true) with check (true);

drop policy if exists "anon all access" on public.budgets;
create policy "anon all access" on public.budgets
  for all using (true) with check (true);

-- ── Seed: serviços padrão ───────────────────────────────────────────────────
-- Usa upsert pra não duplicar se rodar de novo.

insert into public.services (id, name, base_price, category, description) values
  ('ext-wash-basic',     'Lavagem Básica',             50,   'exterior',   'Lavagem externa completa'),
  ('ext-wash-premium',   'Lavagem Premium',            80,   'exterior',   'Lavagem + cera + pneus'),
  ('ext-polimento',      'Polimento',                  200,  'exterior',   'Polimento técnico'),
  ('ext-cristalizacao',  'Cristalização',              350,  'exterior',   'Proteção vitrificada'),
  ('int-aspiracao',      'Aspiração Completa',         40,   'interior',   'Aspiração de todo interior'),
  ('int-higienizacao',   'Higienização',               150,  'interior',   'Limpeza profunda de bancos e carpetes'),
  ('int-hidratacao',     'Hidratação de Couro',        120,  'interior',   'Tratamento de bancos de couro'),
  ('prot-vitrificacao',  'Vitrificação',               800,  'protection', 'Proteção cerâmica 9H'),
  ('prot-ppf',           'PPF (Paint Protection Film)',1500, 'protection', 'Película de proteção de pintura'),
  ('det-motor',          'Limpeza de Motor',           80,   'detailing',  'Limpeza e proteção do motor'),
  ('det-farois',         'Polimento de Faróis',        120,  'detailing',  'Restauração de faróis')
on conflict (id) do nothing;
