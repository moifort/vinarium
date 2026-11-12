# Push

A push never starts on its own: only when the person asks for it explicitly. Then this checklist
applies in order, then the push, then the watch, then the cleanup.

## Before

1. **Generated code.** If an API contract moved, regenerate and commit the produced files, so the
   typed clients match what is deployed.
2. **Linter in write mode.** `bun run lint:fix`, commit what it fixed. CI is not a linter: a
   lint error is never discovered from a red pipeline.
3. **Preflight.** `bun run preflight` green, the test families run separately
   ([01-workflow.md](01-workflow.md#verification-before-a-commit)).
4. **Nothing else moves.** No changelog (written at release only), no README, no screenshots:
   captures are regenerated at release, not at push.

The format of a generated artefact belongs to its generator, not to the linter: every generated
file added to the repository is excluded from the linter in the same commit.

## Workflow files

Pushing a change under `.github/workflows` needs a token with the `workflow` scope. If the push is
refused, push over SSH (`git push git@github.com:<owner>/<repo>.git main`); the lasting
fix is `gh auth refresh -s workflow`, interactive, the person's to run.

## After

The push is not finished until every pipeline run for the pushed commit has been watched to the
end, Deploy included, and the result stated per workflow.

```bash
gh run list --limit 10 --json databaseId,name,status,conclusion,headSha --jq '.[] | select(.headSha | startswith("<sha>"))'
gh run watch <id> --exit-status
gh run view <id> --log-failed
```

- `gh run list --commit <sha>` returns nothing on some machines: filter on `headSha` client side.
- zsh does not word-split an unquoted variable in a `for`: loop over `${(f)ids}` or paste the ids.
  Never report CI green without the final per-run status list.
- `gh run view --log` reads a local cache (`~/.cache/gh/run-log-*.zip`) even after the logs were
  deleted on GitHub: verify a deletion against the API.

A failure is **fixed forward**: find the cause, fix it with a new verified commit, push, watch
again until green. Never force-push, never amend a pushed commit. If the cause is outside the code
(infrastructure, a secret), say so instead of guessing.

## Cleanup after the push

A successful push closes the session's working set:

- the `shutdown-simulators-after-push` hook shuts every booted simulator and quits Simulator.app
  (they otherwise hold 50 to 70 % of the CPU); do not relaunch them unless asked;
- stop every process started for the task that is no longer useful: dev server, watcher,
  preview, background build;
- delete what the session generated and that is not meant to be kept: screenshot harness builds
  and their derived data under `/tmp`, capture files, scratch scripts, temporary clones and
  worktrees (`git worktree remove`, then `git worktree prune`), backups of files taken before an
  edit;
- leave the working tree with nothing untracked that belongs to the session.

What is kept is what the repository holds; everything else was scaffolding.

## Install on the phone

When the push carried app changes next to backend changes, the install on the person's phone
follows the push, once Deploy is green ([10-ios.md](10-ios.md#physical-device)). An app-only
change was installed before the push.

## No CI for prose

Deploy, schema and test workflows carry `paths-ignore` for `site/**`, `docs/**`,
`screenshots/**`, `README.md`, `CLAUDE.md`: a push touching only those runs nothing but the
Pages workflow. For prose outside those paths, end the subject with `[skip ci]`. Never `[skip ci]`
on a commit that touches the site (it would stop Pages), and never put the served changelogs in
`paths-ignore`: the server deploys them.
