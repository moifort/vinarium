# Code review

Every finished task is reviewed before its commit, inline, by re-reading the actual diff
(`git diff`, `git diff --staged`), never the memory of what was meant.

## The grid

| Axis | What to look for |
|---|---|
| Correctness | Does the code do what the task asked, entirely, and nothing more |
| Edge cases | Empty, absent, zero, duplicate, concurrency, network failure, partial data |
| Security | Unvalidated input at the boundary, secrets in clear, one user's data reachable by another |
| Cost | Reads in a loop, one query per row, work redone on every call, a paid call sized to a dataset |
| Consistency | The project's conventions: naming, structure, error handling, style |
| Debt | Duplication introduced, premature abstraction, dead code left behind |
| Tests | Would a test fail if the regression came back |
| Documentation | A surface the person sees changed without the documentation following |

Fix what must be fixed, then commit.

## Receiving a review remark

A remark is neither an order nor a truth. Verify it in the code before applying it. If right, fix
without a long comment. If wrong, say so with the fact that proves it. Agreeing with a wrong
remark costs more than contradicting it.
