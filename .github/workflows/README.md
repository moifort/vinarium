# GitHub Actions Workflows

## Active workflows

| File | Trigger | Purpose |
|------|---------|---------|
| `deploy.yml` | Push to `main` | Build and deploy the Nitro server to production |
| `renovate.yml` | Schedule | Automated dependency updates via Renovate |
| `test-unit.yml` | Push / PR | Run unit tests with Bun |

## Disabled workflows

### `ios-ui-tests.yml.disable`

This workflow runs the iOS UI test suite on the iOS Simulator (Xcode 26.2, iPhone 17, OS 26.2).

**Why it is disabled:** GitHub-hosted runners do not yet provide macOS images
with Xcode 26.2 and the iPhone 17 (OS 26.2) simulator required by the project's
test plan. Running the workflow on the current `macos-15` image would fail at
the simulator boot step.

**How to re-enable:**

1. Wait for GitHub to publish a `macos-26` (or later) runner image that ships
   Xcode 26.2 and the iPhone 17 / OS 26.2 simulator.
2. Update the `runs-on` value in the workflow file to the new runner label
   (e.g. `macos-26`).
3. Rename the file back to `ios-ui-tests.yml`.
4. Push and verify the workflow appears under the Actions tab.

You can track runner image availability at
<https://github.com/actions/runner-images/releases>.
