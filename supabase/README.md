# Supabase setup

This folder contains the **Supabase/Postgres** schema for the application. It is
separate from `04_end_to_end_icu_event_temporal_pipeline.sql`, which is
BigQuery Standard SQL for the MIMIC-IV Chronos pipeline and must not be run in
Supabase.

## Files

| File | Purpose |
|---|---|
| `migrations/20261027090000_initial_schema.sql` | Tables, indexes, triggers, auth-profile trigger, `sessions` storage bucket |
| `migrations/20261027090100_row_level_security.sql` | Enables RLS and creates app/storage policies |
| `migrations/20261027090200_realtime.sql` | Adds tables to the `supabase_realtime` publication |
| `seed.sql` | Optional demo units, patients, orders, reports, predictions, reminders, notifications |

## Apply to a hosted Supabase project

### Option A — Supabase CLI (recommended)

```bash
# If this is the first time using the CLI in this repo and config.toml is
# missing, run `supabase init` first.
supabase link --project-ref <your-project-ref>
supabase db push
```

`db push` applies the three files in `migrations/` in filename order.

Then, if you want demo data:

```bash
psql "$DATABASE_URL" -f supabase/seed.sql
```

`DATABASE_URL` is under **Project Settings → Database → Connection string**.
You can also paste `seed.sql` into the Supabase SQL editor.

### Option B — SQL editor

Run these files, in order:

1. `migrations/20261027090000_initial_schema.sql`
2. `migrations/20261027090100_row_level_security.sql`
3. `migrations/20261027090200_realtime.sql`
4. `seed.sql` (optional)

## Auth setup

- `public.users.id` references `auth.users.id`, and a trigger creates the
  profile row from signup metadata (`name`, `role`, `assigned_doctor_name`,
  `assigned_icu_ward`).
- The app auto-provisions the prefilled demo accounts on first login
  (`doc@synapse.med`, `nurse@synapse.med`, `patient@synapse.med`).
- For that flow, disable **Authentication → Providers → Email → Confirm email**
  in the Supabase dashboard, or confirm the emails manually. If confirmation is
  enabled, the auth trigger still creates the profile, but the browser will not
  have a session until the link is clicked.
- After creating users, they appear in `public.users` automatically. Existing
  auth users are backfilled by the first migration.

## Server-side API key

The browser uses the anon key. RLS policies only allow `authenticated`, so the
serverless functions under `api/` must use the service role key:

```env
SUPABASE_URL=https://<project>.supabase.co
SUPABASE_SERVICE_ROLE_KEY=<service-role-key>
```

`api/_supabase.js` prefers `SUPABASE_SERVICE_ROLE_KEY` and falls back to the
anon key. Without the service role key, `POST /api/start`, `/api/tick`,
`/api/stop`, `/api/tamper` and the storage uploads will be blocked by RLS.

The Python backend (`backend/.env`) should also use the service role key for
Storage uploads:

```env
SUPABASE_URL=https://<project>.supabase.co
SUPABASE_KEY=<service-role-key>
```

## Notes

- The `sessions` Storage bucket is created private. Policies allow authenticated
  users to read/write it; server-side code with the service role bypasses RLS.
- The RLS policies are intentionally broad for the current UI: any authenticated
  user can manage clinical tables, and users can only edit their own profile.
  Tighten these before production if role separation is required.
- `complaints.nature` and `complaints.complaint_text` are kept in sync by a
  trigger because different pages write/read different column names.
  `status='active'` is normalized to `'open'` so nurse/ICU queues see it.
- `ot_blocks.prev_hash` is `text`, not a hash, because the serverless API stores
  `sid=...|evt=frame|seq=...` metadata there. `curr_hash` holds the SHA-256
  chain hash.
