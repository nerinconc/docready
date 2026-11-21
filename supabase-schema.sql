-- DocReady Production Schema (Supabase / PostgreSQL)
-- Run in Supabase SQL Editor (Free Tier)

create extension if not exists "pgcrypto";

create table firms (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid references auth.users(id) on delete cascade,
  name text not null,
  reply_to_email text not null,
  accent_color text default 'bg-blue-700',
  plan text default 'solo' check (plan in ('founding', 'solo', 'firm', 'agency')),
  created_at timestamptz default now()
);

create table clients (
  id uuid primary key default gen_random_uuid(),
  firm_id uuid references firms(id) on delete cascade not null,
  name text not null,
  contact_email text not null,
  close_period text not null, -- e.g. '2026-11'
  due_date date not null,
  magic_token text unique not null default encode(gen_random_bytes(16), 'hex'),
  last_chased_at timestamptz,
  created_at timestamptz default now()
);

create table document_items (
  id uuid primary key default gen_random_uuid(),
  client_id uuid references clients(id) on delete cascade not null,
  title text not null,
  status text default 'missing' check (status in ('missing', 'received', 'validated', 'flagged')),
  storage_path text,
  file_name text,
  updated_at timestamptz default now()
);

alter table firms enable row level security;
alter table clients enable row level security;
alter table document_items enable row level security;

-- Firm owners manage their own clients and documents
create policy "Firm owners manage firms" on firms
  for all using (auth.uid() = owner_user_id);

create policy "Firm owners manage clients" on clients
  for all using (firm_id in (select id from firms where owner_user_id = auth.uid()));

create policy "Firm owners manage docs" on document_items
  for all using (client_id in (
    select c.id from clients c join firms f on c.firm_id = f.id where f.owner_user_id = auth.uid()
  ));
