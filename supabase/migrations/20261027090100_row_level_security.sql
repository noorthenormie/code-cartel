-- =============================================================================
-- Synapse GTB / Vital_Shield AI
-- 0002 - Row Level Security
--
-- Access model (MVP):
--   * authenticated staff users can read/write the application tables
--   * a user can only insert/update their own profile row
--   * anonymous users have no table access
--   * serverless API functions must use SUPABASE_SERVICE_ROLE_KEY (RLS bypass)
--
-- This matches the current UI, which has no per-role restrictions beyond the
-- route the user logs into. Tighten these policies before a real deployment.
-- =============================================================================

alter table public.users             enable row level security;
alter table public.units             enable row level security;
alter table public.patients          enable row level security;
alter table public.ot_blocks         enable row level security;
alter table public.instructions      enable row level security;
alter table public.administered      enable row level security;
alter table public.complaints        enable row level security;
alter table public.reports           enable row level security;
alter table public.risk_predictions  enable row level security;
alter table public.patient_reminders enable row level security;
alter table public.notifications     enable row level security;

-- -----------------------------------------------------------------------------
-- users
-- Reads are open to authenticated users so the ICU dashboard can list nurses
-- and joins such as users!doctor_id(name) work.
-- -----------------------------------------------------------------------------
drop policy if exists "authenticated can read users" on public.users;
create policy "authenticated can read users"
  on public.users
  for select
  to authenticated
  using (true);

drop policy if exists "users can insert their own profile" on public.users;
create policy "users can insert their own profile"
  on public.users
  for insert
  to authenticated
  with check (id = auth.uid());

drop policy if exists "users can update their own profile" on public.users;
create policy "users can update their own profile"
  on public.users
  for update
  to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

-- -----------------------------------------------------------------------------
-- Application tables
-- -----------------------------------------------------------------------------
drop policy if exists "authenticated can manage units" on public.units;
create policy "authenticated can manage units"
  on public.units for all to authenticated
  using (true) with check (true);

drop policy if exists "authenticated can manage patients" on public.patients;
create policy "authenticated can manage patients"
  on public.patients for all to authenticated
  using (true) with check (true);

drop policy if exists "authenticated can manage ot_blocks" on public.ot_blocks;
create policy "authenticated can manage ot_blocks"
  on public.ot_blocks for all to authenticated
  using (true) with check (true);

drop policy if exists "authenticated can manage instructions" on public.instructions;
create policy "authenticated can manage instructions"
  on public.instructions for all to authenticated
  using (true) with check (true);

drop policy if exists "authenticated can manage administered" on public.administered;
create policy "authenticated can manage administered"
  on public.administered for all to authenticated
  using (true) with check (true);

drop policy if exists "authenticated can manage complaints" on public.complaints;
create policy "authenticated can manage complaints"
  on public.complaints for all to authenticated
  using (true) with check (true);

drop policy if exists "authenticated can manage reports" on public.reports;
create policy "authenticated can manage reports"
  on public.reports for all to authenticated
  using (true) with check (true);

drop policy if exists "authenticated can manage risk_predictions" on public.risk_predictions;
create policy "authenticated can manage risk_predictions"
  on public.risk_predictions for all to authenticated
  using (true) with check (true);

drop policy if exists "authenticated can manage patient_reminders" on public.patient_reminders;
create policy "authenticated can manage patient_reminders"
  on public.patient_reminders for all to authenticated
  using (true) with check (true);

drop policy if exists "authenticated can manage notifications" on public.notifications;
create policy "authenticated can manage notifications"
  on public.notifications for all to authenticated
  using (true) with check (true);

-- -----------------------------------------------------------------------------
-- Storage: private "sessions" bucket
-- The browser uploads/downloads as a logged-in user. The Python backend and
-- the serverless API should use the service role key so they bypass RLS.
-- -----------------------------------------------------------------------------
drop policy if exists "sessions read for authenticated" on storage.objects;
create policy "sessions read for authenticated"
  on storage.objects
  for select
  to authenticated
  using (bucket_id = 'sessions');

drop policy if exists "sessions insert for authenticated" on storage.objects;
create policy "sessions insert for authenticated"
  on storage.objects
  for insert
  to authenticated
  with check (bucket_id = 'sessions');

drop policy if exists "sessions update for authenticated" on storage.objects;
create policy "sessions update for authenticated"
  on storage.objects
  for update
  to authenticated
  using (bucket_id = 'sessions')
  with check (bucket_id = 'sessions');

drop policy if exists "sessions delete for authenticated" on storage.objects;
create policy "sessions delete for authenticated"
  on storage.objects
  for delete
  to authenticated
  using (bucket_id = 'sessions');
