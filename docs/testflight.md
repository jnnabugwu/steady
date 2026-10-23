# TestFlight: first external build

Steps to get Steady 1.0 (build 1) to external testers through Beta App Review. The point of
going external early is an early read on 5.1.3(ii) (see `docs/technical_decisions.md`, "Health
data stays on the iPhone (App Store 5.1.3)"). Beta App Review is usually lighter than full
App Store review, so a pass is a good sign, not a guarantee. If a reviewer mentions 5.1.3 or
iCloud, copy their exact wording into issue #98. Contact details (feedback email, phone) are entered
in App Store Connect only, never in this repo, since it's public.

## 0. Before you archive

- [ ] The build under review should be the configuration being asked about: the HealthKit
      read (Health values live on the iPhone, never persisted) and the debug-only full-schema
      initializer merged to `main`. Archiving earlier means Beta App Review sees no HealthKit
      at all and says nothing about 5.1.3.
- [ ] Once HealthKit is in: the App ID `com.jmagic.steady` has the HealthKit capability
      (Xcode automatic signing adds it when the entitlement is present), and
      `NSHealthShareUsageDescription` in `app/ios/Runner/Info.plist` says what's read, why,
      and that it stays on the iPhone.
- [ ] **Deploy the CloudKit schema to production before inviting any tester.** TestFlight
      and App Store builds use the CloudKit *production* environment; with no production
      schema, sync fails for testers. Run the schema initializer on a development build,
      check every `DailyMetricRecord` field in CloudKit Console, then **Deploy Schema
      Changes**. Details: [`docs/cloudkit_schema.md`](cloudkit_schema.md). Production is
      additive-only, so check the field list first.

## 1. App Store Connect app record

My Apps → **+** → New App:

| Field | Value |
| --- | --- |
| Platforms | iOS (macOS can be added to the same record later; same bundle ID) |
| Name | Steady |
| Primary language | English (U.S.) |
| Bundle ID | `com.jmagic.steady` (team UXZV3C926U) |
| SKU | `steady-001` (any unique string; never shown to users) |
| User access | Full access |

If "Steady" is taken (app names are unique across the store, max 30 characters), try
"Steady: Daily Check-in", "Steady – Calorie Check-in" or "Steady Daily". The name on the
home screen stays "Steady" (`CFBundleDisplayName`) whatever the store name is.

## 2. Version and build

`app/pubspec.yaml` has `version: 1.0.0+1`, so the build is **1.0.0 (1)**. Both Info.plists
read it through `FLUTTER_BUILD_NAME` / `FLUTTER_BUILD_NUMBER`. Every later upload of the
same version needs a higher build number (`1.0.0+2`, ...).

The iOS target is iPhone-only (`TARGETED_DEVICE_FAMILY = 1`), so no iPad screenshots or iPad
review.

## 3. Archive and upload

Either:

- **Flutter:** `cd app && flutter build ipa --release`. This writes
  `build/ios/archive/Runner.xcarchive` and `build/ios/ipa/*.ipa`. Upload the `.ipa` with
  the Transporter app, or open the `.xcarchive` in Xcode (Window → Organizer) →
  Distribute App → App Store Connect → Upload.
- **Xcode:** open `app/ios/Runner.xcworkspace`, select "Any iOS Device (arm64)", Product →
  Archive, then Organizer → Distribute App → App Store Connect → Upload.

The entitlements say `aps-environment: development`; App Store distribution signing switches
it to production. In Organizer, check the signed entitlements before uploading if unsure.

Processing takes 5–30 minutes; the build then appears under TestFlight → iOS Builds.

## 4. Export compliance

Both Info.plists set `ITSAppUsesNonExemptEncryption` to `false` (Steady uses only Apple's
built-in encryption, such as CloudKit's HTTPS transport). App Store Connect then
doesn't ask. If it does: **No**, the app doesn't use non-exempt encryption.

## 5. TestFlight Test Information

TestFlight → Test Information:

- **Beta App Description:** "Steady pairs what you ate (imported from a Cal AI PDF export)
  with what you burned (read from Apple Health on iPhone) and a simple end-of-day check-in:
  logged, partial or skipped. No account: your data stays on your devices and syncs through
  your own iCloud."
- **Feedback email:** enter in App Store Connect (not in the repo). Testers can also send
  feedback and screenshots from the TestFlight app.
- **Marketing URL:** optional; `https://github.com/jnnabugwu/steady` works.
- **Privacy Policy URL:** `https://github.com/jnnabugwu/steady/blob/main/docs/PRIVACY.md`
  (`docs/PRIVACY.md` must be merged to `main` first, or the link 404s).
- **Beta App Review information:** contact name, phone and email in App Store Connect.
  **Sign-in required: off** (no account; it needs an iCloud-signed-in device).
- **Review notes** (paste as is):

  > No account is needed: Steady uses the device's iCloud account to sync the user's own
  > data between their iPhone and Mac (CloudKit private database; no servers). To see the
  > app working without a Cal AI export, tap **Import Cal AI PDF → Try a sample export →
  > Import 7 days → Done**: it imports seven made-up days from January 2025 and shows them
  > in the history. **Settings → Sample data → Remove sample days** removes them again.
  > The same sample file is at
  > https://github.com/jnnabugwu/steady/blob/main/docs/sample/cal_ai_sample_export.pdf.
  > On iPhone, Steady asks to read steps and active/resting energy from Apple Health. These
  > are shown on the iPhone only: they are never stored in iCloud and never written back to
  > Apple Health.
- **What to Test** (per build): "Import a Cal AI PDF export, do the end-of-day check-in,
  grant Apple Health access and check today's steps and energy, export your data from
  Settings, and if you have a Mac, check that calories and check-ins sync."

## 6. App Privacy questionnaire

App Store Connect → App Privacy. Answers that match `docs/PRIVACY.md`:

**Data collection: likely "No, we do not collect data from this app."**

Apple's definition: "collect" means transmitting data off the device in a way that lets the
developer (or third-party partners) access it for longer than needed to service the request
in real time. Steady has no servers, analytics or third-party SDKs. Calories eaten and
check-ins go only to the user's own CloudKit **private** database, which the developer can't
read; Apple Health values aren't stored or sent anywhere. On that reading, nothing is
"collected," Health & Fitness included.

Confirm before submitting: this rests on the private-iCloud reading. If you'd rather be
conservative, declare **Health & Fitness → Health** and **Fitness** as collected, with purpose
**App Functionality** only, **not linked to the user's identity** and **not used for
tracking**. Nothing is used for tracking either way.

## 7. External testers and Beta App Review

- [ ] TestFlight → External Testing → **+** → new group (for example "Friends"), add testers
      by email or enable a public link.
- [ ] Add build 1.0.0 (1) to the group → **Submit for Review**. The first build of a version
      goes through Beta App Review (usually within a day or two); later builds of the same
      version often don't.
- [ ] Record Apple's response on the TestFlight issue, especially anything about guideline
      5.1.3.
