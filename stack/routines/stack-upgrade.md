---
id: stack-upgrade
scope: machine
runtime: cloud
cadence: "0 7 * * *"
title: Upgrades (daily, after Renovate)
---

Apply the stack package upgrades and the major dependency upgrades Renovate opened overnight, on
every project of the organisation. Report in the person's language.

## Discovery
The task's repositories are cloned at the start of the run: work in them. For each one, list the
open pull requests under each of the two labels Renovate sets:
`gh pr list --repo <owner>/<name> --label stack --state open --json number,title,headRefName`,
then the same with `--label major`. A pull request bumping `@moifort/stack` follows "Stack pull
request"; one labelled `major` follows "Major dependency"; anything else is reported, not
touched.

## Stack pull request
1. Check out the pull request's branch in the repository's clone, install dependencies, and
   follow the `stack-upgrade` skill shipped by the package in
   `.claude/skills/`: sync, migrations one by one with their checks, preflight, a comment on the
   pull request with one line per migration, merge only when every migration is `safe`, applied or
   not applicable, every check passes and CI is green. Otherwise label `stack:review` and leave it
   open.
2. Put the clone back on `main`.

## Major dependency
1. Check out the branch in the repository's clone, install. Read the dependency's release notes and migration
   guide for every major between the old and the new version (`gh api` on the repository's
   releases, or the package's CHANGELOG).
2. Apply the code changes the new major requires, in one commit per dependency, verified as the
   rules prescribe. Respect the project's `allowedVersions` bounds: a pull request Renovate
   should not have opened is closed with the reason.
3. Add the `staging` label so the Deploy workflow deploys the branch to staging; wait for it.
4. Merge when CI and the staging deploy are green. Otherwise comment with what blocks (the
   failing job, the breaking change, the bound to add) and leave it open.

## Limits
- Never edit the package's rules from a consumer project; a rule that is wrong is reported.
- Never force-merge, never force-push, never touch a pull request that carries neither the `stack`
  nor the `major` label.
- At most one pull request per project per pass.

## Report
Per project: pull request, version from and to, migrations applied, not applicable, needing
review, merged or left open with the reason.
