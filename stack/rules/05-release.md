# Release

A release is a git tag `ios-v<version>`. The tag does everything: build, upload,
TestFlight, submission.

## The order

1. **Deprecations.** `bun run deprecations` lists the schema fields and arguments no build on
   sale for two weeks still asks for, and the build floor to set. One commit removes them and
   raises `MINIMUM_SUPPORTED_BUILD` to the proposed value, which sends older builds to the update
   screen. Never raise the floor by hand. See [11-ops.md](11-ops.md#api-evolution).
2. **Release notes** written in the source language and translated into each served language,
   version headings everywhere, see [06-changelog.md](06-changelog.md).
3. **Approval.** The notes in `French` are shown in the conversation and approved
   explicitly. Corrections are carried into every language. No push on unapproved notes.
4. **Push of `main`**: it deploys the backend, which serves the notes to the app.
5. **Captures and store panels**, only when the person asks for them: regenerated on the
   machine, never in CI (far too slow there), committed to the repository, and uploaded by the
   release workflow from what the repository holds. See [07-appstore.md](07-appstore.md).
6. **Tag**, posted and pushed as soon as the notes are approved. Do not hold it for outside
   conditions (a CI outage, a red run): a missing run is relaunched by hand, an unposted tag
   blocks the chain. Never tag before the approval of step 3.

## Versioning

The marketing version is manual and explicit: the one in the tag is the one in the notes. The
build number is the commit count of the built commit, never edited by hand, and is the key every
comparison uses (the build floor, the deprecation report), never the marketing version.

## End-to-end gate

A project with the `e2e` stack runs its end-to-end scenarios first, and they condition the rest:
no build nor publication if a user journey is broken. They also run locally on a disposable stack,
never against production, one run at a time. A red scenario on a posted tag is fixed, then
re-tagged; the gate is never disabled to rescue a release.

## Red pipeline on a posted tag

Fix forward and re-tag. Rerunning only the failed job (`gh run rerun --failed`) resubmits without
rebuilding when the failure was on the store side.
