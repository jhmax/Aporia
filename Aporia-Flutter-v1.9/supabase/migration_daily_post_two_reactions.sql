-- Entrelinhas v1.5 migration for an EXISTING Supabase project.
-- Rules: one publication per account per Europe/Lisbon day; only Gosto/Levo comigo;
-- no self-reactions. Existing reflection/vote rows are preserved. Legacy reaction
-- values pensar/compreender are merged into gosto; levar remains levar.
-- Run this entire file in the existing project's Supabase SQL Editor.

begin;

-- Internal reservation table. It is not exposed to API client roles.
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

-- Backfill dates for existing posts. One slot is kept per author and Lisbon calendar date.
insert into entrelinhas_private.reflection_daily_slots
  (author_id, posting_date, reflection_id, reserved_at)
select distinct on (r.author_id, (r.created_at at time zone 'Europe/Lisbon')::date)
  r.author_id,
  (r.created_at at time zone 'Europe/Lisbon')::date,
  r.id,
  r.created_at
from public.reflections r
order by r.author_id, (r.created_at at time zone 'Europe/Lisbon')::date, r.created_at asc
on conflict (author_id, posting_date) do nothing;

-- Migrate reaction values and replace any old CHECK constraint involving reaction_type.
do $$
declare c record;
begin
  for c in
    select conname
    from pg_constraint
    where conrelid = 'public.reactions'::regclass
      and contype = 'c'
      and pg_get_constraintdef(oid) ilike '%reaction_type%'
  loop
    execute format('alter table public.reactions drop constraint %I', c.conname);
  end loop;
end $$;

update public.reactions
set reaction_type = 'gosto'
where reaction_type in ('pensar', 'compreender');

alter table public.reactions
  add constraint reactions_reaction_type_check
  check (reaction_type in ('gosto', 'levar'));

create index if not exists reflections_author_created_at_idx
  on public.reflections (author_id, created_at desc);

-- Remove an earlier draft implementation if it exists.
drop trigger if exists enforce_daily_reflection_limit on public.reflections;
drop function if exists public.enforce_daily_reflection_limit();

-- Server controls created_at so the client cannot forge the publication date.
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
create trigger stamp_reflection_created_at
before insert on public.reflections
for each row execute function public.stamp_reflection_created_at();

-- Reserve one publication slot per author/day. The unique key handles simultaneous inserts.
-- The slot remains reserved even if a user later deletes the reflection.
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
create trigger reserve_daily_reflection_slot
after insert on public.reflections
for each row execute function public.reserve_daily_reflection_slot();

-- The Write screen checks the server-side slot for the authenticated user.
create or replace function public.has_published_today()
returns boolean
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_today date;
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

-- Block reactions to the author's own publication, including direct API calls.
create or replace function public.prevent_self_reflection_reaction()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_author_id uuid;
begin
  select r.author_id into v_author_id
  from public.reflections r
  where r.id = new.reflection_id;

  if v_author_id is null then
    raise exception 'reflection_not_found' using errcode = 'P0001';
  end if;
  if new.user_id = v_author_id then
    raise exception 'self_reaction_not_allowed' using errcode = 'P0001';
  end if;
  return new;
end;
$$;
revoke all on function public.prevent_self_reflection_reaction() from public;
revoke all on function public.prevent_self_reflection_reaction() from anon;
drop trigger if exists prevent_self_reflection_reaction on public.reactions;
create trigger prevent_self_reflection_reaction
before insert or update on public.reactions
for each row execute function public.prevent_self_reflection_reaction();

-- Aggregate counts do not reveal voter ids and exclude any old self-reactions.
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

-- Keep the least-privilege policies already agreed for this project.
alter table public.reactions enable row level security;
alter table public.reflections enable row level security;
alter table public.reports enable row level security;

drop policy if exists "Authenticated users can read reactions" on public.reactions;
drop policy if exists "Users can read their own reactions" on public.reactions;
create policy "Users can read their own reactions"
  on public.reactions for select to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Users can create reports" on public.reports;
create policy "Users can create reports"
  on public.reports for insert to authenticated
  with check (auth.uid() = reporter_id and status = 'pending');

commit;
