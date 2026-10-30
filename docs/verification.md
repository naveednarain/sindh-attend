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
