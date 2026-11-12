---
id: deprecations
scope: project
runtime: cloud
cadence: "0 9 1 * *"
title: "Vinarium deprecations (monthly)"
---

Remove from Vinarium's API what no build on sale still asks for (repository `/Users/thibaut/Code/vinarium`).
Follow the project's `CLAUDE.md` and the stack rules on API evolution. Report in the person's
language.

1. In a worktree of `origin/main`, run `bun run deprecations` with the store API key from
   the environment (never printed).
2. For every element reported **removable**: remove it from the schema, the resolver, and the
   code and tests only it used. Leave anything in grace, waiting, still asked, or to check by
   hand; list those in the report.
3. Set the minimum supported build to the floor the script proposes. Never a higher value.
4. Verify as the rules prescribe (typecheck, the three test families separately, linter, schema
   check), commit `refactor(api): remove deprecated fields no build on sale asks for`, push to
   main (authorised for this routine), watch CI and Deploy to the end, fix forward on failure.
5. Report: what was removed, the new floor, what stays in grace and until when, anything to
   check by hand.
