# Scheduled routines

Claude tasks that run on a schedule. Each one states its cadence, where it runs, its
repositories, what it may do, and what it never does. A routine's push is the one exception to
"never push unasked" ([02-commits.md](02-commits.md#push)).

## Where a routine runs

**In the cloud by default**, as a cloud scheduled task on the person's claude.ai account: it runs
when the machine is off, from a fresh clone of the repositories, with the connectors and the
environment variables the task is given, and pushes as the person's GitHub identity. Minimum
interval one hour. What a cloud run does not have: the machine's files (no keychain, no local
`.env`, no observer `gcloud` configuration), Xcode and the simulators, the person's browser
sessions. So:

- a cloud routine gets its credentials as environment variables of its cloud environment (the
  Sentry token, the observer service account key, the store API key), never from a file in a
  repository;
- a change a cloud routine cannot verify itself (an app fix needs Xcode) is pushed as a branch
  with a pull request, and merged by the next pass once CI built it, instead of going to
  `main` directly;
- a routine that needs the machine (a simulator, the keychain, a capture) is a **desktop**
  scheduled task, which runs only while the app is open and the Mac awake, and catches up one
  missed run on wake.

Each routine's prompt names its runtime in its frontmatter (`runtime: cloud` or `desktop`); the
install and upgrade skills create a cloud task through the `/schedule` tooling or a desktop task
through the app, and update it on a version change.

## When a routine cannot decide

A routine never asks the person in its own session: nobody is there. It **opens a GitHub issue**
in the project, labelled `decision`, with the question, the options and what it will do by
default if nobody answers, and references it from the pull request or the report. GitHub
notifies the person on their phone and desktop; the answer is written in the issue; the next pass
reads the issues labelled `decision` that got an answer and acts on them. A push notification to
the phone (`PushNotification`) is sent in addition when the session can, best effort: it needs
Remote Control connected and is not reliable from a scheduled run.

| Routine | Cadence, runtime | Does | Never |
|---|---|---|---|
| Sentry triage | Every six hours, cloud, every app | Reads unresolved issues, fixes the cause with a verified commit, pushes to `main`, watches CI, marks `resolvedInNextRelease` | Marks plain `resolved`; touches an issue it did not fix |
| Daily health | Noon, cloud, per app | Through the observer account: spend from the billing export, performance, monitoring; fixes and pushes what is code; reports cold starts as a figure | Proposes a warm instance; reads errors (Sentry's job) |
| Upgrades | Every morning after Renovate, cloud | Stack pull requests (label `stack`): the `stack-upgrade` skill, sync, migrations with their checks, merge when every migration is safe and CI is green. Major dependency pull requests: reads the changelog and migration guide, applies the code changes, deploys to staging, merges when CI and staging are green, otherwise comments and leaves open | Force-merges; edits rules; touches a pull request without one of those labels |
| Deprecations | Monthly, cloud, per app | Runs the deprecations script, removes what is removable, raises the build floor, pushes, watches CI and Deploy | Removes anything in grace or still asked; raises the floor by hand |
| iOS disk cleanup | Weekly, desktop, the machine | Trims old derived data, unavailable simulators, stale Swift package caches, Xcode caches; reports runtimes and `/tmp` to clean by hand | Deletes a runtime, an archive, a project or anything under `/tmp`; downloads a runtime |

## Shipped by the package, installed on the machine

The routines' prompts live in `routines/` of this package, with placeholders for the project's
facts. A routine is `scope: machine` (one instance for every project: Sentry triage, stack
upgrades) or `scope: project` (one per project: daily health). `sync` renders them into
`~/.claude/scheduled-tasks/<id>/SKILL.md` (`<id>-<app>` for a project routine); the
`stack-install` and `stack-upgrade` skills then create the scheduled task when it does not exist
and update its prompt and cadence when it does, through the app's scheduled-tasks tools. A routine
is never edited by hand on the machine: the change goes into the package and reaches every machine
and project at the next version.

## Rules

- A routine verifies before committing and watches CI after pushing like any session; what it
  cannot verify where it runs goes through a pull request and CI.
- A routine pushes at most three commits per pass (Sentry) or one (the others), and a report
  that says "pushed" always carries the CI result per workflow.
- A routine never asks the person in its session; a decision becomes a `decision` issue.
- A routine reads production through the observer account, never through the person's login.
- The daily health routine checks the last run of every other routine and reports one that
  missed two cadences: nothing else watches the routines.
- The routine's prompt lives in the machine's scheduled tasks; the skills it follows are shipped
  by this package.
