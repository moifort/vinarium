# Tooling on the development machine

## What a machine needs

Installed once.

| Tool | Install | Used for |
|---|---|---|
| Bun | `curl -fsSL https://bun.sh/install \| bash` | Backend, scripts, this package's CLI |
| Xcode, latest final | Mac App Store | The app; `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer` once, the person's to run |
| `gh` | `brew install gh`, then `gh auth login` | GitHub: runs, pull requests, secrets |
| `gcloud` | `brew install --cask google-cloud-sdk` | Production reads through the observer configuration |
| Terraform | `brew install terraform` | The bootstrap and local plans |
| `apollo-ios-cli` | Bundled in the app's Swift package checkout, never a global install | GraphQL codegen for the app |
| JDK and Firebase CLI | Only with the `e2e` stack | The emulators |

## Runtime

Always `bun` / `bunx`, never `npm` / `npx`. Biome for formatting and linting: spaces, single
quotes, no semicolons, line width 100.

## Xcode and simulators

- Build with the latest final Xcode. `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`
  is required for `xcodebuild`, `simctl` and `xcstringstool` while `xcode-select` points at the
  Command Line Tools; switching it needs the person's password.
- **Always the simulator runtime already on the machine.** The reference device is the iPhone of
  the runtime `xcrun simctl list runtimes` shows installed; a build or a capture targets that
  one. Never download another runtime or platform without asking: each is several gigabytes.
  When one is needed: only the version matching the installed SDK, from the command line, one
  download at a time. The commands, how to see it progress and why one stays on "Preparing to
  download": the `ios-simulator` skill.
- **One simulator at a time on the machine.** Every session and every project uses the same
  existing reference device (never a device created for a session or a task), booted on demand
  if it is not, and never shut down by a session: the push hook shuts it, with Simulator.app.
  Before booting, `xcrun simctl list devices booted`: a device already up is the one to use. A
  session installs its own build into it right before each launch, so two sessions sharing the
  device never launch each other's build; one build, install or capture at a time, waiting for
  another session's `xcodebuild` to finish. Two booted simulators is the exception that needs a
  reason (a capture on a second size).
- **Simulators are a free hand**: booting, installing, launching and capturing need no question.
- **Boot through the simulator tool of the Claude app (`attach`, `launch`) or Simulator.app,
  never `xcrun simctl boot` alone.** When `simctl boot` is the only way, open the tool's panel
  (`attach`) right after, so it has a display.
- **At the first sign of a crash, shut down and stop**, no second launch, and tell the person
  before any new attempt. The signs and why: the `ios-simulator` skill.

## Derived data and disk

- **Never a fresh `-derivedDataPath` per build** (`/tmp/<app>-<task>`, a scratch folder): each new
  path rebuilds packages, modules and the compilation cache, about 6 GB a build. Two days of
  capture builds once filled 200 GB of `/tmp` and the disk.
- By default pass no `-derivedDataPath`: Xcode reuses `~/Library/Developer/Xcode/DerivedData`,
  which the weekly cleanup routine trims. When a separate folder is needed (a worktree), use one
  fixed path per worktree, `<worktree>/build/dd`, reused from build to build, never under `/tmp`,
  and share the packages with `-clonedSourcePackagesDirPath` pointed at the main derived data's
  `SourcePackages`. `bun run rules:check` refuses a `-derivedDataPath` under `/tmp` in
  `scripts/` and `package.json`.
- **Disk full: look at `/tmp` first**, `du -xhd1 /System/Volumes/Data/private/tmp`; `du ~` does
  not count it, nor does the cleanup script.
- `simctl io <udid> screenshot` works when the simulator tool's own capture fails.

## Browser, and doing things end to end

Always the built-in browser of the Claude app, never Claude in Chrome, even when asked to "go to
Chrome". When the person says "go to the browser and click here", Claude goes and clicks: it
drives the browser, fills the forms, runs the commands, and goes to the end of the task. When a
page needs a sign-in, it asks the person to sign in there, then continues. Some console actions
have no API (a price schedule, privacy answers, a subscription submission): they are done in that
browser, signed in as the person.

The only things that wait for a go, said in one message with what will be done and why:
**reading production data** and **anything that changes production** (a deploy, a console
setting, a store submission, a purchase). Everything else (code, commands, builds, the person's
own sites and consoles in read mode, GitHub, CI) is done without asking.

## Git and GitHub

- `gh` authenticates with a keyring token; a push changing workflow files may need SSH
  ([04-push.md](04-push.md#workflow-files)).
- Worktrees for parallel sessions, with the gitignored files copied in
  ([02-commits.md](02-commits.md#several-sessions-on-one-project)).
- The App Store Connect API key for scripts lives in `~/.appstoreconnect/private_keys/`, shared
  by every app of the team; its id and issuer are in each project's `project-context.md`.

## Remote control

Driving a project from the Claude app on a phone is a CLI process per project
(`claude remote-control --name <app> --permission-mode auto --spawn same-dir`), with its own
`claude auth login`, relaunched after a reboot. Check it with `pgrep -fl "claude remote-control"`.

## Reading production

Unattended reads (logs, metrics, billing, Firestore) go through the **Claude observer account**,
one for every Polyforms project ([14-infra.md](14-infra.md)), in its own `gcloud` configuration;
`gcloud auth login` is the person's and expires. In an interactive session, a production read
is announced and waits for the go; a routine the person configured has its go in its prompt.
Firestore's REST API needs `Content-Type: application/json` or answers a misleading 400.
