import 'package:flutter/foundation.dart';

/// The ids Steady's subscription is set up with in App Store Connect and
/// RevenueCat (#180). The StoreKit configuration file
/// (`app/ios/Products.storekit`) uses the same product ids; change all
/// three together.
abstract final class SteadySubscriptionIds {
  /// RevenueCat's entitlement the coach checks. Both products grant it.
  static const entitlement = 'coach';

  /// The monthly product ($4.99 a month).
  static const monthlyProduct = 'steady_monthly';

  /// The yearly product ($39.99 a year).
  static const yearlyProduct = 'steady_yearly';
}

/// How this build talks to RevenueCat: its public Apple SDK key, from
/// `--dart-define=REVENUECAT_API_KEY`, one per build type (#180). Never in
/// the repo. A public SDK key is meant to ship inside the app; it's kept
/// out of the repo so each build type picks its own.
@immutable
class RevenueCatConfig {
  /// Creates a config with [apiKey].
  const RevenueCatConfig({required this.apiKey});

  /// The public SDK key: `appl_…` for the App Store and sandbox, or a
  /// `test_…` Test Store key in debug builds.
  final String apiKey;

  /// The key from `--dart-define=REVENUECAT_API_KEY`, or `null` when this
  /// build has none it can use (see [fromKey]).
  static RevenueCatConfig? fromEnvironment() =>
      fromKey(const String.fromEnvironment('REVENUECAT_API_KEY'));

  /// A config for [key], or `null` when it can't be used in this build:
  /// blank, or a Test Store key (`test_…`) outside a debug build.
  /// RevenueCat's SDK crashes a release build configured with a Test Store
  /// key on purpose, TestFlight included, so such a build gets no purchases
  /// instead of a crash. [debugBuild] defaults to [kDebugMode]; tests set it.
  static RevenueCatConfig? fromKey(String key, {bool debugBuild = kDebugMode}) {
    final trimmed = key.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('test_') && !debugBuild) return null;
    return RevenueCatConfig(apiKey: trimmed);
  }
}
