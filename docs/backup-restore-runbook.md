# ISA LC OS — Backup & Restore Runbook (TASK 020)

Supabase project: `ftnmiaswdiynbutschad` (Tommy LC + all tenants).
Single database, multi-tenant (center_id + RLS). One backup covers ALL centers.

## Backup strategy

- **Primary — Supabase Pro daily backups.** Automatic, 7-day retention.
  Dashboard → Database → Backups.
- **Optional — PITR add-on.** Minute-level point-in-time recovery. Add when the
  cost of losing up-to-a-day of data becomes unacceptable (more paying centers).
- **Optional — off-site copy.** Periodic `supabase db dump` to external storage,
  so a Supabase-account issue never means total loss.

## Where backups live
Dashboard → **Database → Backups** (daily list) / **Point in Time** (if PITR on).

## Restore procedure

> ⚠️ A project restore is **whole-project and destructive** to the current state
> (all centers). Never "test" a restore on production. Restore into a scratch
> project / branch first, verify, then decide.

1. **Assess** — what/when was lost. Pick a backup timestamp BEFORE the incident.
2. **Safe verify** — create a new temporary Supabase project (or branch) and
   restore the chosen backup there. Confirm the data is intact.
3. **Decide** — if production must be rolled back, restore the daily backup /
   PITR timestamp on the production project. Announce downtime first.
4. **Post-restore checks** — run the isolation + smoke checks:
   - `select count(*) from centers;` (expected tenants present)
   - anon REST: `center_branding` public, `students`/`payments` closed
   - admin + one student login works
   - `get_center_theme('tommy.lcos.uz')` → Tommy

## DR drill (quarterly)
Restore the latest daily backup into a throwaway project, confirm row counts and
a login, then delete the throwaway project. Log the date + result here.

| Date | Backup used | Result |
|------|-------------|--------|
|      |             |        |

## Off-site export (optional, manual)
`supabase db dump` with the DB connection string (password kept locally, never in
git). Store the encrypted dump off-site. Do NOT commit dumps or passwords.

## Definition of Done (TASK 020)
- [ ] Project on Pro; daily backups visible in Dashboard
- [ ] Restore runbook reviewed (this file)
- [ ] One DR drill completed (restore into scratch project verified)
