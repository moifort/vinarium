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
next morning without tagging a release that is not one. Adding a tester answers 409 when they
belong to another app's group: the `appstore` skill.

## Captures and panels

Captures and marketing panels are produced **on the machine**, never in CI, every served language
at once, and committed; the release workflow uploads what the repository holds. They are
regenerated **only when the person asks for it**, never at push and not automatically at release;
when a screen changed, propose the regeneration. The app's interface, the captions and the device
frame never go through an image model. Panels upload **before** the submission: a version
already in review refuses new captures. How they are made, and the traps: the `appstore` skill.

## Listing

The listing, its translations, its subscription names and the privacy answers live in the
repository (`infra/fastlane/metadata/<locale>/`) and are pushed by a script. What has no API is
done once in the built-in browser where the person is signed in; the `appstore` skill lists it,
with the listing's traps.

## First subscription

The first subscription is submitted with an app version, through a sequence the API alone
refuses: follow the `appstore` skill.

## Site

The project's site, privacy policy and support page are served from the repository (`site/`)
through Pages, on the project's domain.
