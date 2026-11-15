-- Run after dialogues_migration.sql to confirm tables, RLS and RPCs exist.
select
  tablename,
  rowsecurity as rls_enabled
from pg_catalog.pg_tables
where schemaname = 'public'
  and tablename in (
    'dialogue_invites',
    'dialogues',
    'dialogue_messages',
    'dialogue_blocks',
    'dialogue_reports'
  )
order by tablename;

select
  p.proname as function_name,
  has_function_privilege('authenticated', p.oid, 'EXECUTE') as authenticated_can_execute
from pg_catalog.pg_proc p
join pg_catalog.pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in (
    'create_dialogue_invite',
    'respond_dialogue_invite',
    'send_dialogue_message',
    'request_dialogue_extension',
    'end_dialogue',
    'refresh_dialogue_status',
    'set_dialogue_invites_enabled',
    'block_dialogue_user',
    'unblock_dialogue_user',
    'report_dialogue_user'
  )
order by function_name;

select column_name, data_type, is_nullable, column_default
from information_schema.columns
where table_schema = 'public'
  and table_name = 'profiles'
  and column_name = 'allow_dialogue_invites';
