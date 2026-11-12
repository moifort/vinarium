# Commits

## The history is the golden source

The commit history is the source of truth for what was done and why. Every message is written for
the reader who comes back months later, Claude included: what changed, the decision behind it, the
alternative rejected, the cost of a paid call, the issue or feedback that triggered it. Before
taking a decision, read the history (`git log`, `git log -S`, `git blame`): what was tried, what was
reverted and why, which direction was chosen. A good split (one decision, one commit) and a good
message are what make that reading possible.

## Format

Conventional commits: `type(scope): subject`, English, lowercase, imperative, no trailing period.
Types: `feat`, `fix`, `refactor`, `perf`, `docs`, `test`, `chore`, `ci`. The scope is the business
domain deduced from the paths touched, never an invented taxonomy; a cross-cutting change takes
`deps`, `ci`, `config`. A commit needing two scopes is probably two commits.

The body explains the why, the decision taken and the alternative rejected, and states the cost of
a paid API call. It never paraphrases the diff. Every commit ends with the `Co-Authored-By`
trailer.

A commit that touches only documentation, a README, specs, or anything that does not change the
code, the served content or the app's strings ends its subject with `[skip ci]`: a full pipeline
with a deployment is not spent on prose. Never on a commit that touches the site (Pages would not
publish) or the served changelogs. See [04-push.md](04-push.md#no-ci-for-prose).

## Never ask

Neither the message nor the split is submitted for approval. Decide, write, commit.

## Granularity

One finished task, one commit, as soon as its verification passes. Group coherently; never bundle
unrelated tasks, so that a rollback is a clean revert. Stage explicit paths only: never `git add
-A`, `git add .` or `commit -a`.

## Iteration rounds are one commit

When the person iterates on one piece of UI round after round (a text size, an offset, a height
of the same card), the result is one commit describing the final state, not one per round:
keep amending that piece's own last commit, or squash the rounds before the push. Only while
they are unpushed, only after re-reading HEAD (below), and never across someone else's commit.

## Amend

Prefer a new commit to an amend, even when an earlier message has become inaccurate: an extra
commit costs nothing, a clobbered one costs someone else's work. When an amend is warranted,
re-read `git log -1` in the same command as the amend, never from a HEAD observed earlier.

## Branch

Work lands on `main`. No feature branch, no pull request, unless asked.

## Several sessions on one project

When several Claude sessions work on the same project at once, **each session works in its own git
worktree** and merges into `main` when its task is done. A fresh worktree lacks the
gitignored files the build needs (app secrets, Firebase plist, package resolution, generated API
client): copy them from the main checkout first, see [15-tooling.md](15-tooling.md).

Fallback rules when two sessions share a checkout anyway:

- commit with an explicit pathspec (`git commit -- <files>`), and before that, check `git diff`
  of every file outside your own folders: a file carrying someone else's changes is never staged
  into the shared index;
- never split the hunks of a generated file (an exported schema): a zero-context patch applies at
  the wrong place silently. Parse the staged blob before committing, or regenerate it whole;
- after committing, once other sessions have committed on top, grep `main` for your
  change before reporting it done: a stale copy of a file committed by another session can undo
  it.

## Push

Never on your own initiative. Commits accumulate locally until the person says "push"; then the
checklist of [04-push.md](04-push.md) applies. The one exception: a scheduled routine the person
has explicitly authorised to push (see [16-routines.md](16-routines.md)) pushes its own fixes and
watches CI like any push.
