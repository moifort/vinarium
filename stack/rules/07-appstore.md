# App Store

Complement of [05-release.md](05-release.md) for the store side.

## Toolchain

Build with the latest **final** Xcode, never a beta or release candidate, never a version
superseded once a newer one is out: both are rejected at upload for an unsupported SDK. If the
build machine runs a beta OS, the archive carries a prerelease machine build that triggers the same
rejection: archive on a final-version machine, or patch `BuildMachineOSBuild` in the archive's
Info.plist before export (export re-signs on top).

## Signing

Manual signing end to end, archive included: a dedicated certificate and an explicit provisioning
profile. The store API key uploads and submits, it does not sign. The certificate's expiry date is
written in `project-context.md`: an unanticipated expiry breaks the release chain with an
unreadable authentication error. Without an Xcode account, `xcodebuild` signs with the API key
(`-authenticationKeyPath`, `-authenticationKeyID`, `-authenticationKeyIssuerID`).

## TestFlight

Two groups: an internal one ("Nightly") that receives the nightly build of `main`, and
an external one ("Public"). The notes job of the nightly workflow adds each build to the external
group and submits it to Beta App Review, never to App Review. A change can be tried on a phone the
next morning without tagging a release that is not one. Adding a tester who already belongs to another app's group answers
409: create the tester with the group relationship instead.

## Captures and panels

Captures and marketing panels are produced **on the machine**, never in CI (a run that boots
emulators, backend and simulator for every language adds half an hour to a release for images that
rarely change), every served language at once, and committed; the release workflow uploads what
the repository holds. They are regenerated **only when the person asks for it**, never at push and
not automatically at release. A stale panel in the repository is a stale panel in the store: when
a screen changed, propose the regeneration.

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

Panels upload **before** the submission: a version already in review refuses new captures.

## Listing

The listing, its translations, its subscription names and the privacy answers live in the
repository (`infra/fastlane/metadata/<locale>/`) and are pushed by a script; what is written only
in a console is lost at the first account migration.

What the release pipeline cannot do, done once in the browser where the person is signed in: the
app's price schedule, the App Privacy answers, accepting a new developer agreement (the account
holder only). An app name already held by another account in a locale answers 409: plan a
compound name ("Name: What it does"). Keywords are capped at 100 characters.

## First subscription

The first subscription must be submitted with an app version, and the API refuses every direct
route. The sequence that works: create a draft review submission holding the version through the
API, then in the browser open the subscription **group** page, "add for review" into that draft,
then each subscription's page, same action, then submit the draft. The version page itself shows
no subscriptions section. Cancelling a submission takes a minute; a draft with no items cannot be
cancelled, delete its items instead.

## Site

The project's site, privacy policy and support page are served from the repository (`site/`)
through Pages, on the project's domain.
