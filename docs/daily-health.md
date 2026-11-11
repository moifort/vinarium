# Daily production health pass

The runbook of the `vinarium-daily-health` scheduled task: once a day, analyse the last 24 hours
of costs, performance, user activity and monitoring in production, fix what is broken, push the
fixes to `main` and watch CI. This file is the whole task: the scheduled prompt only points here,
so any change to the routine is made in this file and committed.

The final report is written in **French**.

## Scope

|                 |                                                                             |
| --------------- | --------------------------------------------------------------------------- |
| Repository      | `/Users/thibaut/Code/vinarium`                                              |
| GCP project     | `vinarium-prod`, region `europe-west3`                                      |
| Backend         | Cloud Function gen2 `vinarium-server`, 512 MiB, 60 s timeout, scale-to-zero |
| Request logs    | `resource.type="cloud_run_revision"`                                        |
| Production host | https://vinarium-server-okw6e376wq-ey.a.run.app                             |
| Billing export  | `vinarium-prod.billing_export.gcp_billing_export_v1_01B9B2_D51D23_1EF14D`   |

**Error logs are out of scope.** Every `warn` / `error` is reported to Sentry and handled by the
separate 6-hourly `sentry-autofix-6h` routine. Never triage error logs or Sentry issues here.

**App Store / TestFlight is out of scope.**

## Ground rules

- Read [CLAUDE.md](../CLAUDE.md) first and follow it, with the playbook it links
  ([02-commits.md](../playbook/02-commits.md), [04-push-protocol.md](../playbook/04-push-protocol.md)):
  `bun` only, `bun run preflight` before commit and push, logging rules, API evolution rules.
- **Never touch any `CHANGELOG*.md`.**
- Work inline: never launch sub-agents.
- Other Claude sessions may be editing this checkout: commit only the files you changed, with an
  explicit pathspec. Never stash, reset, switch branches, amend or force-push. Recheck `git log`
  right before committing.
- The run is unattended: never ask clarifying questions, make reasonable choices and note them in
  the report. Take a write action only when this file asks for it; when in doubt, report.
- Never read or print API keys or secrets.
- Aggregate figures only: never names, emails, user ids or IP addresses in the report.

## 0. Preconditions

GCP access goes through read-only service accounts, each in its own gcloud configuration, so the
user's account is never touched. **Never fall back to the user's own gcloud login and never run
`gcloud auth login`.** These accounts only read: never try to write anything to GCP with them.

| Use                                                                        | Configuration                                                                                                                |
| -------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| Production reads (logs, Monitoring, Cloud Scheduler, Cloud Run, Firestore) | `CLOUDSDK_CONFIG=$HOME/.config/vinarium-observer/gcloud` (account `vinarium-observer@vinarium-prod.iam.gserviceaccount.com`) |
| Billing export (READER on the dataset, jobUser on `shiori-polyforms`)      | `CLOUDSDK_CONFIG=$HOME/.config/shiori-observer/gcloud`, queries run with `--project_id=shiori-polyforms`                     |

```bash
CLOUDSDK_CONFIG=$HOME/.config/vinarium-observer/gcloud gcloud auth print-access-token >/dev/null && echo ok
CLOUDSDK_CONFIG=$HOME/.config/shiori-observer/gcloud gcloud auth print-access-token >/dev/null && echo ok
git -C /Users/thibaut/Code/vinarium pull --ff-only
```

- If the vinarium observer directory is missing or the check fails, skip every step that needs it,
  do what remains (billing, CI, `/app-config`) and open the report with: « Le compte de lecture
  vinarium-observer n'existe pas ou ne répond pas : performances, activité et jobs planifiés non
  vérifiés », followed by the error.
- If `pull --ff-only` is refused, work on what is there and say so. Local commits ahead of
  `origin/main` belong to other sessions: mention them, never push them.

Scratch files (log dumps) go in the session's scratchpad directory, never in the repository:
set `SCRATCH` to that directory before running the commands below.

## 1. Costs

Cost plus credits per Paris day and per service (and SKU when something moves) over the last
8 days, filtered on `project.id = "vinarium-prod"`. The export lags several hours: check
`MAX(export_time)` and say when yesterday is partial.

```bash
export CLOUDSDK_CONFIG=$HOME/.config/shiori-observer/gcloud
T=vinarium-prod.billing_export.gcp_billing_export_v1_01B9B2_D51D23_1EF14D
bq query --project_id=shiori-polyforms --use_legacy_sql=false --format=prettyjson \
  "SELECT MAX(export_time) m FROM \`$T\` WHERE project.id='vinarium-prod'"
bq query --project_id=shiori-polyforms --use_legacy_sql=false --format=csv --max_rows=500 \
  "SELECT DATE(usage_start_time,'Europe/Paris') d, service.description s,
     ROUND(SUM(cost)+SUM(IFNULL((SELECT SUM(c.amount) FROM UNNEST(credits) c),0)),3) net,
     ROUND(SUM(cost),3) gross
   FROM \`$T\` WHERE project.id='vinarium-prod'
     AND DATE(usage_start_time,'Europe/Paris') >= DATE_SUB(CURRENT_DATE('Europe/Paris'), INTERVAL 8 DAY)
   GROUP BY d,s HAVING gross>0.001 ORDER BY s,d"
# SKUs first seen in the last 2 days
bq query --project_id=shiori-polyforms --use_legacy_sql=false --format=csv \
  "SELECT sku.description, service.description, MIN(DATE(usage_start_time,'Europe/Paris')) first
   FROM \`$T\` WHERE project.id='vinarium-prod'
     AND usage_start_time > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 60 DAY)
   GROUP BY 1,2 HAVING first >= DATE_SUB(CURRENT_DATE('Europe/Paris'), INTERVAL 2 DAY)"
```

Flag:

- any service whose yesterday cost is more than 2× its 7-day daily average;
- the Gemini API above €3 in a day;
- any SKU first seen in the last 2 days (give its cost).

Trace a Gemini spike in the request logs: step, hour, and `httpRequest.userAgent` / `remoteIp` on
`/graphql` to tell whether one device caused it.

**Gemini answering 402 "prepayment credits are depleted" is critical**: put it at the very top of
the report. Only the user can top up.

## 2. Performance

### Request logs

`/graphql` requests of the last 48 hours: p50 / p95 / p99 of `httpRequest.latency`, 5xx rate,
slowest hours, last 24 h against the 24 h before.

```bash
export CLOUDSDK_CONFIG=$HOME/.config/vinarium-observer/gcloud
gcloud logging read --project=vinarium-prod --freshness=2d \
  'resource.type="cloud_run_revision" AND httpRequest.requestUrl:"/graphql"' \
  --format=json --limit=50000 > "$SCRATCH/gql48.json"
jq -r '.[] | (.httpRequest.latency|rtrimstr("s")|tonumber)' "$SCRATCH/gql48.json" | sort -n |
  awk '{a[NR]=$1} END{print "n="NR, "p50="a[int(NR*.5+.5)], "p95="a[int(NR*.95+.5)], "p99="a[int(NR*.99+.5)]}'
```

Tell cold-start bursts from real slowness: list requests with their timestamps; a slow request
that is the first one after a long idle gap, followed by fast ones, is a cold start. If the server
logs one line per GraphQL operation, break latency and reads down by operation.

### Cloud Monitoring

Query the Monitoring REST API with the observer token, aggregated over the day (a raw
distribution point can carry no mean, so always align):

```bash
TOK=$(CLOUDSDK_CONFIG=$HOME/.config/vinarium-observer/gcloud gcloud auth print-access-token)
q() { curl -s -H "Authorization: Bearer $TOK" -G \
  "https://monitoring.googleapis.com/v3/projects/vinarium-prod/timeSeries" \
  --data-urlencode "filter=metric.type=\"run.googleapis.com/$1\" AND resource.labels.service_name=\"vinarium-server\"" \
  --data-urlencode "interval.startTime=$(date -u -v-1d +%Y-%m-%dT%H:%M:%SZ)" \
  --data-urlencode "interval.endTime=$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --data-urlencode "aggregation.alignmentPeriod=86400s" \
  --data-urlencode "aggregation.perSeriesAligner=$2" \
  --data-urlencode "aggregation.crossSeriesReducer=REDUCE_MAX" |
  jq -c '[.timeSeries[]?.points[]?.value]'; }
q request_latencies ALIGN_PERCENTILE_95            # ms
q container/startup_latencies ALIGN_PERCENTILE_99  # ms
q container/memory/utilizations ALIGN_PERCENTILE_99  # ratio of 512 MiB
q container/instance_count ALIGN_MAX
```

Flag: p95 above 2 s that cold starts do not explain, a regression above 50 %, memory p99 above
80 % of 512 MiB, requests near the 60 s timeout, or frequent cold starts.

**Scale-to-zero is a choice: never propose min instances.**

### Firestore

Look at Firestore usage only when a cost or latency spike points there. Production data may be
read (read-only) to explain it; never copy users' personal data into the report.

## 3. User activity

Aggregate figures only.

- **Users**: the admin metrics projection, Firestore document `admin-metrics/current`
  (`totalUsers`, `newUsers` this month, `premium.total`, `newPremium`, `refreshedAt`). Its
  `sessions.days` array carries GA4 sessions per day.
- **Per day over 8 days**: GraphQL requests, mutations (from per-operation logs if they exist),
  distinct devices (approximated by distinct `remoteIp`), app builds seen (first token of
  `userAgent`, `Vinarium/<build>`), 5xx count.
- **Content added** in the last 24 hours and 7 days: count aggregation on the `beverages`
  collection, field `createdAt`.
- Say plainly whether activity is rising, stable or falling, and whether a drop looks like an
  outage (5xx, failed jobs) or just usage. Bursts of hundreds of requests a minute apart from one
  build, often on a simulator's Darwin version, are automated runs (captures, e2e), not users:
  say so rather than counting them as activity.

```bash
export CLOUDSDK_CONFIG=$HOME/.config/vinarium-observer/gcloud
TOK=$(gcloud auth print-access-token)
FS='https://firestore.googleapis.com/v1/projects/vinarium-prod/databases/(default)/documents'
curl -s -H "Authorization: Bearer $TOK" "$FS/admin-metrics/current" | jq -c '.fields |
  {totalUsers, newUsers, newPremium, premium: .premium.mapValue.fields.total, refreshedAt,
   sessions: (.sessions.mapValue.fields.days.arrayValue.values // [] |
     map(.mapValue.fields | [.day.stringValue, .sessions.integerValue]) | .[-8:])}'
for d in 1 7; do since=$(date -u -v-${d}d +%Y-%m-%dT%H:%M:%SZ)
  curl -s -H "Authorization: Bearer $TOK" -H 'Content-Type: application/json' -X POST \
    "$FS:runAggregationQuery" -d "{\"structuredAggregationQuery\":{\"structuredQuery\":{
      \"from\":[{\"collectionId\":\"beverages\"}],
      \"where\":{\"fieldFilter\":{\"field\":{\"fieldPath\":\"createdAt\"},\"op\":\"GREATER_THAN_OR_EQUAL\",
      \"value\":{\"timestampValue\":\"$since\"}}}},\"aggregations\":[{\"alias\":\"n\",\"count\":{}}]}}" |
    jq -c "{days:$d, n: .[0].result.aggregateFields.n.integerValue}"
done

gcloud logging read --project=vinarium-prod --freshness=8d \
  'resource.type="cloud_run_revision" AND httpRequest.requestUrl:"/graphql"' \
  --format=json --limit=50000 > "$SCRATCH/gql8.json"
jq -r '.[] | [(.timestamp[0:10]), .httpRequest.remoteIp, (.httpRequest.userAgent|split(" ")[0]),
  (.httpRequest.status|tostring)] | @tsv' "$SCRATCH/gql8.json" |
  awk -F'\t' '{n[$1]++; ip[$1" "$2]=1; ua[$1" "$3]=1; if($4>=500) e[$1]++}
    END{for(d in n){c=0; for(k in ip) if(index(k,d)==1) c++; u="";
      for(k in ua) if(index(k,d)==1) u=u substr(k,12)" "; print d, n[d], c, e[d]+0, u}}' | sort
```

The Firestore URL holds parentheses: keep it single-quoted, or curl's output is not JSON.

## 4. Monitoring

### CI and Deploy

```bash
gh run list --repo moifort/vinarium --limit 30 \
  --json databaseId,name,headSha,headBranch,status,conclusion,createdAt \
  --jq '.[] | [.createdAt,.name,.headBranch,.status,.conclusion,.headSha[:7],.databaseId] | @tsv'
gh run view <deploy-run-id> --repo moifort/vinarium --json jobs \
  --jq '.jobs[].steps[] | select(.name|test("Terraform|migration";"i")) | [.name,.conclusion] | @tsv'
```

Report any failed run on `main` in the last 24 hours, the Deploy workflow above all: production
only ships through it. Check that the last Deploy succeeded, including its "Terraform init +
apply" and "Run Firestore migrations" steps.

### Cloud Scheduler

```bash
export CLOUDSDK_CONFIG=$HOME/.config/vinarium-observer/gcloud
gcloud scheduler jobs list --project=vinarium-prod --location=europe-west3 --format=json |
  jq -r '.[] | [(.name|split("/")[-1]), .schedule, .state, .lastAttemptTime, (.status.code//0), .httpTarget.uri] | @tsv'
gcloud logging read --project=vinarium-prod --freshness=8d \
  'resource.type="cloud_run_revision" AND httpRequest.userAgent:"Google-Cloud-Scheduler"' --format=json |
  jq -r '.[] | [.timestamp, .httpRequest.requestUrl, .httpRequest.status, .httpRequest.latency] | @tsv' | sort
```

For **each** job: schedule, state, last attempt time and status, then its runs over 8 days
(status and latency). Flag any non-200, any run near the 60 s timeout, or a missed run. Report
every job in a table, never as one summary line.

### `/app-config`

```bash
curl -s -o /dev/null -w "%{http_code} %{time_total}s\n" https://vinarium-server-okw6e376wq-ey.a.run.app/app-config
```

It must answer 200 (a few seconds is a cold start, not a failure).

## 5. Fix

For each real problem with a clear cause in the code:

- Fix it following [CLAUDE.md](../CLAUDE.md) and the playbook: domain layout, logger, no
  `console.*`, deprecate rather than remove GraphQL fields.
- Verify with `bun run preflight` (run the test suffixes separately if `mock.module` leaks across
  files), and `bun run generate:graphql` if the schema changed. iOS changes: build with
  `xcodebuild` (`DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`) on an existing
  simulator.
- Commit without asking for approval: conventional commits, English, explicit pathspec, the
  message ending with `Co-Authored-By: Claude <noreply@anthropic.com>`.
- Push directly to `main`, after the checklist of [04-push-protocol.md](../playbook/04-push-protocol.md):
  the user authorised it for this routine, and only for the fixes it makes. If
  `.github/workflows` changed and the HTTPS push is refused for lack of workflow scope, push to
  `git@github.com:moifort/vinarium.git` over SSH.
- After the push, watch every CI run of the pushed commit until all are finished, Deploy
  included. `gh run list --commit` returns nothing: filter on `headSha` in jq, then
  `gh run watch <id> --exit-status`. On failure, read `gh run view <id> --log-failed`, fix
  forward with a new commit, push, watch again.
- Never touch the changelogs. Never `terraform apply` or deploy from the Mac. Never run
  migrations by hand.

**Do not apply on your own, only propose in the report:**

- anything that changes what users see or can do;
- any infrastructure, Terraform or secret change;
- anything whose cause is unclear;
- any change that would raise paid API calls (state its cost: calls × price).

## 6. Report

In French, short.

1. The verdict in one line: **RAS**, **problèmes corrigés**, or **action requise de votre part**.
2. Four sections, each in plain words:
   - **Coûts**: yesterday's total and per service, against the 7-day average.
   - **Performances**: p50 / p95 / p99, 5xx rate, instances, cold starts.
   - **Activité**: users, sessions, requests, devices, content added, trend.
   - **Monitoring**: CI, Deploy, and a table of every scheduler job.
3. **Corrigé**: commit hashes and the CI result per workflow.
4. **À décider**: the proposals that need the user.

If nothing is wrong, say so in a few lines.
