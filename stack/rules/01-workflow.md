# Workflow of a task

## The cycle

1. **Framing.** Understand the intent before coding. If two readings of the request lead to two
   different pieces of work, ask now, not at the end.
2. **No spec, no plan mode by default.** A design document
   (`docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`) or a written plan is produced only when
   the person asks for one. Without that, the plain explanation below is given in the conversation
   and the work starts. A paid API call states its cost either way, see [13-ai.md](13-ai.md).
3. **Implementation**, inline, to the final result, without checkpoints.
4. **Verification**, below.
5. **Review** before commit, see [03-code-review.md](03-code-review.md).
6. **Commit**, see [02-commits.md](02-commits.md).
7. **Screenshot** when a screen changed, below.

## What an explanation or a plan contains

Before the work, in the conversation (or in the plan when one was asked), a plain section:

- the domains touched: created, modified, removed;
- how it works today, what it gives afterwards, ideally a table of before and after;
- the mechanisms at play, without jargon;
- what does not move;
- why the tasks are in this order.

Code blocks serve execution, the explanation serves the decision. Each task ends with a testable
deliverable and its verification command with the expected output.

## Verification before a commit

A claim of success without the command output behind it has no value. Before every commit:

| What was touched | What runs |
|---|---|
| Backend | `bun run typecheck` (after `bun run prepare` if routes changed), the three test families **separately** (see below), `bun run lint` |
| The API schema | `bun run schema:check`: a removal not preceded by a deprecation is refused, see [11-ops.md](11-ops.md#api-evolution) |
| What `sync` writes (`stack/`, `.claude/skills/`, `.claude/hooks/`) | Never edited by hand: `bun run stack:check`, the last step of `bun run preflight`, fails on any difference, see [12-ci.md](12-ci.md#stack-checks) |
| The app | `bun run ios:build`; and after any on-screen text change, `bun run ios:strings` until it reports every string translated, see [08-copy.md](08-copy.md#localisation) |

The three test families run **separately** (`bun run test:unit`, `bun run test:int`,
`bun run test:feat`): a module mock declared in one test file serves every file of the same
run, so a single combined run passes while CI, which runs them apart, goes red.

## Mockups before a complex screen

A new feature with screens and real complexity (a new flow, several states, a layout nobody has
seen) starts with mockups, before any real code: quick throwaway renderings of the screens built
from fixtures (a preview or a harness screenshot, or a drawn mock when that is faster), sent for a
fast approval of the layout and the flow. Only once the mockups are approved does the real
implementation start. A small change to an existing screen skips this and goes straight to the
screenshot below.

## Screenshot after every UI change

Every request that changes a screen ends with a screenshot of the result, sent to the person,
followed by a wait for their approval. Without exception, and whatever the state of the simulator:

- "the simulator stops at sign-in" is never a reason to skip it. Feed the page its preview
  fixtures through a temporary launch argument in the app entry point, build (into the default
  derived data, or the worktree's fixed one: [15-tooling.md](15-tooling.md#derived-data-and-disk)),
  install and launch, capture, then revert the harness before the commit. The fixtures and
  previews stay.
- The capture is positioned on the changed part of the screen, not on the screen's top.
- Before sending, check the design conventions of [10-ios.md](10-ios.md#design-conventions).
- Committing before approval is fine. Installing on the person's device before approval is not.
- The next task does not start until the screenshot is approved.

## A UI change is validated twice

In a project with a design board ([18-design.md](18-design.md)), a requested UI change is
validated twice, in this order, as two separate asks:

1. **Board**: the change is drawn on the board, the capture is sent, and the person validates.
2. **App**: only then is it built in the app, with the simulator screenshot above, and a second
   validation.

A change in the board's prototyping zone stops after step 1. Never both steps in one ask.

## Ideas and decisions

- **Ideas** that come up and are not built now go into the project's `docs/ideas.md`, one line
  each with the date, so nothing said in passing is lost. Claude adds to it without being asked.
- **Architecture choices** get an ADR (architecture decision record) in `docs/adr/`, numbered
  (`0007-flat-collections.md`): context, decision, alternatives rejected, consequences. Written
  when the choice is made, proposed to the person before the code that depends on it.

(Shape to refine later; the rule is that both exist in every project.)

## Skills and tooling

Before starting, look at what is installed and invoke what matches the task. Never cite, impose
or document a skill without checking it exists on the machine. The skills this package ships are
in `.claude/skills/` after `sync`, for the stacks the project has: `domain`, `graphql` and
`cold-start` (backend), `ios-feature`, `ios-simulator` and `appstore` (iOS), `ai-calls` (AI),
`stack-install` and `stack-upgrade`. A rule names the skill that holds its long form; the skill
is read when the task needs it.
