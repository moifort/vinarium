---
name: appstore
description: Use when preparing an App Store or TestFlight step of a Polyforms app (listing, captures and panels, first subscription submission, release notes, signing secrets) or when App Store Connect refuses something. The long form of stack rule 07-appstore.
---

# App Store Connect

## The release, in order

1. `bun run deprecations`, remove what is removable, floor raised by the script's value.
2. Notes in `CHANGELOG.md` and each `CHANGELOG.<lang>.md` (rule 06), the review language's version shown
   and approved in the conversation.
3. Push `main`, watch Deploy.
4. Captures and panels only if the person asked.
5. `git tag ios-v<version> && git push origin ios-v<version>`; watch Release to the end.

## Secrets the iOS workflows read

| Secret | What |
|---|---|
| `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8` | The team's App Store Connect API key |
| `IOS_DIST_CERT_P12`, `IOS_DIST_CERT_PASSWORD` | The Apple Distribution certificate, base64 |
| `IOS_PROVISION_PROFILE` | The App Store profile named `<App> App Store`, base64 |
| `IOS_GOOGLE_SERVICE_INFO_PLIST` | The Firebase plist, base64 |
| `IOS_SENTRY_DSN`, `SENTRY_AUTH_TOKEN` | Reporting and dSYM upload |

## Captures and panels

Produced on the machine, never in CI: a run that boots emulators, backend and simulator for
every language adds half an hour to a release for images that rarely change. Every served
language at once, committed; the release workflow uploads what the repository holds. A stale
panel in the repository is a stale panel in the store.

- Captures come from in-app showcase fixtures (`-showcase` launch argument, Debug builds only),
  on a dedicated simulator, never from a seeded server.
- The app's interface, the captions and the device frame never go through an image model: the
  model produces plausible but wrong text, and a different device size at every try. Generate the
  backdrop with reserved zones, compose the real captures, draw captions in the system font of
  each language, draw the device at the same place on every panel.
- One panel per generated image: asking for two yields a dividing line. Even the backdrop out.
- Backdrops are cached and committed: adding a language or rewording a caption costs no API call.
- The product page header (16:9) lives outside the panel folders: the upload script sends every
  PNG there as a screenshot.
- `simctl addmedia` hangs on a fresh simulator until Photos has been launched once.
- Covers or product images for the showcase come from a keyless public API (iTunes Search for
  books), rate-limited; some queries answer an HTML page every time, treat it as no result.
- Panels upload before the submission: a version already in review refuses new captures.

## What has no API

The listing lives in the repository because what is written only in a console is lost at the
first account migration. What the release pipeline cannot do is done once, in the built-in
browser, signed in as the person: the app record, the price schedule, the App Privacy answers,
accepting a new developer agreement (account holder only).

## First subscription

The API refuses every direct route (`FIRST_SUBSCRIPTION_MUST_BE_SUBMITTED_ON_VERSION`,
`SUBSCRIPTION_GROUP_SUBMISSION_NOT_ALLOWED`). The sequence that works:
1. API: create a draft `reviewSubmission` (platform IOS), add the `appStoreVersion` as an item.
2. Browser: the subscription group's page, "Add for review" is a dropdown, pick the draft;
   then each subscription's page, same dropdown, same draft.
3. The draft's "Submit for review" becomes active; submit.
The version page itself shows no subscriptions section: the group's page is the way in.
Cancelling takes a minute; a draft without items cannot be cancelled, delete its items.

## Listing traps

- A name held by another account in a locale answers 409: "Name: What it does".
- Keywords: 100 characters, checked by App Store Connect.
- A locale with release notes but no listing is created empty and the submission is refused:
  add a locale's `infra/fastlane/metadata/<locale>/` before its notes.
- The product page header (16:9) is dragged in by hand: there is no API for it.

## TestFlight

Adding a tester who belongs to another app's group answers 409: create the tester with
`POST /v1/betaTesters` carrying the group relationship.
