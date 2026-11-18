# RevenueCat as Steady's paywall and subscription layer

> Status: research input for a product decision (2026-11-17). Not a decision record. Context:
> 1.1.0 puts the hosted coach behind a subscription (`docs/design/onboarding.md`, "The coach
> steps are marked paid"). Primary sources only. Each bracketed label, such as
> [rc: install flutter], links to its source, and the URLs are listed at the end. "Not confirmed"
> means I looked and couldn't find it. Conclusions from reading SDK source code are marked
> "inference".

---

## TL;DR

- **SDK:** `purchases_flutter` and `purchases_ui_flutter` **11.0.3** (2026-11-16). They need iOS
  13+ (iOS 15+ for the paywall UI), Flutter 3.22+ and Dart 3.4+. Steady (iOS 17, Flutter 3.47.5,
  already on Swift Package Manager) fits. StoreKit 2 is the default, and v12 will require SPM.
- **No login needed.** The SDK makes a random `$RCAnonymousID:` and caches it on the device. A
  reinstall or new device gets a new ID, and **Restore Purchases** reattaches the Apple
  subscription.
- **Don't use the App Attest key id as the App User ID.** Apple's keys don't survive a reinstall,
  a device migration or a restore from backup.
- **Setup:** one entitlement (`coach`) and one offering. Monthly and/or yearly products go in one
  subscription group, with a free trial as the introductory offer. RevenueCat needs the In-App
  Purchase key. The first subscription has to ship together with an app version (1.1.0).
- **Paywall UI:** RevenueCat's paywall is native SwiftUI in a sheet and needs no Material in
  Steady's code. But it can't use `steadyTheme` or be widget-tested. **Recommendation: a custom
  shadcn paywall** that calls `Purchases.purchasePackage`.
- **Server:** a client-only gate can be bypassed. **Recommendation:** the app sends the StoreKit 2
  signed transaction (JWS) with each coach request. The proxy verifies it offline with Apple's
  library and ties it to a few App Attest keys in Redis. RevenueCat's REST API is the fallback.
  RevenueCat's own customer tokens are private beta and not in the Flutter SDK.
- **Privacy:** the SDK's privacy manifest declares only Purchase History (App Functionality, not
  linked, no tracking). RevenueCat says to also list Analytics. **The iOS SDK sends the IDFV on
  every request**, which neither the manifest nor RevenueCat's docs mention. No IDFA without
  AdSupport, and no ATT prompt.
- **Pricing:** free below $2.5K monthly tracked revenue, then 1% of it.
- **Testing:** the Test Store works only in debug builds. StoreKit configuration files work only
  when the app is launched from Xcode, not with `flutter run`. Sandbox renews a month in 5
  minutes; TestFlight renews daily, up to 6 times.

---

## 1. SDK

**Versions.** `purchases_flutter` and `purchases_ui_flutter` are both 11.0.3, released 2026-11-16
([pub: purchases_flutter], [pub: purchases_ui_flutter], [gh: flutter releases]). 11.0.0 came out
2026-10-28, and 10.19.1 (2026-11-13) is a 10.x maintenance release. 11.0.3 pins
`PurchasesHybridCommon` 20.9.0 ([gh: flutter ios Package.swift]), which pins `purchases-ios`
5.103.0 ([gh: PHC Package.swift]). RevenueCat's install page still shows `^10.10.0`
([rc: install flutter]); pub.dev is current.

**Minimums.** Dart `>=3.4.0 <4.0.0` and Flutter `>=3.22.0` for both packages ([gh: pubspec]).
iOS 13.0 ([gh: flutter ios Package.swift]) and Xcode 14+ ([pub: purchases_flutter]). The paywall
UI needs iOS 15; its native code is `@available(iOS 15.0, *)` ([rc: paywalls install], [gh: ui
plugin swift]).

**What 11.0.0 broke** is mostly Android. On iOS, a failed offerings fetch during a purchase now
reports the offerings error. Paywalls no longer call `onPurchaseCompleted` for purchases the app's
own `PaywallPurchaseLogic` completes ([gh: flutter changelog]).

**Swift Package Manager.** New Flutter projects get the iOS SDK through SPM with no setup.
RevenueCat: "version 12 will require Swift Package Manager." Don't also add `purchases-ios` in
Xcode ([rc: install flutter]). Flutter has used SPM by default since 3.44, and CocoaPods trunk goes
read-only on 2026-12-02 ([flutter: spm plugin authors]). Steady's `app/ios` has no Podfile, so it's
on SPM already. Open issue #2014 asks RevenueCat to add Flutter's `FlutterFramework` dependency
(Flutter 3.41+), which Flutter's guide doesn't yet call required ([gh: issue 2014]).

**StoreKit 2** is the default. `StoreKitVersion.default` is `.storeKit2`, used on iOS 16+
([gh: StoreKitVersion.swift]), and has been since Flutter SDK v8 ([gh: flutter changelog]).

**Install and configure** ([rc: install flutter], [rc: configuring sdk]). Run `flutter pub add
purchases_flutter` (plus `purchases_ui_flutter` only for RevenueCat's paywall). Turn on the In-App
Purchase capability in Xcode. Then configure once, early:
`Purchases.configure(PurchasesConfiguration(<Apple public SDK key>))`.

**Flutter defaults** ([gh: PurchasesConfiguration]). `entitlementVerificationMode` is `disabled`
and `diagnosticsEnabled` is `false`. `automaticDeviceIdentifierCollectionEnabled` is `true`, but
it acts only once an attribution ID is set (`setAdjustID` and similar). Preferences go in standard
`UserDefaults`.

---

## 2. Anonymous users

**The ID.** With no App User ID, the SDK "will generate a new random App User ID (prefixed with
`$RCAnonymousID:`) … and will cache it on the device." On reinstall, "the cache will be cleared"
and a new one is made ([rc: identifying customers]). The cache is in UserDefaults, so a phone
restored from an iCloud backup probably keeps the ID. Not confirmed.

**Restore Purchases** restores what the same store account bought. Call it only from a tap,
because it may show an OS sign-in prompt; `syncPurchases` is the programmatic version
([rc: restoring]).

**Transfer behavior.** The default is "Transfer to new App User ID". If one anonymous ID restores
a receipt owned by another anonymous ID, the two are **merged (aliased)**. For "no login mechanism
and only relies on RevenueCat anonymous App User IDs", RevenueCat calls this default "Required to
allow customers to restore transactions after uninstalling / reinstalling your app"
([rc: restore behavior]). After a merge, every alias returns the same `CustomerInfo`
([rc: identifying customers]).

**A stable ID of our own?** It's possible, through `appUserID` at configure or `logIn`. It must
be unique per user and not guessable ("RevenueCat provides subscription status via the public
API"): a UUID v4, at most 100 characters, never an email or IDFA, never hard-coded ([rc:
identifying customers]). The upside: a UUID becomes StoreKit 2's `appAccountToken` ([gh:
PurchasesOrchestrator]), so Apple's signed transactions carry it. The downside: a custom ID means
declaring Identifiers → User ID ([rc: app privacy]), and keeping it across devices means storing
it in iCloud. Not for 1.1.0.

**Not the App Attest key id.** Apple: keys "don't survive app reinstallation, device migration, or
restoration of a device from a backup" ([apple: app attest]). Steady also replaces the key after
`attestation_failed` (CLAUDE.md §11). Each new key would be a new RevenueCat customer, and the
proxy's one device identifier would end up in RevenueCat's purchase records.

---

## 3. Entitlements, offerings and products

**RevenueCat:** one entitlement (`coach`) with every coach product attached, and one current
offering with a monthly and/or annual package. The app checks
`customerInfo.entitlements.active['coach']` ([rc: entitlements]).

**App Store Connect** ([rc: asc setup], [rc: ios products]):

1. Sign the Paid Applications Agreement, add banking and tax.
2. Create a subscription group. It needs a localization before you submit.
3. Add products: ID, price, duration, localization.
4. Add a free introductory offer. "Customers can redeem one introductory offer per subscription
   group" ([apple: subscriptions]). The Flutter `checkTrialOrIntroductoryPriceEligibility` can
   return "unknown", and then the non-trial price should show ([gh: purchases_flutter.dart]).

Periods: at least seven days (3.1.2(a), [apple: guidelines]); weekly to annual (Schedule 2
§3.8(a), [apple: dpla]).

**Credentials.** The **In-App Purchase key** (.p8 and Issuer ID) is required: without it,
StoreKit 2 "transactions will fail to be recorded" ([rc: iap key]). The shared secret is for
StoreKit 1 only ([rc: shared secret]), though the store setup page still lists it. An App Store
Connect API key is recommended, for importing products ([rc: connect store]). App Store Server
Notifications are optional for subscriptions. They speed up webhooks and enable Refund Control;
"Apply in App Store Connect" sets them, V2 is recommended, and "Track new purchases from
server-to-server notifications" should stay off ([rc: apple notifications]).

**Shipping.** The first auto-renewable subscription must be submitted with an app version
([rc: asc setup]). Products can take up to 24 hours to become buyable ([rc: rejections]).
**Family Sharing can't be turned off once it's on** ([rc: family sharing]).

---

## 4. Paywalls

**RevenueCat Paywalls (`purchases_ui_flutter`):**

- **How it's shown.** `RevenueCatUI.presentPaywall()` or `presentPaywallIfNeeded("coach")` calls
  a method channel, and native code presents a SwiftUI paywall over Flutter, as a sheet by default
  or full screen. `PaywallView` embeds it instead, as a `UiKitView`, and shouldn't go in a modal
  bottom sheet ([rc: displaying paywalls], [gh: ui lib], [gh: ui plugin swift]).
- **Material.** The package imports `material.dart` in its own widget files. But the present API
  needs no widget, and `PaywallView` returns only a widgets-layer `UiKitView` ([gh: ui lib]).
  Steady's code needs no Material import, and nothing in the source needs a `MaterialApp`
  ancestor (inference; the docs don't say).
- **Customizing** happens in the dashboard: templates, an AI editor, Figma import, light and dark
  versions, localization, price variables, Restore and terms buttons, multi-step flows. Fonts are
  uploaded or bundled. Changes need no app update ([rc: paywalls], [rc: paywall components]).
- **Events.** It sends `paywall_impression`, `paywall_close` and others to RevenueCat
  ([rc: paywall events]).
- **Costs for Steady:** no `steadyTheme` or `ui_kit`, so the Native Glass look would be rebuilt in
  the dashboard. A native view can't run in a widget test (inference). Open issue #1735: it
  stutters when reopened ([gh: issue 1735]).

**A custom shadcn paywall** uses `Purchases.getOfferings()` → `offerings.current`, then
`purchasePackage(package)`, which returns `customerInfo` and a `storeTransaction`, and
`restorePurchases()` ([gh: purchases_flutter.dart]). Don't assume a package exists: until Apple
approves a product, the SDK leaves its package out ([rc: rejections]).

**What Apple requires on the screen:**

- **Contents:** the subscription's name and length, what it includes, the full renewal price
  (clear, prominent, localized), a way to restore, and Terms of Use and Privacy Policy links in
  the app and in the metadata ([apple: subscriptions]).
- **Prices:** "The amount that will be billed must be the most prominent pricing element." A trial
  shows its length and the price after it ([apple: subscriptions]).
- **Schedule 2 §3.8(b)** and **3.1.2(c):** title, length, price (per unit if appropriate),
  privacy and terms links in the app ([apple: dpla]); "clearly describe what the user will get
  for the price" ([apple: guidelines]).
- **Common rejections** (RevenueCat): billed amount not shown, unclear intro offer, no "Cancel
  anytime", terms or privacy hard to find ([rc: paywall app review]).

---

## 5. Server-side enforcement in the proxy

**The threat.** App Attest already blocks a modified app (CLAUDE.md §11). What's left is a
genuine app presenting someone else's ID or receipt, and jailbroken devices, where App Attest is
weaker. RevenueCat's Trusted Entitlements guards only the app's own copy of the status, and it's
`disabled` by default in Flutter ([rc: trusted entitlements], [gh: PurchasesConfiguration]).

| Option | How | For | Against |
| --- | --- | --- | --- |
| **A. RevenueCat REST** | The app sends `Purchases.appUserID`. The proxy calls v1 `GET /subscribers/{id}` or v2 `…/customers/{id}/active_entitlements` with a secret key ([rc: api v1 customers], [rc: api v2 customer]). | No native code. RevenueCat tracks renewals, refunds and aliases. | The ID is a bare claim. v1 "creates a new customer if it doesn't exist". v2 allows 480 requests/min per key ([rc: api v2]). v1's limit and both versions' latency aren't documented. RevenueCat is on the request path, so cache in Redis. Not confirmed: v2's `customer_id` = App User ID. |
| **B. Webhooks** | Store "entitled until" per ID in Redis, updated by webhooks. Each carries an authorization header and an HMAC signature, with up to 5 retries over about 80 minutes ([rc: webhooks]). | Nothing extra on the request path. | Same bare ID, plus stored state and possible lag. Use it to invalidate A's cache. |
| **C. Apple JWS** | The app sends `jwsRepresentation` from `Transaction.currentEntitlements` ([apple: currentEntitlements], [apple: jwsRepresentation]). The proxy runs `SignedDataVerifier` (`@apple/app-store-server-library` 3.1.0, [gh: apple server library]) and checks bundle ID, product, `expiresDate`, `revocationDate` and `environment` ([apple: JWS payload]). | Signed by Apple, so it can't be forged. Checked locally, with no RevenueCat key. Steady already reads `AppTransaction` in Swift (`steady/install`). | Needs a small Swift channel, because the Flutter `StoreTransaction` exposes only the id, product and date ([gh: store_transaction.dart]). A JWS is a bearer token until it expires, and an old one hides a refund. Fix: tie it to App Attest keys, and recheck with **Get All Subscription Statuses** (50 requests/s per app, 10% of that in sandbox, [apple: server api limits], [apple: subscription statuses]) using an In-App Purchase key. |
| **D. RevenueCat Authentication** | A customer JWT, verified against the project's JWKS ([rc: customer authentication]). | The right shape. | Private beta, iOS SDK 5.88+ only, "Support for the hybrid SDKs will follow". It also needs an identity-provider sign-in, which Steady doesn't have. |

**Stopping someone else's subscription.** With no accounts, neither A nor C can tell people
apart, so cap the sharing. In Redis, map the subscription (C: original transaction id; A: App
User ID) to the App Attest key ids that used it. Allow about 5, since reinstalls and new phones
make new keys ([apple: app attest]), and drop keys unused for 30 days; 3.1.2(a) wants
subscriptions to work "across all of the user's devices" ([apple: guidelines]). Cache "entitled
until min(expiresDate, now + a few hours)" per key. (The SDK refreshes its own cache after 5
minutes, [rc: customer info].)

**Sandbox.** App Review buys in sandbox ([rc: rejections]), so the proxy must accept
`environment: Sandbox` from App Store builds. RevenueCat's "Sandbox testing access" must stay at
**Anybody**, or reviewers get no entitlement ([rc: sandbox access]). Sandbox accounts work only
"within your own developer account", and TestFlight runs in sandbox, so testers get the coach
free ([apple: testflight subscriptions]).

---

## 6. Privacy

**The SDK's privacy manifest** (`purchases-ios` 5.103.0; the SPM mirror is identical) collects
Purchase History, with linked `false`, tracking `false` and purpose App Functionality. Its
required-reason API is UserDefaults, reason `CA92.1`. `NSPrivacyTracking` is `false`, and there's
no `NSPrivacyTrackingDomains` key ([gh: PrivacyInfo ios]). `PurchasesHybridCommon` declares no
data types ([gh: PrivacyInfo phc]).

**RevenueCat's label guidance** ([rc: app privacy]): declare Purchases → Purchase History for
"Analytics" and "App Functionality". With anonymous IDs and "no way to identify individual users,
you can select 'No'" for linked. User ID applies only to custom IDs, and Device ID only to
advertising-ID integrations.

**Apple's definitions leave room for doubt.** Data counts as linked "via their account, device, or
other details" unless it's de-identified. "Personal Data" under privacy laws is "considered
linked". A User ID includes an "assigned user ID", and a Device ID "other device-level ID"
([apple: app privacy details]). So whether a random purchase ID is linked is a judgment call.

**IDFV.** On iOS, the SDK adds `X-Apple-Device-Identifier: <identifierForVendor>` to every
request, with no condition ([gh: HTTPClient.swift]). It isn't in the manifest or on RevenueCat's
privacy page. RevenueCat's privacy policy lists device type, OS, last seen, the receipt and an
optional user ID ([rc: privacy policy]). Steady already declares Device ID for the App Attest key
(`docs/testflight.md` §6). What RevenueCat does with the IDFV isn't documented.

**IDFA and ATT.** The SDK reads the IDFA only through `ASIdentifierManager`, and only if the app
links AdSupport. It reads the ATT status through selectors without linking the framework, and has
no `requestTrackingAuthorization` call ([gh: AttributionFetcher.swift]). Steady links neither, so
there's no prompt as long as it never sets attribution IDs.

**DPA, retention, sub-processors.** RevenueCat is the processor, and the DPA is part of the
standard terms, so nothing needs signing ([rc: data and compliance], [rc: dpa]). If asked within
30 days of termination, RevenueCat deletes or returns the data, "subject to … backup and archival
practices". Sub-processors are listed in Annex 3 (AWS, Snowflake, Google, OpenAI, Anthropic and
more), and transfers use SCCs ([rc: dpa]). No retention period for app users' data is published.
Data is on AWS in the US ([rc: privacy policy]), and `DELETE /subscribers/{id}` exists ([rc: api
v1 customers]). So RevenueCat needs a line in `docs/PRIVACY.md`. It gets no health data unless
Steady sets customer attributes, so set none.

---

## 7. Pricing

Free in any month below $2.5K MTR (monthly tracked revenue, USD, before the store's cut), then
1%. The page's example is $25 at $2.5K, so it's 1% of all of it. "Our entire suite of features
comes standard", and no card is needed until the threshold ([rc: pricing]). Webhooks are on Pro
([rc: webhooks]).

---

## 8. Testing

| Where | What works |
| --- | --- |
| **Test Store** | Its own API key. A modal simulates success, failure or cancel, and purchases grant entitlements as sandbox data. Flutter SDK 9.8.0+. **A release build with this key crashes on purpose, TestFlight included**, so pick the key per build type, like `COACH_PROXY_URL`. There's no StoreKit, so it can't test option C ([rc: test store]). |
| **StoreKit configuration file** | Local, with no App Store servers ([apple: storekit testing]). It's only used when launched from Xcode: "`flutter run` … won't use the StoreKit Configuration File" ([rc: apple sandbox]). Not signed by Apple's roots, so the proxy would reject it (inference). |
| **Sandbox, on a device** | Sandbox Apple Account. Renewals are sped up: a week takes 3 min, a month 5, a year 1 hour, at most 12 a day. Signed by Apple, `environment: Sandbox` ([rc: apple sandbox]). |
| **TestFlight** | Sandbox. "Each subscription is renewed daily, up to 6 times within a 1-week period" ([apple: testflight subscriptions]). |
| **Simulator** | StoreKit file and Test Store. Sandbox products fail to load in the iOS 18.4–18.5 simulators; iOS 26 fixed it ([rc: ios 18.4 simulator]). No App Attest (the debug bypass covers it), so purchase plus proxy runs end to end only on a device. |

---

## 9. Gotchas

**App Review (3.1.1, 3.1.2)** ([rc: rejections], [apple: guidelines], [apple: dpla]):

- **Products don't load** if the subscription wasn't submitted with the version.
- **`STORE_PROBLEM`** comes from sandbox outages. Resubmit.
- **Nothing unlocks after purchase.** For Steady, the reviewer must buy in sandbox and then get a
  coach reply, which goes through App Attest and the proxy.
- **Disclosures** (§4).
- **3.1.2(a):** "ongoing value", no bait-and-switch, and don't remove what users already paid
  for. 1.0 had no hosted coach and no purchases (`docs/testflight.md`).
- **Schedule 2 §3.8(c):** "You must fulfill the offer during the entire subscription period." The
  proxy's daily cap and kill switch become promises to paying users.

**Flutter and SDK.** 11.0.0's CocoaPods pod was published late, and a later major version drops
CocoaPods ([gh: flutter changelog]). Issue #1192: the customer-info listener isn't called after a
hot restart or an out-of-memory restart, so call `getCustomerInfo()` on resume ([gh: issue
1192]). Issue #1161 (a full-screen paywall not dismissing after restore) no longer reproduces on
9.9.0, its reporter says ([gh: issue 1161]). `flutter run` skips StoreKit files, and Test Store
keys crash release builds (§8). No open issue mentions Flutter 3.47 or iOS 17 (checked
2026-11-17, [gh: flutter issues]).

---

## Recommendation for Steady

**SDK.** `purchases_flutter` 11.0.3 over SPM, in a new
`features/subscription/{subscription_domain,subscription_data,subscription_presentation}`. Only
`_data` imports the SDK; the coach reads `subscription_domain` for its gate. Use anonymous IDs and
the default transfer behavior, with Restore on the paywall and in Settings. No
`purchases_ui_flutter`. The Apple and Test Store keys come from `--dart-define`, per build type.

**Paywall UI.** A custom shadcn/`ui_kit` screen before the consent step
(`docs/design/onboarding.md`). It shows the billed price as the largest price, the trial length
and the price after it, "Cancel anytime", Restore, and Terms and Privacy links. It keeps the
no-Material rule, uses Steady's tokens, can be widget-tested and sends no paywall events.
RevenueCat Paywalls stay an option if remote experiments ever outweigh design control.

**Proxy: option C.**

1. A Swift channel next to `steady/install` returns the `coach` JWS from
   `Transaction.currentEntitlements`.
2. `HostedCoachModel` sends it inside the App Attest-signed body.
3. The proxy verifies it, accepting Sandbox too.
4. The proxy ties the original transaction id to at most 5 App Attest keys.
5. It caches the result until expiry and rechecks it about daily with Get All Subscription
   Statuses, which catches refunds.
6. A new error code maps to a new `CoachModelFailure` ("subscription required").

The cost is some Swift and a second Apple key on the proxy. In return, RevenueCat stays off the
request path and Apple signs the proof. Option A (cached REST plus webhooks) needs no native
code, but it trusts a bare ID.

**App Privacy label** (`docs/testflight.md` §6):

- **Add Purchases → Purchase History** (App Functionality and Analytics, not linked, not
  tracking). The proxy's stored transaction id falls under it too.
- **Device ID:** keep it, and note that it also covers the IDFV that RevenueCat's SDK sends.
- **No ATT:** never set attribution IDs or customer attributes.
- **PRIVACY.md:** add RevenueCat as a processor.

---

## Open questions for Jordan

- **Plans:** monthly, yearly or both, and at what prices? Is the trial one week ("try the coach
  free for a week", onboarding doc)?
- **Family Sharing:** on or off? It can't be undone.
- **Limits:** given §3.8(c), what daily cap do subscribers get, and what does the kill switch mean
  for them? Should a fair-use limit be stated?
- **Label:** declare Identifiers → User ID for the anonymous RevenueCat ID, which is more cautious
  than RevenueCat's "No"? Which purpose goes on Device ID for the IDFV? (One question to
  RevenueCat support would settle what they use it for.)
- **Terms of Use:** Apple's standard EULA, or our own?
- **Proxy:** is the Swift JWS channel acceptable, or is option A's simplicity worth a bare-ID
  trust?
- **Free vs paid:** what exactly is in each? The onboarding doc says this is still open.

---

## Sources

All fetched 2026-11-17. (Link definitions: the labels in the text link to these.)

[rc: install flutter]: https://www.revenuecat.com/docs/getting-started/installation/flutter
[rc: configuring sdk]: https://www.revenuecat.com/docs/getting-started/configuring-sdk
[rc: identifying customers]: https://www.revenuecat.com/docs/customers/identifying-customers
[rc: restoring]: https://www.revenuecat.com/docs/getting-started/restoring-purchases
[rc: restore behavior]: https://www.revenuecat.com/docs/projects/restore-behavior
[rc: customer info]: https://www.revenuecat.com/docs/customers/customer-info
[rc: trusted entitlements]: https://www.revenuecat.com/docs/customers/trusted-entitlements
[rc: customer authentication]: https://www.revenuecat.com/docs/customers/customer-authentication
[rc: entitlements]: https://www.revenuecat.com/docs/getting-started/entitlements
[rc: ios products]: https://www.revenuecat.com/docs/getting-started/entitlements/ios-products
[rc: asc setup]: https://www.revenuecat.com/docs/platform-resources/apple-platform-resources/app-store-connect-setup-guide
[rc: connect store]: https://www.revenuecat.com/docs/projects/connect-a-store
[rc: iap key]: https://www.revenuecat.com/docs/service-credentials/itunesconnect-app-specific-shared-secret/in-app-purchase-key-configuration
[rc: shared secret]: https://www.revenuecat.com/docs/service-credentials/itunesconnect-app-specific-shared-secret
[rc: apple notifications]: https://www.revenuecat.com/docs/platform-resources/server-notifications/apple-server-notifications
[rc: family sharing]: https://www.revenuecat.com/docs/platform-resources/apple-platform-resources/apple-family-sharing
[rc: paywalls]: https://www.revenuecat.com/docs/tools/paywalls
[rc: paywalls install]: https://www.revenuecat.com/docs/tools/paywalls/installation
[rc: displaying paywalls]: https://www.revenuecat.com/docs/tools/paywalls/displaying-paywalls
[rc: paywall components]: https://www.revenuecat.com/docs/tools/paywalls/creating-paywalls/components
[rc: paywall app review]: https://www.revenuecat.com/docs/tools/paywalls/creating-paywalls/app-review
[rc: paywall events]: https://www.revenuecat.com/docs/tools/paywalls/paywall-events
[rc: api v1 customers]: https://www.revenuecat.com/docs/api-v1/customers
[rc: api v2]: https://www.revenuecat.com/docs/api-v2
[rc: api v2 customer]: https://www.revenuecat.com/docs/api-v2/customer/resources
[rc: webhooks]: https://www.revenuecat.com/docs/integrations/webhooks
[rc: app privacy]: https://www.revenuecat.com/docs/platform-resources/apple-platform-resources/apple-app-privacy
[rc: data and compliance]: https://www.revenuecat.com/docs/welcome/set-up-revenuecat/data-and-compliance
[rc: dpa]: https://www.revenuecat.com/dpa
[rc: privacy policy]: https://www.revenuecat.com/privacy
[rc: pricing]: https://www.revenuecat.com/pricing/
[rc: test store]: https://www.revenuecat.com/docs/test-and-launch/sandbox/test-store
[rc: sandbox access]: https://www.revenuecat.com/docs/projects/sandbox-access
[rc: apple sandbox]: https://www.revenuecat.com/docs/test-and-launch/sandbox/apple-app-store
[rc: ios 18.4 simulator]: https://www.revenuecat.com/docs/known-store-issues/storekit/ios-18-4-simulator-fails-to-load-products
[rc: rejections]: https://www.revenuecat.com/docs/test-and-launch/app-store-rejections
[pub: purchases_flutter]: https://pub.dev/packages/purchases_flutter
[pub: purchases_ui_flutter]: https://pub.dev/packages/purchases_ui_flutter
[gh: flutter releases]: https://github.com/RevenueCat/purchases-flutter/releases
[gh: flutter changelog]: https://github.com/RevenueCat/purchases-flutter/blob/main/CHANGELOG.md
[gh: pubspec]: https://github.com/RevenueCat/purchases-flutter/blob/11.0.3/pubspec.yaml
[gh: flutter ios Package.swift]: https://github.com/RevenueCat/purchases-flutter/blob/11.0.3/ios/purchases_flutter/Package.swift
[gh: PurchasesConfiguration]: https://github.com/RevenueCat/purchases-flutter/blob/11.0.3/lib/models/purchases_configuration.dart
[gh: purchases_flutter.dart]: https://github.com/RevenueCat/purchases-flutter/blob/11.0.3/lib/purchases_flutter.dart
[gh: store_transaction.dart]: https://github.com/RevenueCat/purchases-flutter/blob/11.0.3/lib/models/store_transaction.dart
[gh: ui lib]: https://github.com/RevenueCat/purchases-flutter/tree/11.0.3/purchases_ui_flutter/lib
[gh: ui plugin swift]: https://github.com/RevenueCat/purchases-flutter/blob/11.0.3/purchases_ui_flutter/ios/purchases_ui_flutter/Sources/purchases_ui_flutter/PurchasesUiFlutterPlugin.swift
[gh: PHC Package.swift]: https://github.com/RevenueCat/purchases-hybrid-common/blob/20.9.0/Package.swift
[gh: PrivacyInfo phc]: https://github.com/RevenueCat/purchases-hybrid-common/blob/20.9.0/ios/PurchasesHybridCommon/PurchasesHybridCommon/PrivacyInfo.xcprivacy
[gh: PrivacyInfo ios]: https://github.com/RevenueCat/purchases-ios/blob/5.103.0/Sources/PrivacyInfo.xcprivacy
[gh: StoreKitVersion.swift]: https://github.com/RevenueCat/purchases-ios/blob/5.103.0/Sources/Misc/StoreKitVersion.swift
[gh: HTTPClient.swift]: https://github.com/RevenueCat/purchases-ios/blob/5.103.0/Sources/Networking/HTTPClient/HTTPClient.swift
[gh: AttributionFetcher.swift]: https://github.com/RevenueCat/purchases-ios/blob/5.103.0/Sources/Attribution/AttributionFetcher.swift
[gh: PurchasesOrchestrator]: https://github.com/RevenueCat/purchases-ios/blob/5.103.0/Sources/Purchasing/Purchases/PurchasesOrchestrator.swift
[gh: flutter issues]: https://github.com/RevenueCat/purchases-flutter/issues
[gh: issue 2014]: https://github.com/RevenueCat/purchases-flutter/issues/2014
[gh: issue 1735]: https://github.com/RevenueCat/purchases-flutter/issues/1735
[gh: issue 1192]: https://github.com/RevenueCat/purchases-flutter/issues/1192
[gh: issue 1161]: https://github.com/RevenueCat/purchases-flutter/issues/1161
[gh: apple server library]: https://github.com/apple/app-store-server-library-node
[apple: guidelines]: https://developer.apple.com/app-store/review/guidelines/
[apple: dpla]: https://developer.apple.com/support/terms/apple-developer-program-license-agreement/
[apple: subscriptions]: https://developer.apple.com/app-store/subscriptions/
[apple: app privacy details]: https://developer.apple.com/app-store/app-privacy-details/
[apple: app attest]: https://developer.apple.com/documentation/devicecheck/establishing-your-app-s-integrity
[apple: currentEntitlements]: https://developer.apple.com/documentation/storekit/transaction/currententitlements
[apple: jwsRepresentation]: https://developer.apple.com/documentation/storekit/verificationresult/jwsrepresentation-21vgo
[apple: JWS payload]: https://developer.apple.com/documentation/appstoreserverapi/jwstransactiondecodedpayload
[apple: subscription statuses]: https://developer.apple.com/documentation/appstoreserverapi/get-all-subscription-statuses
[apple: server api limits]: https://developer.apple.com/documentation/appstoreserverapi/identifying-rate-limits
[apple: storekit testing]: https://developer.apple.com/documentation/xcode/setting-up-storekit-testing-in-xcode
[apple: testflight subscriptions]: https://developer.apple.com/help/app-store-connect/test-a-beta-version/testing-subscriptions-and-in-app-purchases-in-testflight/
[flutter: spm plugin authors]: https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-plugin-authors
