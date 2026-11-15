-- Aporia: private, time-limited dialogues (v1.9)
-- Apply once in Supabase SQL Editor AFTER the existing Entrelinhas/Aporia schema.
-- All writes go through SECURITY DEFINER RPCs. Client roles receive SELECT only,
-- guarded by RLS. No service_role key is required in the Flutter app.

begin;

-- Per-account preference. Existing profiles default to accepting invitations.
alter table public.profiles
  add column if not exists allow_dialogue_invites boolean not null default true;

create table if not exists public.dialogue_invites (
  id uuid primary key default gen_random_uuid(),
  reflection_id uuid not null references public.reflections(id) on delete cascade,
  sender_id uuid not null references auth.users(id) on delete cascade,
  recipient_id uuid not null references auth.users(id) on delete cascade,
  sender_name text not null,
  recipient_name text not null,
  reflection_body text not null,
  message text not null,
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'declined', 'blocked')),
  created_at timestamptz not null default now(),
  responded_at timestamptz,
  constraint dialogue_invites_different_users check (sender_id <> recipient_id),
  constraint dialogue_invites_message_length check (char_length(btrim(message)) between 10 and 2000),
  constraint dialogue_invites_no_links check (message !~* '(https?://|www[.]|[[:alnum:]_-]+[.][[:alpha:]]{2,}([.][[:alpha:]]{2,})?([^[:alnum:]_-]|$))')
);

-- One invitation per sender and reflection. A new reflection creates a new
-- independent opportunity, including between the same two people.
create unique index if not exists dialogue_invites_one_per_reflection_sender
  on public.dialogue_invites(reflection_id, sender_id);
create index if not exists dialogue_invites_recipient_status_created
  on public.dialogue_invites(recipient_id, status, created_at desc);
create index if not exists dialogue_invites_sender_status_created
  on public.dialogue_invites(sender_id, status, created_at desc);

create table if not exists public.dialogues (
  id uuid primary key default gen_random_uuid(),
  invite_id uuid not null unique references public.dialogue_invites(id) on delete cascade,
  reflection_id uuid not null references public.reflections(id) on delete cascade,
  sender_id uuid not null references auth.users(id) on delete cascade,
  recipient_id uuid not null references auth.users(id) on delete cascade,
  sender_name text not null,
  recipient_name text not null,
  reflection_body text not null,
  started_at timestamptz not null default now(),
  ends_at timestamptz not null default (now() + interval '24 hours'),
  status text not null default 'active' check (status in ('active', 'ended')),
  ended_at timestamptz,
  end_reason text check (end_reason is null or end_reason in ('participant_ended', 'expired', 'blocked')),
  sender_extend_requested boolean not null default false,
  recipient_extend_requested boolean not null default false,
  constraint dialogues_different_users check (sender_id <> recipient_id)
);
create index if not exists dialogues_sender_active_ends on public.dialogues(sender_id, status, ends_at);
create index if not exists dialogues_recipient_active_ends on public.dialogues(recipient_id, status, ends_at);

create table if not exists public.dialogue_messages (
  id uuid primary key default gen_random_uuid(),
  dialogue_id uuid not null references public.dialogues(id) on delete cascade,
  sender_id uuid not null references auth.users(id) on delete cascade,
  body text not null check (char_length(btrim(body)) between 1 and 2000),
  created_at timestamptz not null default now(),
  constraint dialogue_messages_no_links check (body !~* '(https?://|www[.]|[[:alnum:]_-]+[.][[:alpha:]]{2,}([.][[:alpha:]]{2,})?([^[:alnum:]_-]|$))')
);
create index if not exists dialogue_messages_dialogue_created
  on public.dialogue_messages(dialogue_id, created_at asc);

create table if not exists public.dialogue_blocks (
  blocker_id uuid not null references auth.users(id) on delete cascade,
  blocked_id uuid not null references auth.users(id) on delete cascade,
  blocked_name text not null,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  constraint dialogue_blocks_different_users check (blocker_id <> blocked_id)
);

create table if not exists public.dialogue_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references auth.users(id) on delete cascade,
  reported_user_id uuid not null references auth.users(id) on delete cascade,
  invite_id uuid references public.dialogue_invites(id) on delete set null,
  dialogue_id uuid references public.dialogues(id) on delete set null,
  reason text not null check (reason in ('spam', 'abuse', 'other')),
  details text check (details is null or char_length(details) <= 1000),
  status text not null default 'pending' check (status in ('pending', 'reviewed', 'dismissed', 'actioned')),
  created_at timestamptz not null default now(),
  constraint dialogue_reports_different_users check (reporter_id <> reported_user_id)
);
create index if not exists dialogue_reports_status_created
  on public.dialogue_reports(status, created_at desc);

-- RLS: participants may read their own invitations/dialogues/messages only.
alter table public.dialogue_invites enable row level security;
alter table public.dialogues enable row level security;
alter table public.dialogue_messages enable row level security;
alter table public.dialogue_blocks enable row level security;
alter table public.dialogue_reports enable row level security;

revoke all on public.dialogue_invites from public, anon, authenticated;
revoke all on public.dialogues from public, anon, authenticated;
revoke all on public.dialogue_messages from public, anon, authenticated;
revoke all on public.dialogue_blocks from public, anon, authenticated;
revoke all on public.dialogue_reports from public, anon, authenticated;

grant select on public.dialogue_invites to authenticated;
grant select on public.dialogues to authenticated;
grant select on public.dialogue_messages to authenticated;
grant select on public.dialogue_blocks to authenticated;
grant select on public.dialogue_reports to authenticated;

drop policy if exists "dialogue_invites_participant_read" on public.dialogue_invites;
create policy "dialogue_invites_participant_read"
  on public.dialogue_invites for select to authenticated
  using (auth.uid() = sender_id or auth.uid() = recipient_id);

drop policy if exists "dialogues_participant_read" on public.dialogues;
create policy "dialogues_participant_read"
  on public.dialogues for select to authenticated
  using (auth.uid() = sender_id or auth.uid() = recipient_id);

drop policy if exists "dialogue_messages_participant_read" on public.dialogue_messages;
create policy "dialogue_messages_participant_read"
  on public.dialogue_messages for select to authenticated
  using (exists (
    select 1 from public.dialogues d
    where d.id = dialogue_messages.dialogue_id
      and (d.sender_id = auth.uid() or d.recipient_id = auth.uid())
  ));

drop policy if exists "dialogue_blocks_owner_read" on public.dialogue_blocks;
create policy "dialogue_blocks_owner_read"
  on public.dialogue_blocks for select to authenticated
  using (auth.uid() = blocker_id);

drop policy if exists "dialogue_reports_reporter_read" on public.dialogue_reports;
create policy "dialogue_reports_reporter_read"
  on public.dialogue_reports for select to authenticated
  using (auth.uid() = reporter_id);

-- Internal helper called only by the SECURITY DEFINER RPCs below.
create or replace function public.require_confirmed_dialogue_account()
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare v_user uuid := auth.uid();
begin
  if v_user is null then
    raise exception 'not_authenticated' using errcode = 'P0001';
  end if;
  if not exists (
    select 1 from auth.users u
    where u.id = v_user and u.email_confirmed_at is not null
  ) then
    raise exception 'email_not_confirmed' using errcode = 'P0001';
  end if;
  return v_user;
end;
$$;
revoke all on function public.require_confirmed_dialogue_account() from public, anon, authenticated;

-- Create an invitation tied to a specific reflection. Links are deliberately
-- rejected at the server; the initial invitation is text-only (no attachments).
create or replace function public.create_dialogue_invite(
  p_reflection_id uuid,
  p_message text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
  v_recipient uuid;
  v_sender_name text;
  v_recipient_name text;
  v_reflection_body text;
  v_message text := pg_catalog.btrim(coalesce(p_message, ''));
  v_id uuid;
begin
  v_user := public.require_confirmed_dialogue_account();
  if pg_catalog.char_length(v_message) < 10 or pg_catalog.char_length(v_message) > 2000 then
    raise exception 'dialogue_invite_message_length' using errcode = 'P0001';
  end if;
  if v_message ~* '(https?://|www[.]|[[:alnum:]_-]+[.][[:alpha:]]{2,}([.][[:alpha:]]{2,})?([^[:alnum:]_-]|$))' then
    raise exception 'dialogue_links_not_allowed' using errcode = 'P0001';
  end if;

  select r.author_id, r.body
    into v_recipient, v_reflection_body
  from public.reflections r
  where r.id = p_reflection_id;
  if not found then
    raise exception 'reflection_not_found' using errcode = 'P0001';
  end if;
  if v_recipient = v_user then
    raise exception 'dialogue_self_invite_not_allowed' using errcode = 'P0001';
  end if;

  select p.display_name into v_sender_name
  from public.profiles p where p.id = v_user;
  select p.display_name into v_recipient_name
  from public.profiles p
  where p.id = v_recipient and p.allow_dialogue_invites = true;
  if v_recipient_name is null then
    raise exception 'dialogue_invites_disabled' using errcode = 'P0001';
  end if;

  if exists (
    select 1 from public.dialogue_blocks b
    where (b.blocker_id = v_user and b.blocked_id = v_recipient)
       or (b.blocker_id = v_recipient and b.blocked_id = v_user)
  ) then
    raise exception 'dialogue_blocked_between_users' using errcode = 'P0001';
  end if;

  insert into public.dialogue_invites (
    reflection_id, sender_id, recipient_id, sender_name,
    recipient_name, reflection_body, message
  ) values (
    p_reflection_id, v_user, v_recipient,
    coalesce(v_sender_name, 'Utilizador'),
    coalesce(v_recipient_name, 'Utilizador'),
    v_reflection_body, v_message
  ) returning id into v_id;

  return v_id;
exception
  when unique_violation then
    raise exception 'dialogue_invite_already_sent_for_reflection' using errcode = 'P0001';
end;
$$;

-- Recipient sees the full message before deciding. Acceptance creates one
-- 24-hour dialogue and places the invitation message as its first message.
create or replace function public.respond_dialogue_invite(
  p_invite_id uuid,
  p_accept boolean
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
  v_invite public.dialogue_invites%rowtype;
  v_dialogue_id uuid;
begin
  v_user := public.require_confirmed_dialogue_account();

  select * into v_invite
  from public.dialogue_invites i
  where i.id = p_invite_id
  for update;
  if not found then
    raise exception 'dialogue_invite_not_found' using errcode = 'P0001';
  end if;
  if v_invite.recipient_id <> v_user then
    raise exception 'dialogue_invite_not_recipient' using errcode = 'P0001';
  end if;
  if v_invite.status <> 'pending' then
    raise exception 'dialogue_invite_already_answered' using errcode = 'P0001';
  end if;

  if exists (
    select 1 from public.dialogue_blocks b
    where (b.blocker_id = v_user and b.blocked_id = v_invite.sender_id)
       or (b.blocker_id = v_invite.sender_id and b.blocked_id = v_user)
  ) then
    raise exception 'dialogue_blocked_between_users' using errcode = 'P0001';
  end if;

  if not p_accept then
    update public.dialogue_invites
      set status = 'declined', responded_at = pg_catalog.now()
      where id = p_invite_id;
    return null;
  end if;

  insert into public.dialogues (
    invite_id, reflection_id, sender_id, recipient_id,
    sender_name, recipient_name, reflection_body,
    started_at, ends_at
  ) values (
    v_invite.id, v_invite.reflection_id, v_invite.sender_id,
    v_invite.recipient_id, v_invite.sender_name, v_invite.recipient_name,
    v_invite.reflection_body, pg_catalog.now(), pg_catalog.now() + interval '24 hours'
  ) returning id into v_dialogue_id;

  update public.dialogue_invites
    set status = 'accepted', responded_at = pg_catalog.now()
    where id = p_invite_id;

  insert into public.dialogue_messages(dialogue_id, sender_id, body)
    values (v_dialogue_id, v_invite.sender_id, v_invite.message);

  return v_dialogue_id;
end;
$$;

-- Send text-only messages while the dialogue is active. The server enforces
-- the 24-hour deadline, participants, block status and link prohibition.
create or replace function public.send_dialogue_message(
  p_dialogue_id uuid,
  p_body text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
  v_dialogue public.dialogues%rowtype;
  v_body text := pg_catalog.btrim(coalesce(p_body, ''));
  v_message_id uuid;
begin
  v_user := public.require_confirmed_dialogue_account();
  if pg_catalog.char_length(v_body) < 1 or pg_catalog.char_length(v_body) > 2000 then
    raise exception 'dialogue_message_length' using errcode = 'P0001';
  end if;
  if v_body ~* '(https?://|www[.]|[[:alnum:]_-]+[.][[:alpha:]]{2,}([.][[:alpha:]]{2,})?([^[:alnum:]_-]|$))' then
    raise exception 'dialogue_links_not_allowed' using errcode = 'P0001';
  end if;

  select * into v_dialogue
  from public.dialogues d
  where d.id = p_dialogue_id
  for update;
  if not found or (v_dialogue.sender_id <> v_user and v_dialogue.recipient_id <> v_user) then
    raise exception 'dialogue_not_found' using errcode = 'P0001';
  end if;
  if v_dialogue.status <> 'active' or v_dialogue.ends_at <= pg_catalog.now() then
    raise exception 'dialogue_expired' using errcode = 'P0001';
  end if;
  if exists (
    select 1 from public.dialogue_blocks b
    where (b.blocker_id = v_dialogue.sender_id and b.blocked_id = v_dialogue.recipient_id)
       or (b.blocker_id = v_dialogue.recipient_id and b.blocked_id = v_dialogue.sender_id)
  ) then
    raise exception 'dialogue_blocked_between_users' using errcode = 'P0001';
  end if;

  insert into public.dialogue_messages(dialogue_id, sender_id, body)
    values (p_dialogue_id, v_user, v_body)
    returning id into v_message_id;
  return v_message_id;
end;
$$;

-- Each participant can request one more 24-hour period during the final six
-- hours. A new period starts only when BOTH independent votes are true.
create or replace function public.request_dialogue_extension(p_dialogue_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
  v_dialogue public.dialogues%rowtype;
  v_sender_yes boolean;
  v_recipient_yes boolean;
  v_ends_at timestamptz;
  v_extended boolean := false;
begin
  v_user := public.require_confirmed_dialogue_account();

  select * into v_dialogue
  from public.dialogues d
  where d.id = p_dialogue_id
  for update;
  if not found or (v_dialogue.sender_id <> v_user and v_dialogue.recipient_id <> v_user) then
    raise exception 'dialogue_not_found' using errcode = 'P0001';
  end if;
  if v_dialogue.status <> 'active' or v_dialogue.ends_at <= pg_catalog.now() then
    raise exception 'dialogue_expired' using errcode = 'P0001';
  end if;
  if exists (
    select 1 from public.dialogue_blocks b
    where (b.blocker_id = v_dialogue.sender_id and b.blocked_id = v_dialogue.recipient_id)
       or (b.blocker_id = v_dialogue.recipient_id and b.blocked_id = v_dialogue.sender_id)
  ) then
    raise exception 'dialogue_blocked_between_users' using errcode = 'P0001';
  end if;
  if v_dialogue.ends_at - interval '6 hours' > pg_catalog.now() then
    raise exception 'dialogue_extension_window_not_open' using errcode = 'P0001';
  end if;

  v_sender_yes := v_dialogue.sender_extend_requested or v_user = v_dialogue.sender_id;
  v_recipient_yes := v_dialogue.recipient_extend_requested or v_user = v_dialogue.recipient_id;

  if v_sender_yes and v_recipient_yes then
    v_ends_at := v_dialogue.ends_at + interval '24 hours';
    update public.dialogues
      set ends_at = v_ends_at,
          sender_extend_requested = false,
          recipient_extend_requested = false
      where id = p_dialogue_id;
    v_extended := true;
  else
    update public.dialogues
      set sender_extend_requested = v_sender_yes,
          recipient_extend_requested = v_recipient_yes
      where id = p_dialogue_id;
    v_ends_at := v_dialogue.ends_at;
  end if;

  return pg_catalog.jsonb_build_object(
    'extended', v_extended,
    'ends_at', v_ends_at,
    'sender_requested', case when v_extended then false else v_sender_yes end,
    'recipient_requested', case when v_extended then false else v_recipient_yes end
  );
end;
$$;

create or replace function public.end_dialogue(p_dialogue_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare v_user uuid := auth.uid();
begin
  v_user := public.require_confirmed_dialogue_account();
  update public.dialogues d
    set status = 'ended', ended_at = pg_catalog.now(), end_reason = 'participant_ended'
  where d.id = p_dialogue_id
    and d.status = 'active'
    and (d.sender_id = v_user or d.recipient_id = v_user);
  if not found then raise exception 'dialogue_not_found_or_ended' using errcode = 'P0001'; end if;
end;
$$;

-- Lazy expiry: no scheduled job is needed. The app calls this when opening
-- the dialogue centre; writes also independently enforce ends_at.
create or replace function public.refresh_dialogue_status()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare v_user uuid := auth.uid(); v_count integer;
begin
  v_user := public.require_confirmed_dialogue_account();
  update public.dialogues d
    set status = 'ended', ended_at = d.ends_at, end_reason = 'expired'
  where d.status = 'active'
    and d.ends_at <= pg_catalog.now()
    and (d.sender_id = v_user or d.recipient_id = v_user);
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

create or replace function public.set_dialogue_invites_enabled(p_enabled boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare v_user uuid := auth.uid();
begin
  v_user := public.require_confirmed_dialogue_account();
  update public.profiles set allow_dialogue_invites = p_enabled where id = v_user;
  if not found then raise exception 'profile_not_found' using errcode = 'P0001'; end if;
end;
$$;

create or replace function public.block_dialogue_user(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
  v_name text;
begin
  v_user := public.require_confirmed_dialogue_account();
  if p_user_id is null or p_user_id = v_user then
    raise exception 'invalid_block_target' using errcode = 'P0001';
  end if;
  select p.display_name into v_name from public.profiles p where p.id = p_user_id;
  if v_name is null then raise exception 'profile_not_found' using errcode = 'P0001'; end if;

  insert into public.dialogue_blocks(blocker_id, blocked_id, blocked_name)
    values (v_user, p_user_id, v_name)
    on conflict (blocker_id, blocked_id) do nothing;

  update public.dialogue_invites i
    set status = 'blocked', responded_at = pg_catalog.now()
  where i.status = 'pending'
    and ((i.sender_id = v_user and i.recipient_id = p_user_id)
      or (i.sender_id = p_user_id and i.recipient_id = v_user));

  update public.dialogues d
    set status = 'ended', ended_at = pg_catalog.now(), end_reason = 'blocked'
  where d.status = 'active'
    and ((d.sender_id = v_user and d.recipient_id = p_user_id)
      or (d.sender_id = p_user_id and d.recipient_id = v_user));
end;
$$;

create or replace function public.unblock_dialogue_user(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare v_user uuid := auth.uid();
begin
  v_user := public.require_confirmed_dialogue_account();
  delete from public.dialogue_blocks
  where blocker_id = v_user and blocked_id = p_user_id;
end;
$$;

create or replace function public.report_dialogue_user(
  p_reported_user_id uuid,
  p_reason text,
  p_invite_id uuid default null,
  p_dialogue_id uuid default null,
  p_details text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
  v_other uuid;
  v_report_id uuid;
begin
  v_user := public.require_confirmed_dialogue_account();
  if p_reported_user_id is null or p_reported_user_id = v_user then
    raise exception 'invalid_report_target' using errcode = 'P0001';
  end if;
  if p_reason not in ('spam', 'abuse', 'other') then
    raise exception 'invalid_report_reason' using errcode = 'P0001';
  end if;
  if p_details is not null and pg_catalog.char_length(p_details) > 1000 then
    raise exception 'report_details_too_long' using errcode = 'P0001';
  end if;

  if p_invite_id is not null then
    select case when i.sender_id = v_user then i.recipient_id else i.sender_id end
      into v_other
    from public.dialogue_invites i
    where i.id = p_invite_id and (i.sender_id = v_user or i.recipient_id = v_user);
  elsif p_dialogue_id is not null then
    select case when d.sender_id = v_user then d.recipient_id else d.sender_id end
      into v_other
    from public.dialogues d
    where d.id = p_dialogue_id and (d.sender_id = v_user or d.recipient_id = v_user);
  else
    raise exception 'report_context_required' using errcode = 'P0001';
  end if;

  if v_other is null or v_other <> p_reported_user_id then
    raise exception 'report_context_not_allowed' using errcode = 'P0001';
  end if;

  insert into public.dialogue_reports(
    reporter_id, reported_user_id, invite_id, dialogue_id, reason, details
  ) values (
    v_user, p_reported_user_id, p_invite_id, p_dialogue_id,
    p_reason, nullif(pg_catalog.btrim(coalesce(p_details, '')), '')
  ) returning id into v_report_id;
  return v_report_id;
end;
$$;

-- Restrict function execution to authenticated users. The functions validate
-- auth.uid() themselves and do not expose or require service_role credentials.
revoke all on function public.require_confirmed_dialogue_account() from public, anon, authenticated;
revoke all on function public.create_dialogue_invite(uuid, text) from public, anon;
revoke all on function public.respond_dialogue_invite(uuid, boolean) from public, anon;
revoke all on function public.send_dialogue_message(uuid, text) from public, anon;
revoke all on function public.request_dialogue_extension(uuid) from public, anon;
revoke all on function public.end_dialogue(uuid) from public, anon;
revoke all on function public.refresh_dialogue_status() from public, anon;
revoke all on function public.set_dialogue_invites_enabled(boolean) from public, anon;
revoke all on function public.block_dialogue_user(uuid) from public, anon;
revoke all on function public.unblock_dialogue_user(uuid) from public, anon;
revoke all on function public.report_dialogue_user(uuid, text, uuid, uuid, text) from public, anon;

grant execute on function public.create_dialogue_invite(uuid, text) to authenticated;
grant execute on function public.respond_dialogue_invite(uuid, boolean) to authenticated;
grant execute on function public.send_dialogue_message(uuid, text) to authenticated;
grant execute on function public.request_dialogue_extension(uuid) to authenticated;
grant execute on function public.end_dialogue(uuid) to authenticated;
grant execute on function public.refresh_dialogue_status() to authenticated;
grant execute on function public.set_dialogue_invites_enabled(boolean) to authenticated;
grant execute on function public.block_dialogue_user(uuid) to authenticated;
grant execute on function public.unblock_dialogue_user(uuid) to authenticated;
grant execute on function public.report_dialogue_user(uuid, text, uuid, uuid, text) to authenticated;

commit;
