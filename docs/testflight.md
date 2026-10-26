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
- **GitHub Actions:** Actions → Ship iOS → Run workflow → lane `beta` builds, checks and
  uploads it with fastlane. One-time setup (API key, match, secrets): [`docs/fastlane.md`](fastlane.md).

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
  with what you burned and your weight trend (read from Apple Health on iPhone), a simple
  end-of-day check-in (logged, partial or skipped), a guided check-in for cravings, and an
  on-device coach for a short weekly look back. No account: your data stays on your
  devices and syncs through your own iCloud."
- **Feedback email:** enter in App Store Connect (not in the repo). Testers can also send
  feedback and screenshots from the TestFlight app.
- **Marketing URL:** optional; `https://github.com/jnnabugwu/steady` works.
- **Privacy Policy URL:** `https://github.com/jnnabugwu/steady/blob/main/docs/PRIVACY.md`
  (`docs/PRIVACY.md` must be merged to `main` first, or the link 404s).
- **Beta App Review information:** contact name, phone and email in App Store Connect.
  **Sign-in required: off** (no account).
- **Review notes** (paste as is; the same text goes in App Store Connect → App Review
  Information for the App Store submission, §8):

  > No account is needed. Steady uses the device's iCloud account, if signed in, to sync
  > the user's own calories eaten and check-ins between their iPhone and Mac (CloudKit
  > private database; no servers). Signed out, it still works and keeps data on the
  > device; a banner explains it won't sync.
  >
  > To see it with data: on Today, tap the import button (top right) → **Try a sample
  > export → Import 7 days → Done**. It imports seven made-up days from January 2025,
  > shown in the Week tab. **Settings → Sample data → Remove sample days** removes them.
  > The sample file is also at
  > https://github.com/jnnabugwu/steady/blob/main/docs/sample/cal_ai_sample_export.pdf.
  >
  > Apple Health (iPhone): Steady asks to read steps, active and resting energy, and
  > weight. They're read live and shown on the iPhone only, never stored in iCloud and
  > never written to Apple Health.
  >
  > Coach (iPhone): a short chat and a 5-minute weekly check-in about the person's own
  > tracking, run entirely on the device with Apple's Foundation Models; nothing is sent to
  > a server or a third party. It needs an iPhone that supports Apple Intelligence, with
  > it turned on; on any other device the Coach tab says plainly why it can't run, and the
  > rest of the app works as usual. Every coach screen says it isn't medical advice. It
  > never gives calorie targets, weight goals or diets, and points to the ANAD helpline
  > and 988 if someone mentions disordered eating or a crisis. Conversations stay on the
  > iPhone; **Settings → Coach → Delete coach history** removes them. To try it: **Coach →
  > Start a chat**. The weekly check-in appears Friday to Sunday once at least 4 of the
  > previous Friday–Thursday days have a check-in, so the January sample data won't show
  > it.
  >
  > Cravings (iPhone): **Today → Having a craving?** opens a short guided check-in
  > (strength, what's behind it, an optional one-minute imagery exercise). Stored on the
  > iPhone only. **Settings → Cravings** has the ANAD helpline and 988.
  >
  > Privacy policy: **Settings → Privacy → Privacy policy**.
- **What to Test** (per build): "Import a Cal AI PDF export, do the end-of-day check-in,
  grant Apple Health access and check today's steps, energy and weight, try the coach
  (Coach → Start a chat; needs Apple Intelligence), log a craving, export your data from
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

## 8. App Store submission

App Store Connect → the app → **+ Version** (1.0.0), then:

- **Build:** the latest build from freshly pulled `main` (`scripts/build-ios-ipa.sh --pull
  --bump`), uploaded and processed.
- **Screenshots:** the 6.9-inch iPhone set (1320×2868), showing the app in use. iPhone
  only (`TARGETED_DEVICE_FAMILY = 1`), so no iPad set.
- **Promotional text / description / keywords:** a starting point, edit freely:
  - **Name:** Steady (30 max). **Subtitle:** "Track calmly, see your week" (30 max).
  - **Keywords** (100 max): `calorie,tracking,check-in,steps,weight trend,cravings,coach,
    habit,health,food log`. Never another app's name (guideline 2.3.7): "Cal AI" belongs in
    the description, as what Steady imports, not in the keywords.
  - **Description:** "Steady sits next to the food tracker you already use. Import your
    Cal AI export to see what you ate beside what you burned, your steps and your weight
    trend from Apple Health. Each evening, a one-tap check-in records how tracking went:
    logged, partial or skipped. No streaks, no red marks. When a craving hits, a short
    guided check-in helps you pause. And on iPhones with Apple Intelligence, an on-device
    coach looks back on your week with you, and nothing leaves your phone. No account:
    your data stays on your devices and your own iCloud."
- **Support URL:** `https://github.com/jnnabugwu/steady/issues`. **Privacy Policy URL:**
  as in §5 (the same address as Settings → Privacy).
- **App Review Information:** sign-in required **off**; contact details in App Store
  Connect only (never in this repo); notes as in §5.
- **App Privacy:** as in §6.
- **Age rating:** answer the questionnaire as it applies: health and wellness topics yes
  (calories, weight, cravings, with help lines), no medical treatment, no user-generated
  content shared with others, no web access, and the coach is an on-device assistant
  limited to the person's own tracking (if asked about AI chat, say so).
- **Content rights:** no third-party content (the Cal AI export is the user's own file).
- **Pricing and availability:** as you choose; nothing in the app depends on a storefront.

A new account's first review can sit in "Waiting for Review" for several days. Release
"Manually" if you want to pick the day it goes live after approval.

