# Verification and release status

Verified on 30 October 2026.

- Production deployment: https://sindh-attend.vercel.app
- Vercel deployment ID: dpl_3ZWEEsDHCyBMcEbUCQDuR1GoSqCo (READY).
- Supabase project: mfikbalqckbzqqsuexxf (NAVEED organization).
- Current dependencies installed with exact versions and a committed lockfile; installation audit reported zero known vulnerabilities.
- Type checking and optimized production build passed.
- Three Node tests passed: attendance boundaries, recovery calculations, and CSV formula/quoting protection.
- Eleven database security scenarios passed, including early/late/exact-cutoff attendance, invalid rosters, unassigned teachers, student isolation and privilege escalation, idle and absolute expiry, identity restrictions, AI quota, and audit insertion. Fixtures were rolled back.
- Supabase security advisor returned no findings after all migrations.
- Browser checks: desktop login and teacher dashboard; roster completeness enables submission; mobile timetable and student progress at 390px; mobile navigation and no horizontal page overflow.
- Live deployed login and administrator verification preview rendered successfully. Screenshots contain sample records only.

## Not yet activated or verified

- GitHub: source is committed locally; the GitHub connection was requested but was not connected during this run. No remote repository was created or pushed.
- Resend: no Resend tool, key, or verified sender was available. The recovery flow is implemented with Supabase Auth, but Resend SMTP and real email delivery have not been configured or tested.
- Staff accounts: reserved addresses are protected from public signup. Neither account has been provisioned; run the trusted setup script with a securely supplied service credential after configuring email delivery.
- Supabase Auth production settings: configure final Site URL/callback allowlist, minimum password length, recovery expiry, CAPTCHA, and appropriate rate limits. These settings were not changed through SQL.
- AI: the read-only integration and database limits are implemented, but the provider is disabled until a model and budget are configured. No model request was sent.

An attempted temporary privileged staff-provisioning endpoint was rejected by automatic review because it lacked an in-function administrator check. It was not deployed. The repository instead provides a trusted local provisioning script; no provisioning endpoint exists.

This deployment is ready for UI review. Complete the authentication activation steps in README before onboarding real students.

## Interface refresh and registration diagnosis — 30 October 2026
- Replaced tiny typography with readable system fonts, blue/white surfaces, larger touch targets and roomier cards/forms.
- Added mobile bottom navigation and scroll-to-top when changing pages.
- Registration and recovery show actionable service/rate-limit errors without exposing account existence.
- Production build and existing 3 tests passed; desktop and 390px mobile previews inspected.
- Exact supplied university email passed database signup validation in a rolled-back transaction; no test account persisted.
- Public Auth settings return 200 and signup is enabled; real signup requests returned 504 in gateway logs.
- User reported SMTP port 458; Resend documentation requires 465. Sender onboarding@resend.dev only permits delivery to the Resend account owner's address; a verified domain sender is required for students.
- SMTP fix and end-to-end delivery remain unverified. Vercel publishing currently requires renewed team authorization (403).

## Subject registers and removal of previews — 30 October 2026
- Removed role preview entry points, role switching, and sample-data loading from the portal and authentication components.
- Added a separate date-column register per authorized subject with teacher, section, semester, dates/times, statuses, totals, percentages, date/subject filters, CSV and print.
- Pending and cancelled periods never display as absences; percentages exclude excused/unsubmitted/cancelled records.
- Registration now loads the pending-approval screen when Supabase returns a session; no automatic approval was added.
- Supabase Confirm email must be disabled by the owner to activate the requested registration-without-email flow. Available MCP tools cannot change Auth configuration.
- Latest authentication log: SMTP 550 recipient restriction from Resend's testing sender after port correction. Recovery to university recipients remains unavailable with that sender.
- Build and type checking passed. Synthetic render check confirmed three per-subject tables and expected 80% attendance. Mobile document width equals viewport width. Browser verified no role preview buttons at sign-in.
- Production Vercel release remains blocked by team authorization (403).
