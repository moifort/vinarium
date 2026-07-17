# API Evolution — Force-Update Strategy

The GraphQL schema is **not** versioned and carries no deprecation cycle. Old iOS builds
in the wild are handled by a single mechanism: a **force-update gate**. The backend
publishes a minimum supported iOS build; any older build is blocked at launch (and on
return to foreground) by an "update required" screen pointing to the App Store.

This is a deliberate trade-off: maximum codebase simplicity (no `@deprecated` fields, no
schema-diff CI, no client-version telemetry) in exchange for a blocking window during App
Store review whenever a breaking change ships. Acceptable for the current small user base.

## Moving parts

| Piece | File |
|---|---|
| Build floor + App Store URL | `server/system/app-support.ts` |
| Public config route (`GET /app-config`) | `server/routes/app-config.get.ts` (whitelisted in `server/middleware/auth.ts`) |
| Launch/foreground check, fail-open | `ios/Vinarium/Shared/Services/AppSupportGate.swift` |
| Blocking screen | `ios/Vinarium/Shared/Components/UpdateRequiredView.swift` (wired in `AuthRoot.swift`) |

The comparison key is the integer build number (`CFBundleVersion`, set by CI to
`git rev-list --count HEAD` at tag time), never the marketing version.

## Non-breaking change (the common case)

Adding a field, a query, a mutation, an optional input, a new enum handled leniently:
**do nothing**. Do not touch the floor. Old builds keep working.

## Breaking change (removal, rename, stricter input, changed enum values)

1. Implement the backend and iOS sides together, in the same commit series on `main`.
2. Bump `MINIMUM_SUPPORTED_IOS_BUILD` to the build number of the iOS release about to
   ship. The build equals `git rev-list --count HEAD` at the tagged commit; since the
   bump commit itself increments the count, target `git rev-list --count HEAD` **+ 1**
   (adjust if more commits land before the tag).
3. Follow the normal release flow: push `main` (deploys the backend and the new floor),
   then push the `ios-v<version>` tag immediately.
4. Users on older builds see the update screen until the release clears App Store review
   (auto-submitted and auto-released; usually under a day). This window is accepted. To
   avoid it entirely, hold the breaking `main` push until the new version is approved.

## Fail-open

If `/app-config` is unreachable or undecodable, the app stays usable. A stale build that
slips through the gate simply gets GraphQL errors — never lock users out because the
check itself failed.
