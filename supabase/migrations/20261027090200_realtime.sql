-- =============================================================================
-- Synapse GTB / Vital_Shield AI
-- 0003 - Supabase Realtime
--
-- NurseDashboard, PatientPortal and NotificationCenter subscribe to changes on
-- these tables via supabase.channel(...).on('postgres_changes', ...).
-- =============================================================================

do $$
declare
  tbl text;
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    foreach tbl in array array[
      'public.notifications',
      'public.instructions',
      'public.administered',
      'public.complaints',
      'public.patient_reminders',
      'public.ot_blocks',
      'public.patients',
      'public.risk_predictions'
    ]
    loop
      begin
        execute format('alter publication supabase_realtime add table %s', tbl);
      exception
        when duplicate_object then
          null; -- table is already part of the publication
      end;
    end loop;
  end if;
end;
$$;

-- Send complete rows (not just the primary key) for update/delete payloads.
alter table public.notifications      replica identity full;
alter table public.instructions       replica identity full;
alter table public.administered       replica identity full;
alter table public.complaints         replica identity full;
alter table public.patient_reminders  replica identity full;
alter table public.ot_blocks          replica identity full;
alter table public.patients           replica identity full;
alter table public.risk_predictions   replica identity full;
