---
id: sentry-autofix
scope: machine
runtime: cloud
cadence: "0 */6 * * *"
title: Sentry autofix (every 6 hours)
---

Fix the unresolved Sentry errors of every project of the organisation, push each fix to main, check
CI, and write a report in the person's language. This routine runs every six hours.

## Standing authorisation
The person authorised this routine to commit AND push its fixes directly to `main` without asking.
Every other rule of each project's `CLAUDE.md` and of the stack rules still applies: language,
commit style, changelog never touched, verification before commit, deprecate rather than remove an
API field, deploy only through CI, never terraform or migrate from the machine.

## Overlap guard (first)
A run starts on a fresh machine, so there is no lock file: before touching an issue, check that no
open pull request and no commit of the last 14 days on `main` carries `Fixes <SHORT-ID>`; if one
does, the issue is being handled, skip it.

## Sentry access
- Org `polyforms`, API `https://sentry.io/api/0/`.
- In the cloud, the token is a **network secret** of the cloud environment for the host
  `sentry.io`: the proxy adds the `Authorization` header to every request to that host, so call
  the API with `curl` **without** an authorization header and never look for a token in a file or
  a variable. On a desktop run, the token is `SENTRY_AUTH_TOKEN` in the project's `.env`. Never
  print it, never write it into a file or a commit.
- Logger extras appear under `.context` in the event JSON.

## Projects
The task's repositories are cloned at the start of the run: work in them. A Sentry project
`<name>-<platform>` maps to the repository `moifort/<name>`; a Sentry project whose
repository is not among the task's repositories is listed as unmapped in the report and skipped.
Add it to the task to cover it.

## Steps
1. Per project: `GET /projects/polyforms/{slug}/issues/?query=is:unresolved&statsPeriod=14d&sort=freq`.
   Keep issues with events in the last 7 days. Skip external or transient causes (timeouts,
   third-party 5xx, user cancellations) unless the code handles them wrongly.
2. Skip issues already fixed: after `git fetch origin`,
   `git log origin/main --since="14 days ago" --grep="Fixes <SHORT-ID>"`; if found, retry the
   resolve step only. A regression (`isRegression`) means the fix was wrong: investigate again.
3. Fetch the latest event (stack, message, `.context`, tags, release). Find the root cause in the
   code. Without a confident root cause, do not guess: report "to investigate" with findings.
4. In the repository's clone (already on `main`), install dependencies, follow that project's
   `CLAUDE.md` and the stack rules.
5. Fix with a regression test where the code is testable (test first). One commit per issue or
   shared root cause, minimal.
6. Verify as the rules prescribe (typecheck, the three test families separately, linter, schema
   check if the schema changed, an app build for app changes). Never commit a failing fix.
7. Commit: conventional commit, English, body with the root cause, trailer `Fixes <SHORT-ID>`,
   then the `Co-Authored-By` trailer. Never touch the changelogs.
8. Push **to `main`**, not to a `claude/` branch: `git fetch origin && git rebase origin/main`,
   then `git push origin HEAD:main`. A conflicting rebase is aborted and reported, never forced.
   An **app (iOS) fix cannot be built here** (no Xcode): push it as a branch `claude/sentry-<id>`,
   open a pull request with `gh pr create`, and let CI build it; the next pass merges it when CI
   is green.
9. Watch CI for the pushed commit (`gh run list --json databaseId,headSha,name,status,conclusion`
   filtered on `headSha`, then `gh run watch <id> --exit-status`). On failure, fix forward if the
   cause is clear, otherwise revert, push the revert, report.
10. Once CI is green, Deploy included: `PUT /organizations/polyforms/issues/{id}/` with
    `{"status":"resolvedInNextRelease"}`, never plain `resolved`.
11. Merge the pull requests opened by earlier passes whose CI is green (`gh pr list --author @me
    --label sentry`), then resolve their issues as in step 10.

## Limits
- At most 3 fixes per pass, prioritised by event count times users affected.
- Never change infrastructure, secrets, CI workflows or migrations to silence an error; never
  lower a log level to hide a bug; never delete data; never ignore an issue.

## Report (short, scannable)
Nothing found and nothing fixed: one line, plus any access problem. Otherwise per project: issues
examined, fixed (short id, root cause in one sentence, SHA, CI status, resolved or not), skipped
(reason), to investigate (leads). Access problems at the end.
