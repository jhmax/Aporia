-- Read-only verification for Between the Lines. This query does not alter data or policies.
select
  'RLS' as category,
  c.relname as object_name,
  'enabled=' || c.relrowsecurity::text as detail
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relname in (
    'profiles', 'reflections', 'reactions', 'saved_reflections', 'reports'
  )
union all
select
  'POLICY' as category,
  tablename as object_name,
  policyname || ' | ' || cmd || ' | using=' || coalesce(qual, '-') ||
  ' | check=' || coalesce(with_check, '-') as detail
from pg_policies
where schemaname = 'public'
  and tablename in (
    'profiles', 'reflections', 'reactions', 'saved_reflections', 'reports'
  )
union all
select
  'FUNCTION' as category,
  p.proname as object_name,
  pg_get_function_identity_arguments(p.oid) as detail
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname = 'get_reaction_counts'
order by category, object_name, detail;

-- v1.5 checks: required RPC functions and trigger names
select p.proname as function_name, pg_get_function_identity_arguments(p.oid) as arguments
from pg_proc p join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public' and p.proname in ('get_reaction_counts', 'has_published_today', 'stamp_reflection_created_at', 'reserve_daily_reflection_slot', 'prevent_self_reflection_reaction')
order by p.proname;

-- Confirm the private daily-slot table exists (read-only check).
select table_schema, table_name
from information_schema.tables
where table_schema = 'entrelinhas_private'
  and table_name = 'reflection_daily_slots';
