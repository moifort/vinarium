---
name: cold-start
description: Use when a backend cold start is slow, or before changing what the function loads at boot (dependencies, Sentry, Firestore, concurrency, memory) in a Polyforms Nitro project on Cloud Functions. The long form of the Scale to zero part of stack rule 11-ops.
---

# The cold start

Never a warm instance (stack rule 11-ops, Scale to zero). What is worked on instead is the cold
start itself, measured before it is changed:

- `server/system/boot-marks.ts` logs one `boot steps` line per instance (time before the
  bundle, the rest of the bundle, Sentry, the GraphQL server): read it from production logs to
  choose what to load later.
- The production bundle inlines its dependencies, except the Firebase, gRPC and Sentry packages
  (`externals` in `nitro.config.ts`): thousands of files in `node_modules` were most of a cold
  start.
- Firestore talks REST (`preferRest`), so the first read does not load gRPC; Sentry runs with
  `enableRuntimeChannelInjection: false`, which skips a module loader hook that produced no span.
- Concurrency per instance is sized on memory, not CPU (`max_instance_request_concurrency` in
  `infra/function.tf`, mirrored in `nitro.config.ts`): sixteen on 1 GiB, since requests mostly
  wait on Firestore and the models.
- Measure locally without deploying: `bun run build`, run `.output/server` under
  `@google-cloud/functions-framework` with `node`, read the `boot steps` line, alternate the two
  builds a dozen times and compare medians. A Mac is about six times faster than Cloud Run on
  the dependency load: scale the gain, and say it is an estimate.
