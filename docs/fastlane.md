# Shipping iOS with fastlane + GitHub Actions

Nothing ships on its own. `test.yml` and `analyze.yml` run on every PR and push. The
**Ship iOS** workflow (`.github/workflows/ship-ios.yml`) runs only when you start it:
Actions → Ship iOS → Run workflow. Pick a lane:

| Lane | What it does | What it doesn't do |
| --- | --- | --- |
| `beta` | Builds a signed `.ipa`, checks it with `scripts/verify-ios-ipa.sh`, uploads it to TestFlight | Add it to a tester group, or submit it for Beta App Review (App Store Connect, `docs/testflight.md`) |
| `release` | Submits a build that's already in TestFlight for App Store review | Rebuild anything, edit metadata or screenshots, or publish once approved |

So there are three points where you decide: running `beta`, running `release`, and pressing
**Release this version** in App Store Connect after Apple approves (the lane sets
`automatic_release: false`). `release` ships the exact binary testers had. It never makes a new
build.

The lanes live in `app/ios/fastlane/Fastfile`. The fastlane version is pinned by
`app/ios/Gemfile.lock`.

## Version and build numbers

- **Version** (`1.0.0`): the part before `+` in `app/pubspec.yaml`. To ship a new version,
  bump it in a PR as usual.
- **Build number**: `beta` uses one more than the larger of TestFlight's latest build and the
  pubspec's `+N`. Nothing is committed back, so you never have to bump it by hand.
- `release` submits the latest TestFlight build for the pubspec version, or the build
  number you type into the workflow's `build_number` box.

## One-time setup

### 1. App Store Connect API key (CI's login)

App Store Connect → Users and Access → Integrations → App Store Connect API → Team Keys →
**+**. Name it `GitHub Actions`, role **App Manager**. Download the `.p8` file (you only get
one download) and note the **Key ID** and the **Issuer ID** shown above the table.

With this key, CI never uses your Apple ID, password or a 2FA code.

### 2. A private repo for signing assets (match)

fastlane `match` keeps one Apple Distribution certificate and one App Store provisioning
profile, encrypted, in a git repo. CI pulls them read-only. Create an **empty, private** repo,
e.g. `jnnabugwu/steady-certificates`. It has to be private: this repo is public, and the
encryption passphrase is the only thing protecting a public copy.

### 3. Create the certificate and profile (on your Mac, once)

```sh
cd app/ios
bundle install
export MATCH_GIT_URL=https://github.com/jnnabugwu/steady-certificates.git
bundle exec fastlane match appstore
```

It asks for your Apple ID (this run only) and a **passphrase**. Keep the passphrase in your
password manager: it's `MATCH_PASSWORD`. match creates an Apple Distribution certificate and
a profile named `match AppStore com.jmagic.steady`. The profile gets its capabilities
(HealthKit, iCloud/CloudKit, push) from the App ID, which Xcode's automatic signing has
already set up.

If Apple says you've reached the limit on distribution certificates, revoke one you no longer
use (Certificates, Identifiers & Profiles), then run it again.

Day-to-day Xcode work keeps automatic signing. Only the `beta` lane switches Runner to
match's profile, for that one build, and it restores `project.pbxproj` afterwards.

### 4. A read-only token for CI to clone that repo

GitHub → Settings → Developer settings → Fine-grained tokens → Generate. Give it access to
`steady-certificates` only, with **Contents: Read-only**. Then:

```sh
printf '%s' 'jnnabugwu:<the token>' | base64
```

The output is `MATCH_GIT_BASIC_AUTHORIZATION`.

### 5. Repository secrets

In `jnnabugwu/steady` → Settings → Secrets and variables → Actions → New repository secret:

| Secret | Value |
| --- | --- |
| `ASC_KEY_ID` | Key ID from step 1 |
| `ASC_ISSUER_ID` | Issuer ID from step 1 |
| `ASC_KEY_P8` | Full contents of the `.p8` file, including the `BEGIN`/`END` lines |
| `MATCH_GIT_URL` | `https://github.com/jnnabugwu/steady-certificates.git` |
| `MATCH_PASSWORD` | The passphrase from step 3 |
| `MATCH_GIT_BASIC_AUTHORIZATION` | The base64 string from step 4 |

Secrets aren't passed to workflows triggered from forks, and only people with write access to
the repo can start a `workflow_dispatch` run.

### 6. Before the first `release`

The `release` lane skips metadata and screenshots, so the App Store listing (description,
screenshots, privacy details, App Review contact info) has to be filled in once in App Store
Connect. After that, a release is one workflow run.

## Running it

1. Merge to `main`, and let `test.yml` go green.
2. Actions → Ship iOS → Run workflow → branch `main` → lane `beta`. This takes about 15–25
   minutes. The build then processes in App Store Connect for another 5–30.
3. Test it in TestFlight.
4. When you're happy: Run workflow → lane `release` (leave `build_number` blank for the
   latest build, or type one in).
5. After Apple approves, press **Release this version** in App Store Connect.

Standard GitHub-hosted runners, macOS included, are free for public repos, so runs don't cost
anything while this repo is public.

### Running a lane on your Mac

Export the same variables (`ASC_*`, `MATCH_GIT_URL`, `MATCH_PASSWORD`). You don't need
`MATCH_GIT_BASIC_AUTHORIZATION` locally, since your own git credentials work. Then
`cd app/ios && bundle exec fastlane ios beta`. `scripts/build-ios-ipa.sh` is still there for
building with Xcode's automatic signing and uploading through Organizer or Transporter.

## Optional: an approval gate on `release`

To require a confirmation before `release` runs (protection against a misclick), create a
GitHub Environment (Settings → Environments → `app-store`) with yourself as a required
reviewer, and add `environment: app-store` to the job in `ship-ios.yml`. The run then pauses
until you approve it.

## Not covered yet

- **macOS.** The Mac target isn't built or uploaded. It needs its own match type
  (`bundle exec fastlane match appstore --platform macos`) and a `mac` platform block in the
  Fastfile.
- **The CloudKit production schema deploy** (`docs/cloudkit_schema.md`) stays a manual step
  in CloudKit Console.
