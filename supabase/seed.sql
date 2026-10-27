-- =============================================================================
-- Synapse GTB / Vital_Shield AI
-- Optional demo seed data
--
-- This is NOT a migration. `supabase db push` will not run it automatically.
-- Run it once with the Supabase SQL editor, or:
--   psql "$DATABASE_URL" -f supabase/seed.sql
--
-- Every block is guarded so re-running is safe and so it does not overwrite
-- real clinical data that already exists.
-- =============================================================================

begin;

-- -----------------------------------------------------------------------------
-- Units
-- -----------------------------------------------------------------------------
insert into public.units (unit_id, unit_type)
values
  (1, 'ICU-A (Critical Care)'),
  (2, 'ICU-B (Post-Op)'),
  (3, 'ICU-C (Neonatal)'),
  (4, 'ICU-D (Neuro)')
on conflict do nothing;

select setval(
  pg_get_serial_sequence('public.units', 'unit_id'),
  coalesce((select max(unit_id) from public.units), 1),
  true
);

-- -----------------------------------------------------------------------------
-- Patients (IDs match frontend/src/data/mockChronosData.js)
-- -----------------------------------------------------------------------------
insert into public.patients
  (id, name, age, bed, unit_id, admission_type, admission_time, diagnosis, status)
values
  ('P-1042', 'R. Sharma',    67,  4, 1, 'ICU', now() - interval '2 days',  'Post-CABG Recovery',      'critical'),
  ('P-2718', 'S. Patel',     54,  7, 1, 'ICU', now() - interval '1 day',   'Pneumonia / ARDS',        'critical'),
  ('P-3141', 'A. Gupta',     73,  2, 2, 'ICU', now() - interval '3 days',  'Acute Kidney Injury',     'critical'),
  ('P-1618', 'M. Reddy',     45, 11, 1, 'ICU', now() - interval '8 hours', 'Septic Shock',            'critical'),
  ('P-2236', 'R. Iyer',      61,  9, 2, 'ICU', now() - interval '4 days',  'Post-Valve Replacement',  'observing'),
  ('P-5050', 'L. Nair',      58,  3, 1, 'ICU', now() - interval '12 hours', 'GI Bleed',               'observing'),
  ('P-7777', 'D. Verma',     82,  1, 1, 'ICU', now() - interval '6 days',  'CHF Exacerbation',        'observing'),
  ('P-4242', 'T. Singh',     39,  6, 2, 'ICU', now() - interval '1 day',   'Trauma - MVC',            'stable'),
  ('P-9090', 'E. Joshi',     71,  8, 2, 'ICU', now() - interval '2 days',  'Elective Hip Replacement','stable'),
  ('P-6180', 'C. Deshmukh',  50, 10, 1, 'ICU', now() - interval '5 hours', 'Diabetic Ketoacidosis',  'stable')
on conflict (id) do update
  set name           = excluded.name,
      age            = excluded.age,
      bed            = excluded.bed,
      unit_id        = excluded.unit_id,
      admission_type = excluded.admission_type,
      admission_time = excluded.admission_time,
      diagnosis      = excluded.diagnosis,
      status         = excluded.status;

-- -----------------------------------------------------------------------------
-- Demo instructions (only when the table is empty)
-- nurse_id is null = shown in the patient portal.
-- -----------------------------------------------------------------------------
insert into public.instructions (doctor_id, patient_id, nurse_id, text, status, created_at)
select v.doctor_id, v.patient_id, v.nurse_id, v.text, v.status, v.created_at
from (values
  (null::uuid, 'P-1042', null::uuid,
   'Strict bed rest for 24 hours. Keep the surgical site dry and report any chest pain immediately.',
   'pending', now() - interval '2 hours'),
  (null::uuid, 'P-2718', null::uuid,
   'Monitor urine output hourly. Notify the on-call physician if it drops below 30 ml/hour.',
   'pending', now() - interval '90 minutes'),
  (null::uuid, 'P-3141', null::uuid,
   'Repeat renal panel in 12 hours. Maintain fluid balance chart.',
   'completed', now() - interval '1 day')
) as v(doctor_id, patient_id, nurse_id, text, status, created_at)
where not exists (select 1 from public.instructions);

-- -----------------------------------------------------------------------------
-- Demo medication records (only when the table is empty)
-- -----------------------------------------------------------------------------
insert into public.administered
  (doctor_id, patient_id, nurse_id, medicine, dosage, route, is_administered, administered_at, created_at)
select v.doctor_id, v.patient_id, v.nurse_id, v.medicine, v.dosage, v.route,
       v.is_administered, v.administered_at, v.created_at
from (values
  (null::uuid, 'P-1042', null::uuid, 'Paracetamol', '650 mg', 'PO', true,
   now() - interval '3 hours', now() - interval '4 hours'),
  (null::uuid, 'P-1042', null::uuid, 'Insulin', '4 units', 'SC', false,
   null::timestamptz, now() - interval '1 hour'),
  (null::uuid, 'P-2718', null::uuid, 'Norepinephrine', '0.05 mcg/kg/min', 'IV', true,
   now() - interval '1 hour', now() - interval '2 hours')
) as v(doctor_id, patient_id, nurse_id, medicine, dosage, route,
       is_administered, administered_at, created_at)
where not exists (select 1 from public.administered);

-- -----------------------------------------------------------------------------
-- Demo complaints (only when the table is empty)
-- The trigger copies nature -> complaint_text and normalizes 'active' -> 'open'.
-- -----------------------------------------------------------------------------
insert into public.complaints
  (patient_id, lodged_by, nature, status, resolution_notes, resolved_at, created_at)
select v.patient_id, v.lodged_by, v.nature, v.status, v.resolution_notes,
       v.resolved_at, v.created_at
from (values
  ('P-1042', 'patient', 'Nurse Request: Pain management review after surgery.', 'open',
   null::text, null::timestamptz, now() - interval '45 minutes'),
  ('P-2718', 'patient', 'Authority Escalation: Requesting an update on the treatment plan.', 'open',
   null::text, null::timestamptz, now() - interval '20 minutes'),
  ('P-3141', 'patient', 'Nurse Request: Assistance with mobility.', 'resolved',
   'Nurse assisted the patient and documented the episode.', now() - interval '1 day',
   now() - interval '2 days')
) as v(patient_id, lodged_by, nature, status, resolution_notes, resolved_at, created_at)
where not exists (select 1 from public.complaints);

-- -----------------------------------------------------------------------------
-- Demo reports (only when the table is empty)
-- -----------------------------------------------------------------------------
insert into public.reports (patient_id, report_type, status, content, created_at)
select v.patient_id, v.report_type, v.status, v.content, v.created_at
from (values
  ('P-1042', 'Post-Op Summary', 'verified',
   'CABG completed without complications. Patient shifted to ICU for monitoring.',
   now() - interval '1 day'),
  ('P-2718', 'Chest X-Ray', 'verified',
   'Bilateral infiltrates consistent with ARDS. Continue lung-protective ventilation.',
   now() - interval '5 hours'),
  ('P-3141', 'Renal Panel', 'verified',
   'Creatinine elevated. Nephrology review requested.',
   now() - interval '3 hours')
) as v(patient_id, report_type, status, content, created_at)
where not exists (select 1 from public.reports);

-- -----------------------------------------------------------------------------
-- Demo Chronos predictions (only when the table is empty)
-- -----------------------------------------------------------------------------
insert into public.risk_predictions
  (patient_id, event, risk_percentage, timeline, shap_1, shap_2, shap_3, model, created_at)
select v.patient_id, v.event, v.risk_percentage, v.timeline,
       v.shap_1, v.shap_2, v.shap_3, v.model, v.created_at
from (values
  ('P-1042', 'deterioration', 78.50, '12h',
   'Lactate elevated +4.2%', 'MAP below target +3.1%', 'Heart rate rising +1.8%',
   'XGBoost', now() - interval '2 hours'),
  ('P-2718', 'sepsis', 85.20, '12h',
   'Respiratory rate high +5.0%', 'SpO2 low +3.4%', 'Lactate elevated +2.7%',
   'XGBoost', now() - interval '1 hour'),
  ('P-3141', 'aki', 64.00, '12h',
   'Creatinine elevated +6.1%', 'Urine output low +4.8%', 'BUN elevated +2.2%',
   'XGBoost', now() - interval '3 hours')
) as v(patient_id, event, risk_percentage, timeline, shap_1, shap_2, shap_3, model, created_at)
where not exists (select 1 from public.risk_predictions);

-- -----------------------------------------------------------------------------
-- Demo reminders (only when the table is empty)
-- -----------------------------------------------------------------------------
insert into public.patient_reminders (patient_id, title, reminder_date, created_at)
select v.patient_id, v.title, v.reminder_date, v.created_at
from (values
  ('P-1042', 'Cardiology follow-up', now() + interval '14 days', now() - interval '1 day'),
  ('P-1042', 'Surgical wound review', now() + interval '7 days', now() - interval '1 day'),
  ('P-2718', 'Pulmonology review', now() + interval '21 days', now() - interval '2 days')
) as v(patient_id, title, reminder_date, created_at)
where not exists (select 1 from public.patient_reminders);

-- -----------------------------------------------------------------------------
-- Demo notifications (only when the table is empty)
-- -----------------------------------------------------------------------------
insert into public.notifications (patient_id, risk_score, type, message, is_read, created_at)
select v.patient_id, v.risk_score, v.type, v.message, v.is_read, v.created_at
from (values
  ('P-1042', 78, 'ringing', 'ALERT: SOFA score rose to 6. Patient deteriorating rapidly.',
   false, now() - interval '30 minutes'),
  ('P-2718', 85, 'ringing', 'CRITICAL: Shock index elevated. Ensure adequate perfusion.',
   false, now() - interval '15 minutes'),
  ('P-3141', 64, 'silent', 'WARNING: Creatinine increased. Monitor renal function closely.',
   true, now() - interval '4 hours')
) as v(patient_id, risk_score, type, message, is_read, created_at)
where not exists (select 1 from public.notifications);

-- -----------------------------------------------------------------------------
-- Demo Sentinel block so the patient portal has a secured OT record
-- -----------------------------------------------------------------------------
insert into public.ot_blocks
  (patient_id, bp, spo2, heart_rate, prev_hash, curr_hash, recorded_at, created_at)
select 'P-1042', 122, 97.5, 84, null,
       repeat('a', 64), now() - interval '1 day', now() - interval '1 day'
where not exists (select 1 from public.ot_blocks);

commit;
