---
id: daily-health
scope: project
runtime: desktop
cadence: "0 12 * * *"
title: "Vinarium health (daily at noon)"
---

Daily production health pass for Vinarium (repository `/Users/thibaut/Code/vinarium`, GCP project
`vinarium-polyforms`, region `europe-west3`, backend Cloud Function gen 2 `vinarium-server`,
request logs under `resource.type="cloud_run_revision"`). Analyse the last 24 hours of costs,
performance and monitoring, fix what is broken in code, push to main, watch CI. Report in the
person's language.

Error logs are out of scope: every `warn` and `error` goes to Sentry and to the `sentry-autofix`
routine.

Read the project's `CLAUDE.md` and the stack rules first and follow them. Work inline, never a
subagent. Other sessions may be editing the checkout: work in a worktree, or commit only your
files with an explicit pathspec; never stash, reset, switch branches, amend or force-push.

## 0. Preconditions
- Every `gcloud` / `bq` command is prefixed with `CLOUDSDK_CONFIG=$HOME/.config/claude-observer/gcloud`,
  the read-only observer account's own configuration. Check it with `gcloud auth
  print-access-token`. If it fails, never fall back to the person's login and never run `gcloud
  auth login`: do the steps that need no GCP and put the failure at the top of the report.
- The observer account only reads. Never write to GCP with it.
- `git pull --ff-only` if the tree allows it; otherwise work on what is there and say so.

## 1. Costs
- Billing export: `bq query --project_id=vinarium-polyforms --use_legacy_sql=false` on
  `vinarium-prod.billing_export.gcp_billing_export_v1_01B9B2_D51D23_1EF14D`, filtered on `project.id = "vinarium-polyforms"`, cost plus credits per day
  (`Europe/Paris`) and per service and SKU for the last 8 days. The export lags hours: yesterday
  may be partial, say so.
- Flag any service above twice its 7-day daily average, any AI API above `3 euros` a
  day, any new SKU. For Gemini, the grounded-search SKU is the expensive one; trace a spike through
  the structured usage logs grouped by step and hour; `httpRequest.userAgent` and `remoteIp` on the
  API route say whether one device caused it.
- A prepaid AI account answering 402 is critical: report it first, only the person can top up.
- Never read or print a key or a secret.

## 2. Performance
- From the API request logs of the last 24 h: p50, p95, p99 latency, 5xx rate, slowest hours.
  Cloud Monitoring: request latencies, instance count, startup latencies, memory. Compare with
  the previous day. Flag p95 above 2 s not explained by cold starts, a regression above 50 %,
  memory near the limit. Cold starts are a figure, never an action item: scaling to zero is the
  rule.
- Per operation, from the `operation served` log lines (rule 09-backend, Observability): count,
  p50, p95 and median reads of each GraphQL operation over 48 h. Name the slowest operations and
  say whether reads explain them; an operation above a hundred reads or a second at p50 is a
  read model candidate, proposed in "To decide", never built by the routine.
- Firestore usage when a cost or latency spike points there. Production data may be read to
  explain a spike; never copy personal data into the report.

## 3. Monitoring
- CI: `gh run list --repo moifort/vinarium --limit 30 --json databaseId,name,headSha,status,conclusion,createdAt`:
  any failed run on main in 24 h, Deploy first, including its migrations step.
- Cloud Scheduler: `gcloud scheduler jobs list --project=vinarium-polyforms --location=europe-west3`,
  state and last attempt of each job; a paused or failed job is a finding.
- A job answering 200 is not a job doing its work. For each pass that keeps shared documents
  fresh (release watches, catalogues), read the age of what it refreshes (`checkedAt` and the
  like, with a `select` on that field only) and compare it with the pass's cadence and daily cap:
  a backlog older than the cadence, or nothing refreshed for days while documents are due, is a
  finding; documents not due yet because of a long cadence are a figure, said in plain words,
  since that is what readers see as "nothing new".
- The app configuration endpoint on the production host answers 200.
- App Store and TestFlight are out of scope.

## 4. Fix
For each real problem with a clear cause in code: fix it following the rules, verify (typecheck,
the three test families separately, linter, schema check if the schema changed, an app build for
app changes), commit without asking (conventional commits, English, explicit pathspec,
`Co-Authored-By` trailer), push directly to main (authorised for this routine), watch every CI
run for the commit until green, fix forward on failure. Never touch the changelogs, never deploy or
terraform from the machine, never run migrations by hand.

Only propose, never apply: anything that changes what users see or can do, any infrastructure,
Terraform or secret change, anything with an unclear cause, and anything that would raise paid API
calls (state its cost).

## 4b. The other routines
List the last run of every other routine of this account (Sentry triage, upgrades,
deprecations). One that missed two cadences is a finding at the top of the report.

## 5. Report (short)
One-line verdict first (all fine / fixed / action needed from you). Then Costs (yesterday's total
and per service versus the 7-day average), Performance (p50, p95, 5xx, instances), Monitoring
(CI, Deploy, scheduler). Then "Fixed" (hashes, CI result per workflow) and "To decide".
