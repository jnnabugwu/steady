import 'dart:math';

import 'package:cravings_domain/cravings_domain.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:url_launcher/url_launcher.dart';

part 'providers.g.dart';

/// The `CravingRepository` craving check-ins are stored through.
///
/// Typed against the domain interface only: this package never depends on
/// `cravings_data` (CLAUDE.md §3). `app/lib/providers.dart` binds it on iOS
/// only, to the device-only file store; on macOS it stays unbound, so a Mac
/// path that reads it fails loudly instead of quietly creating a store.
/// Tests override it with a fake. Reading it without an override throws.
///
/// `keepAlive`: repositories are cheap and stateless (D6).
@Riverpod(keepAlive: true)
CravingRepository cravingRepository(Ref ref) =>
    throw UnimplementedError('Override cravingRepositoryProvider in app/');

/// Whether craving support is offered on this device: `true` on iOS only.
///
/// `false` by default; `app/lib/providers.dart` sets it from the platform
/// (`appProviderOverridesFor(isIOS: ...)`), so tests can cover both. When
/// it's `false` the home entry point and the Settings card render nothing,
/// and the app's `/craving` route sends you home.
///
/// `keepAlive`: a constant for the app's lifetime.
@Riverpod(keepAlive: true)
bool cravingSupportAvailable(Ref ref) => false;

/// The current time, as the flow and the weekly summary read it.
typedef CravingClock = DateTime Function();

/// The clock the craving feature reads "now" from. Defaults to
/// [DateTime.now]; tests pin it.
///
/// `keepAlive`: cheap and stateless (D6).
@Riverpod(keepAlive: true)
CravingClock cravingClock(Ref ref) => DateTime.now;

/// Makes a new, unique craving event id.
typedef CravingIdGenerator = String Function();

/// The id generator for new craving events: a random (version 4) UUID by
/// default ([randomCravingId]); tests pin it.
///
/// `keepAlive`: cheap and stateless (D6).
@Riverpod(keepAlive: true)
CravingIdGenerator cravingIdGenerator(Ref ref) => randomCravingId;

final Random _random = Random.secure();

/// A random version 4 UUID, e.g. `3f2b8c1e-9a4d-4c7e-8b21-5d0f6a7e9c13`.
String randomCravingId() {
  final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // RFC 4122 variant
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// Opens an external link (the Settings card's help resource). Returns
/// whether it opened.
typedef CravingLinkOpener = Future<bool> Function(Uri uri);

/// How the Settings card opens its help link. Defaults to the system
/// browser through `url_launcher`; tests override it so they never reach
/// the plugin.
///
/// `keepAlive`: cheap and stateless (D6).
@Riverpod(keepAlive: true)
CravingLinkOpener cravingLinkOpener(Ref ref) =>
    (uri) => launchUrl(uri, mode: LaunchMode.externalApplication);
