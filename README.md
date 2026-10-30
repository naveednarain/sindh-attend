# SindhAttend

A responsive attendance workspace for University of Sindh, Jamshoro. Built with Next.js, React, TypeScript, and Supabase; deployable to Vercel.

## Included

- Student, teacher, and administrator dashboards; mobile navigation; sample-only role previews.
- University email registration (`rollnumber@usindh.edu.pk`), email/roll matching, unique roll numbers, administrator verification.
- Departments, courses, approved-student enrollments, timetable sessions, teacher/section/room conflict checks.
- Attendance opens at the scheduled start and closes exactly 24 hours later. Database checks prevent early or late writes, duplicate students, partial rosters, and unauthorized teacher access.
- Present and late count as attended; excused records do not enter the denominator. Cancelled and unsubmitted sessions do not count. Threshold defaults to a configurable 75%; this is a product default, not a claim about university policy.
- Dated logs, CSV exports with spreadsheet formula escaping, recovery calculator, correction requests, and audited administrator decisions.
- Database-enforced 30-minute session inactivity and 8-hour absolute expiry. Signed-out sessions lose data access. RLS protects all public tables. Privileged functions live in the private schema and explicitly authorize each operation.

## Run

Use Node.js 24. Copy `.env.example` to `.env.local`, then set the Supabase project URL and publishable key.

```text
npm ci
npm run dev
npm run typecheck
npm test
npm run build
```

Only publishable credentials belong in `NEXT_PUBLIC_*`. `.env.local` is ignored by Git.

## Supabase project

Project reference: `mfikbalqckbzqqsuexxf`, organization NAVEED, Singapore region. Migrations in `supabase/migrations` were applied through the connected Supabase service. The database contains departments only; previews do not insert sample students into the live database.

`tests/database-security.sql` creates temporary fixture accounts and records inside a transaction, tests authorization/time/session boundaries, then rolls everything back. Use an administrative SQL connection to execute it. `npm test` checks the display-window boundaries and recovery calculator.

## Finish authentication configuration

1. Keep email confirmation enabled. Set a minimum password length of 12 in Supabase Auth. Turn off anonymous sign-ins and unused providers.
2. Set Site URL to the final HTTPS deployment origin. Allow exactly that origin's `/auth/callback` and `/auth/callback?next=/reset-password` redirect destinations, plus localhost during development. Avoid wildcard production redirects.
3. Configure Resend custom SMTP in Supabase Auth: host `smtp.resend.com`, port `465`, username `resend`, password the Resend API key. Sender must be an address on a domain verified in the user's Resend account. The sender domain does not have to be `usindh.edu.pk`; do not claim university-domain sender ownership without DNS access.
4. Keep confirmation and recovery tokens short lived, configure auth rate limits, and enable CAPTCHA for public signup/recovery before a broad rollout. Supabase Auth controls recovery-token issuance and redemption. The app always gives a neutral recovery response.
5. Provision the requested staff identities with `node scripts/provision-staff.mjs` in a trusted environment containing `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY`. The script uses trusted app metadata, leaves emails unconfirmed, and generates passwords it never prints. `admin@usindh.edu.pk` and `teacher@usindh.edu.pk` are reserved from public signup. Access is established through mailbox recovery after delivery is configured. Do not grant students staff metadata.

Resend setup reference: https://resend.com/docs/send-with-supabase-smtp

## Publishing

Keep the GitHub repository private. Connect the repository to the Vercel project `sindh-attend`. Store production Supabase URL and publishable key as Vercel environment variables. Use a separate development database for preview deployments; this project deliberately does not expose production configuration to previews. No service-role key is required by the running application.

## Deployment and verification limits

Supabase security rules can be verified without a real mailbox. Real signup, confirmation, recovery email delivery, and staff login must be tested after SMTP, redirect URLs, and staff provisioning are complete. Do not treat sample previews as a successful live login test.

The dashboard insights and recovery calculator are deterministic and labeled as such. The read-only Campus assistant includes a Vercel AI Gateway integration. It is disabled by default: set `AI_ENABLED=true` and choose a current `AI_GATEWAY_MODEL` after configuring a budget. Vercel OIDC authenticates production requests; local development needs a server-only `AI_GATEWAY_API_KEY`. Only the question, viewer role, and authorized course information are sent; names, emails, roll numbers, and attendance logs are excluded. RLS and database quotas enforce approved access, at most 10 requests per user per day, and a 15-second cooldown. Live provider responses have not been tested while disabled. Facial recognition and location tracking are not included.

Future institutional work: verified staff provisioning UI, official student roster import, department-scoped staff administration, term rollover, bulk timetable scheduling, notification delivery, and retention policies. This is an independent application, not an official university integration.
