---
name: what-to-test
description: Write TestFlight "What to Test" notes for Steady's beta testers, covering what changed since the build they last got. Use when asked what's new for testers, for release notes, or before uploading a build.
---

# What to Test

Turns the commits since the testers' last build into the text for TestFlight's **What to Test** field. Two readers: the testers (friends on TestFlight, not developers) get the notes; Jordan gets a short list of what was left out and what still needs a real-device check.

## 1. Find the range

A build is a `version:` bump in `app/pubspec.yaml` (`1.0.0+N`, N = build number). List the bumps:

```sh
git fetch -q origin
git log origin/main --format='%h %ad %s' --date=short -G'^version:' -- app/pubspec.yaml
git show <sha>:app/pubspec.yaml | grep '^version:'   # each bump's build number
```

- **This build** is the newest bump on `origin/main`. If `app/pubspec.yaml` in the working tree has a higher build than `origin/main` (`scripts/build-ios-ipa.sh --bump` edits without committing), this build is `origin/main` plus that bump.
- **Baseline** is the bump for the previous build number.
- The range is `<baseline>..<this build>`. An argument naming a ref or build number overrides the baseline.

Done when you can state "build N−1 → build N" and the two SHAs. If the previous build number has no bump commit, ask Jordan which commit testers last got.

## 2. Collect every change in the range

```sh
git log --first-parent --format='%h %s' <baseline>..<this>
gh pr view <n> --json title,body,files
```

Read the body of every merged PR in the range, not just the title. Bodies say what's on screen, what's iPhone-only and what's **unverified** on a device. Done when every first-parent commit in the range is either matched to a PR you've read or read itself.

## 3. Sort each change

Every change lands in exactly one bucket:

- **Testers see it.** New screens, features, changed copy, a new permission prompt (a new Health type re-shows the sheet), fixed bugs, privacy changes.
- **Jordan only.** Docs, tests, CI, refactors, codegen, version bumps. These go in the "left out" list.

For each tester-visible change, note:
- **Platform:** iPhone only, Mac only or both. HealthKit, cravings and the coach are iPhone only.
- **What it needs:** for example, Apple Intelligence turned on, data in Apple Health, or four check-ins last week.
- **Never run on a device:** whether the PR body says it hasn't run on a real device yet.

## 4. Write the notes

Plain text: TestFlight shows no Markdown, so no `**`, `#` or links. Keep it under 4,000 characters (the field's limit). Shape:

```
Build 1.0.0 (N)

New
- <feature in a sentence: what it is and where to find it> (iPhone only)
  Try: <one concrete action>

Changed
- <...>

Fixed
- <...>

Please tell us
- <the 1–3 things most worth reporting, unverified ones first>

Send feedback with a screenshot from the TestFlight app.
```

Write for a friend trying the app:
- **Name screens and buttons by their on-screen text** ("the Coach tab", "Keep going"). Leave out code names, PR numbers and file paths.
- **Order by what's most worth trying.** Anything that has never run on a real device goes first, with a "Try" line.
- **Say what each feature needs** so a tester who doesn't see it knows why (e.g. "needs an iPhone with Apple Intelligence on").
- **Match the privacy story in `docs/PRIVACY.md`** whenever a note touches data: Health values stay on the iPhone, cravings and coach conversations stay on the iPhone, nothing goes to a server. State only what the build does.
- **Keep the tone neutral,** in the product's voice: a missed day is information. No streaks, scores or praise.
- **Mention a new permission sheet by name**, so testers expect it.

Done when every tester-visible change from step 3 is in the notes or listed in the "left out" list with a reason.

## 5. Hand it over

Reply with:

1. The notes in one fenced block ready to paste, with the character count under it.
2. **For Jordan:**
   - The range (build N−1 → N, SHAs).
   - What was left out, one line each.
   - Every change the PRs mark unverified on a device: these are worth Jordan trying before uploading.
