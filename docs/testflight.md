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

- **Beta App Description:** "Steady pairs what you ate (from Cal AI, through Apple Health
  or a PDF export) with what you burned, your steps and your weight trend (read from Apple
  Health), a simple end-of-day check-in (logged, partial or skipped), a guided check-in for
  cravings, and a coach for a short weekly look back. No account: your data stays on your
  iPhone and in your own iCloud. The coach is off until you turn it on; then its
  conversations go to Anthropic (the maker of Claude) only to write its replies."
- **Feedback email:** enter in App Store Connect (not in the repo). Testers can also send
  feedback and screenshots from the TestFlight app.
- **Marketing URL:** optional; `https://github.com/jnnabugwu/steady` works.
- **Privacy Policy URL:** `https://github.com/jnnabugwu/steady/blob/main/docs/PRIVACY.md`
  (`docs/PRIVACY.md` must be merged to `main` first, or the link 404s).
- **Beta App Review information:** contact name, phone and email in App Store Connect.
  **Sign-in required: off** (no account).
- **Review notes:** Apple asks every new app from a new account for the six answers
  below, as a **2.1.0 App Completeness** rejection ("Information Needed") that pauses review
  until you reply. It happened on Steady's first App Store submission (October 2026). Paste
  this into App Store Connect → App Review Information → Notes **before** submitting (it fits
  the 4,000-character limit), and attach the screen recording below to the submission's
  reply. The same text serves TestFlight's Beta App Review. If it comes back anyway: reply
  under Messages with this text and the recording, update Notes, then **Resubmit to App
  Review**. The build doesn't change. Keep every button name matched to the app; plain text
  only (App Store Connect shows no Markdown).

  ```text
  1. Screen recording: attached. Recorded on an iPhone running the latest iOS, starting from launching the app. Steady has no account registration, login or account deletion (there are no accounts), no user-generated content shared with anyone, and no paid content or in-app purchases.

  2. Purpose and audience: Steady is for adults who already log food in a tracker such as Cal AI and want a calm, judgment-free view of their week. Food trackers show one day at a time; Steady shows calories eaten beside calories burned, steps and weight trend, plus a one-tap end-of-day check-in (logged fully, partial or skipped) so people can see their tracking pattern without streaks or red marks. It also offers a short guided check-in for food cravings and an AI coach (Claude, by Anthropic) for a short look back at the week. The coach is off until the user turns it on: a consent screen says what it sends to Anthropic and why, and nothing is sent until the user taps Allow and continue. It can be turned off any time in Settings > Coach. It is not medical advice and never gives calorie targets, weight goals or diets.

  3. Setup: no login or credentials needed. Open the app to the Today tab.
  - Sample data: tap the import button (top right of Today) > Try a sample export > Import 7 days > Done. This adds seven made-up days from January 2025, visible in the Week tab. Settings > Sample data > Remove sample days removes them. The sample file is also at https://github.com/jnnabugwu/steady/blob/main/docs/sample/cal_ai_sample_export.pdf
  - Apple Health: Settings > Apple Health > Connect Apple Health (or Allow Apple Health on Today). Steady only reads steps, active and resting energy, weight and dietary energy, live, and never writes to Health or stores Health data in iCloud.
  - Check-in: on Today, tap Logged fully, Partial or Skipped.
  - Cravings: Today > Having a craving?
  - Coach: Coach tab > Turn on the coach > read the consent screen > Allow and continue (Not now leaves it off and sends nothing) > Start a chat. Needs a network connection. Settings > Coach has the switch to turn it off again. The weekly check-in appears Friday to Sunday once 4 of the previous 7 days have a check-in, so the January sample won't show it.
  - Settings also has data export, the privacy policy, and Delete coach history / Delete craving history.

  4. External services: HealthKit (read only), iCloud/CloudKit private database (optional sync of the user's own check-ins and imported calories), and, for the coach only and only after the user's consent, the Anthropic API (Claude), reached through Steady's own small proxy on Vercel. The proxy holds the API key, checks Apple App Attest on every request (DeviceCheck App Attest), sets daily limits, keeps no message content (metadata-only logs) and passes each request to Anthropic for the reply. Anthropic deletes API inputs and outputs within 30 days and doesn't train on them. No third-party SDKs, analytics, ads, authentication or payment services. Steady does not connect to Cal AI and is not affiliated with it; users import their own Cal AI PDF export, or Cal AI writes to Apple Health.

  5. Regions: the app works the same in every region. The coach needs a network connection; without one it says it can't reach the coach and the rest of the app works. The help lines shown (ANAD and 988) are US services.

  6. Regulation: Steady is not a regulated medical device (declared No in App Store Connect), does not diagnose or treat anything, and contains no protected third-party material. Cal AI is named only as a compatible data source.
  ```

- **Screen recording** (Apple requires it for 2.1 and it must start with launching the app):
  record on a physical iPhone updated to the latest iOS, with Control Center → Screen
  Recording, 2 to 4 minutes, starting on the Home Screen:
  1. Tap the Steady icon.
  2. Today: tap **Logged fully**.
  3. Import button → **Try a sample export → Import 7 days → Done**, then the **Week** tab.
  4. **Settings → Apple Health → Connect Apple Health**, through the permission sheet, back
     to Today's numbers.
  5. **Having a craving?**, through the whole guided check-in.
  6. **Coach → Turn on the coach**: the consent screen, **Allow and continue**, then **Start
     a chat**: one message, the reply, then end the session.
  7. Settings: the **Coach** switch (off and on again, through the consent screen),
     **Privacy policy**, **Export**, **Delete coach history**, then **Sample data → Remove
     sample days**.

  Your own Health numbers and any real craving or coach history appear in it; Apple is the
  only viewer, but clear the histories first if you'd rather not show them.
- **What to Test** (per build): "Import a Cal AI PDF export, do the end-of-day check-in,
  grant Apple Health access and check today's steps, energy, weight and calories eaten,
  try the coach (Coach → Turn on the coach, then Start a chat; needs a connection), log a
  craving, and
  export your data from Settings." For each build's own notes, use the `what-to-test`
  skill.

## 6. App Privacy questionnaire

App Store Connect → App Privacy. Answers that match `docs/PRIVACY.md`. **Jordan sets these in
App Store Connect before the hosted coach ships**; what follows is the proposal and the
reasoning, not a record of what's set.

> **PR #156 (PostHog analytics) is open and changes this section too.** Whichever of it and
> #153 lands second must combine the answers: the lists below are the coach's, and #156 adds
> its own (for example Usage Data / Identifiers for analytics).

**Data collection: "Yes, we collect data from this app"** once the hosted coach ships.

Apple's definition: "collect" means transmitting data off the device in a way that lets the
developer **or third-party partners** access it for longer than needed to service the request
in real time. Steady's proxy keeps no message content, but Anthropic, a third party, keeps API
inputs and outputs for up to 30 days (longer if its safety systems flag a conversation, or by
law). That is longer than real time, so the coach's data counts as collected even though it's
sent only after consent and used only for the reply. Calories eaten and check-ins in the
user's own CloudKit **private** database still aren't collected (the developer can't read
them).

Proposed answers (all: purpose **App Functionality** only; **not linked to the user's
identity**; **not used for tracking**):

| Data type | Declare? | Why |
|---|---|---|
| **Health & Fitness → Health** | Yes | Calories eaten and active/resting energy from Apple Health (and an imported Cal AI total) go into the coach's week context, and so do the craving check-ins (counts, time of day, and the reason picked from a fixed list). |
| **Health & Fitness → Fitness** | Yes | Steps from Apple Health, in the same context. |
| **User Content → Other User Content** | Yes | What the person types to the coach. Apple's "Other User Content" covers user-generated content not in the other categories. |
| **Identifiers → Device ID** | Probably not; Jordan's call | The App Attest key id is a per-install key the proxy stores (with its counter, in Upstash Redis) to verify requests and count the daily limit. It isn't the IDFA or IDFV, can't be tied to the person, and is used for fraud prevention/security. Apple's Device ID is "such as the device's advertising identifier, or other device-level ID". The conservative answer is to declare it (App Functionality, not linked, not tracking); the narrow reading is that a per-install attestation key isn't a device-level ID. |
| **Usage Data, Diagnostics, Contact Info, Location, Financial Info, etc.** | No (for the coach) | Nothing else leaves the phone for the coach. #156 may change Usage Data / Diagnostics. |

"Not linked to identity": there are no accounts, no email, no name; the proxy sees an App
Attest key id and an IP address in transit, and keeps no message content. Anthropic sees only
the proxy's requests, with no identifier of the person.

**Open questions for Jordan:**

- Device ID for the App Attest key id: declare (conservative) or not (narrow reading above)?
- Craving check-ins: proposed under Health (they read as health data, the same reason they
  stay off iCloud). Their reasons are a fixed list, not free text, so they aren't "Other User
  Content"; typed coach messages are.
- Check-in statuses (logged, partial, skipped) are also sent. Proposed under Health with the
  rest of the week context; there's no closer Apple category.
- Confirm the "collected" reading: Anthropic's 30-day retention is what makes it so. If
  Steady ever moves to zero data retention with Anthropic, revisit.

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
  - **Description:** "Steady sits next to the food tracker you already use. Connect Cal AI
    to Apple Health, or import a Cal AI PDF export, to see what you ate beside what you
    burned, your steps and your weight trend from Apple Health. Each evening, a one-tap check-in records how tracking went:
    logged, partial or skipped. No streaks, no red marks. When a craving hits, a short
    guided check-in helps you pause. And if you turn it on, a coach powered by Claude looks
    back on your week with you; its conversations go to Anthropic only to write its
    replies, and are saved only on your iPhone. No account: everything else stays on your
    iPhone and in your own iCloud."
- **Support URL:** `https://github.com/jnnabugwu/steady/issues`. **Privacy Policy URL:**
  as in §5 (the same address as Settings → Privacy).
- **App Review Information:** sign-in required **off**; contact details in App Store
  Connect only (never in this repo); notes as in §5 (the six 2.1 answers), with the §5
  screen recording attached. Without them, a new app gets a 2.1.0 rejection asking for
  exactly these.
- **App Privacy:** as in §6.
- **Age rating:** answer the questionnaire as it applies: health and wellness topics yes
  (calories, weight, cravings, with help lines), no medical treatment, no user-generated
  content shared with others, no web access. The coach is a hosted AI chat assistant
  (Claude, by Anthropic, through Steady's proxy) limited to the person's own tracking, with
  guardrails on the proxy: if the questionnaire asks about AI chatbots or AI-generated
  content, answer yes and describe it that way. Unrestricted chat with an AI can push the
  rating up; the coach is scoped to the person's tracking and refuses off-topic or unsafe
  requests (#154 evaluates that), which is the case to make.
- **Content rights:** no third-party content (the Cal AI export is the user's own file).
- **Pricing and availability:** as you choose; nothing in the app depends on a storefront.

A new account's first review can sit in "Waiting for Review" for several days. Release
"Manually" if you want to pick the day it goes live after approval.

