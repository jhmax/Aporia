-- Between the Lines: beta schema for Flutter Web + Android/iOS.
-- Run in the Supabase project SQL Editor.
-- The client app uses only the publishable key; never use service_role on the client.

create extension if not exists pgcrypto;

-- Internal reservation table; never expose this schema to client/API roles.
create schema if not exists entrelinhas_private;
revoke all on schema entrelinhas_private from public, anon, authenticated;
create table if not exists entrelinhas_private.reflection_daily_slots (
  author_id uuid not null references auth.users(id) on delete cascade,
  posting_date date not null,
  reflection_id uuid not null,
  reserved_at timestamptz not null default pg_catalog.now(),
  primary key (author_id, posting_date)
);
revoke all on table entrelinhas_private.reflection_daily_slots from public, anon, authenticated;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (char_length(trim(display_name)) between 2 and 36),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.reflections (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles(id) on delete cascade,
  author_name text not null,
  body text not null check (char_length(trim(body)) between 10 and 1200),
  created_at timestamptz not null default now()
);

create table if not exists public.reactions (
  reflection_id uuid not null references public.reflections(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  reaction_type text not null check (reaction_type in ('gosto', 'levar')),
  created_at timestamptz not null default now(),
  primary key (reflection_id, user_id)
);

create table if not exists public.saved_reflections (
  reflection_id uuid not null references public.reflections(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (reflection_id, user_id)
);

create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  reflection_id uuid not null references public.reflections(id) on delete cascade,
  reporter_id uuid not null references auth.users(id) on delete cascade,
  reason text not null check (reason in ('spam', 'abuso', 'other')),
  status text not null default 'pending' check (status in ('pending', 'reviewed', 'dismissed', 'actioned')),
  created_at timestamptz not null default now(),
  unique (reflection_id, reporter_id)
);

create index if not exists reflections_created_at_idx on public.reflections (created_at desc);
create index if not exists reflections_author_id_idx on public.reflections (author_id);
create index if not exists reflections_author_created_at_idx on public.reflections (author_id, created_at desc);
create index if not exists reactions_reflection_id_idx on public.reactions (reflection_id);
create index if not exists reactions_user_id_idx on public.reactions (user_id);
create index if not exists saved_reflections_user_id_idx on public.saved_reflections (user_id);
create index if not exists reports_status_created_idx on public.reports (status, created_at desc);

-- Create a profile when Supabase Auth creates a user.
create or replace function public.handle_new_entrelinhas_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  requested_name text;
begin
  requested_name := trim(coalesce(new.raw_user_meta_data ->> 'display_name', split_part(coalesce(new.email, 'user'), '@', 1)));
  if char_length(requested_name) < 2 then requested_name := 'User'; end if;
  if char_length(requested_name) > 36 then requested_name := left(requested_name, 36); end if;
  insert into public.profiles (id, display_name)
  values (new.id, requested_name)
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_entrelinhas on auth.users;
create trigger on_auth_user_created_entrelinhas
after insert on auth.users
for each row execute procedure public.handle_new_entrelinhas_user();

-- The database snapshots the author name. The client cannot impersonate another author.
create or replace function public.set_entrelinhas_author_name()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  select p.display_name into new.author_name
  from public.profiles p
  where p.id = new.author_id;
  if new.author_name is null or char_length(trim(new.author_name)) = 0 then
    raise exception 'Author profile not found';
  end if;
  return new;
end;
$$;

drop trigger if exists before_reflection_insert_entrelinhas on public.reflections;
create trigger before_reflection_insert_entrelinhas
before insert on public.reflections
for each row execute procedure public.set_entrelinhas_author_name();

-- Row Level Security. Safe to re-run: policies are dropped before recreation.
alter table public.profiles enable row level security;
alter table public.reflections enable row level security;
alter table public.reactions enable row level security;
alter table public.saved_reflections enable row level security;
alter table public.reports enable row level security;

drop policy if exists "Users can read own profile" on public.profiles;
drop policy if exists "Users can update own profile" on public.profiles;
drop policy if exists "Authenticated users can read reflections" on public.reflections;
drop policy if exists "Users can create their own reflections" on public.reflections;
drop policy if exists "Users can delete their own reflections" on public.reflections;
drop policy if exists "Authenticated users can read reactions" on public.reactions;
drop policy if exists "Users can read their own reactions" on public.reactions;
drop policy if exists "Users can create their own reactions" on public.reactions;
drop policy if exists "Users can edit their own reactions" on public.reactions;
drop policy if exists "Users can delete their own reactions" on public.reactions;
drop policy if exists "Users can read their own saved reflections" on public.saved_reflections;
drop policy if exists "Users can save their own reflections" on public.saved_reflections;
drop policy if exists "Users can unsave their own reflections" on public.saved_reflections;
drop policy if exists "Users can create reports" on public.reports;
drop policy if exists "Users can read their own reports" on public.reports;

create policy "Users can read own profile"
  on public.profiles for select to authenticated using (auth.uid() = id);
create policy "Users can update own profile"
  on public.profiles for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);

create policy "Authenticated users can read reflections"
  on public.reflections for select to authenticated using (true);
create policy "Users can create their own reflections"
  on public.reflections for insert to authenticated with check (auth.uid() = author_id);
create policy "Users can delete their own reflections"
  on public.reflections for delete to authenticated using (auth.uid() = author_id);

create policy "Users can read their own reactions"
  on public.reactions for select to authenticated using (auth.uid() = user_id);
create policy "Users can create their own reactions"
  on public.reactions for insert to authenticated with check (auth.uid() = user_id);
create policy "Users can edit their own reactions"
  on public.reactions for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users can delete their own reactions"
  on public.reactions for delete to authenticated using (auth.uid() = user_id);

create policy "Users can read their own saved reflections"
  on public.saved_reflections for select to authenticated using (auth.uid() = user_id);
create policy "Users can save their own reflections"
  on public.saved_reflections for insert to authenticated with check (auth.uid() = user_id);
create policy "Users can unsave their own reflections"
  on public.saved_reflections for delete to authenticated using (auth.uid() = user_id);

create policy "Users can create reports"
  on public.reports for insert to authenticated with check (auth.uid() = reporter_id and status = 'pending');
create policy "Users can read their own reports"
  on public.reports for select to authenticated using (auth.uid() = reporter_id);

-- Return aggregate reaction counts without exposing other users' reaction rows.
create or replace function public.get_reaction_counts(
  p_reflection_ids uuid[]
)
returns table (
  reflection_id uuid,
  reaction_type text,
  reaction_count bigint
)
language sql
stable
security definer
set search_path = ''
as $$
  select r.reflection_id, r.reaction_type, count(*)::bigint as reaction_count
  from public.reactions r
  join public.reflections f on f.id = r.reflection_id
  where r.reflection_id = any(coalesce(p_reflection_ids, array[]::uuid[]))
    and r.user_id <> f.author_id
  group by r.reflection_id, r.reaction_type;
$$;
revoke all on function public.get_reaction_counts(uuid[]) from public;
revoke all on function public.get_reaction_counts(uuid[]) from anon;
grant execute on function public.get_reaction_counts(uuid[]) to authenticated;

-- Enforce one publication per account per Europe/Lisbon calendar day.
create or replace function public.stamp_reflection_created_at()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  new.created_at := pg_catalog.now();
  return new;
end;
$$;
revoke all on function public.stamp_reflection_created_at() from public;
revoke all on function public.stamp_reflection_created_at() from anon;
drop trigger if exists stamp_reflection_created_at on public.reflections;
create trigger stamp_reflection_created_at before insert on public.reflections
for each row execute function public.stamp_reflection_created_at();

create or replace function public.reserve_daily_reflection_slot()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_today date;
  v_reserved boolean;
begin
  v_today := (pg_catalog.now() at time zone 'Europe/Lisbon')::date;
  insert into entrelinhas_private.reflection_daily_slots
    (author_id, posting_date, reflection_id, reserved_at)
  values (new.author_id, v_today, new.id, pg_catalog.now())
  on conflict (author_id, posting_date) do nothing
  returning true into v_reserved;
  if not found then
    raise exception 'daily_reflection_limit' using errcode = 'P0001';
  end if;
  return new;
end;
$$;
revoke all on function public.reserve_daily_reflection_slot() from public;
revoke all on function public.reserve_daily_reflection_slot() from anon;
drop trigger if exists reserve_daily_reflection_slot on public.reflections;
create trigger reserve_daily_reflection_slot after insert on public.reflections
for each row execute function public.reserve_daily_reflection_slot();

create or replace function public.has_published_today()
returns boolean
language plpgsql
stable
security definer
set search_path = ''
as $$
declare v_today date;
begin
  if auth.uid() is null then return false; end if;
  v_today := (pg_catalog.now() at time zone 'Europe/Lisbon')::date;
  return exists (
    select 1 from entrelinhas_private.reflection_daily_slots s
    where s.author_id = auth.uid() and s.posting_date = v_today
  );
end;
$$;
revoke all on function public.has_published_today() from public;
revoke all on function public.has_published_today() from anon;
grant execute on function public.has_published_today() to authenticated;

-- Prevent users from reacting to their own publications.
create or replace function public.prevent_self_reflection_reaction()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare v_author_id uuid;
begin
  select r.author_id into v_author_id from public.reflections r where r.id = new.reflection_id;
  if v_author_id is null then raise exception 'reflection_not_found' using errcode = 'P0001'; end if;
  if new.user_id = v_author_id then raise exception 'self_reaction_not_allowed' using errcode = 'P0001'; end if;
  return new;
end;
$$;
revoke all on function public.prevent_self_reflection_reaction() from public;
revoke all on function public.prevent_self_reflection_reaction() from anon;
drop trigger if exists prevent_self_reflection_reaction on public.reactions;
create trigger prevent_self_reflection_reaction before insert or update on public.reactions
for each row execute function public.prevent_self_reflection_reaction();

grant select, insert, delete on public.reflections to authenticated;
grant select, insert, update, delete on public.reactions to authenticated;
grant select, insert, delete on public.saved_reflections to authenticated;
grant select, update on public.profiles to authenticated;
grant select, insert on public.reports to authenticated;

-- Enable Supabase Realtime for shared updates (safe to run repeatedly).
do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'reflections') then
    alter publication supabase_realtime add table public.reflections;
  end if;
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'reactions') then
    alter publication supabase_realtime add table public.reactions;
  end if;
end $$;
