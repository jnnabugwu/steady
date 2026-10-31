/// Usage sharing: anonymous usage events sent to PostHog, from TestFlight
/// builds only.
///
/// **What's sent** is the fixed list in `AnalyticsEvent`
/// (`packages/shared/analytics`): a name and a few labels, yes/nos or
/// counts. Never a Health value, a calorie number, a craving, a coach
/// message or anything typed (App Store 5.1.3, `docs/PRIVACY.md`). PostHog
/// also records the app's own lifecycle events (installed, opened,
/// backgrounded), each with the app version and device model. No session
/// replay, no autocaptured taps, no person profiles, nothing identifying:
/// [PosthogFlutterClient] turns each of those off explicitly.
///
/// **Where it runs.** Only when all of these hold:
/// - the build has a PostHog project key ([postHogKey], passed with
///   `--dart-define=POSTHOG_KEY=...` by `scripts/build-ios-ipa.sh`, so it's
///   never in the repo), and it's iOS;
/// - this install came from TestFlight, or is a debug build
///   ([InstallSource], asked at runtime over `steady/install`, since the
///   same binary can go on to the App Store, where nothing is ever sent);
/// - the person hasn't turned it off in Settings (`UsageSharingCard`).
///
/// The SDK is set up by hand, here, never at launch by the plugin:
/// Info.plist sets `com.posthog.posthog.AUTO_INIT` and
/// `com.posthog.posthog.CAPTURE_PUSH_NOTIFICATION_OPENED` to `false`.
library;

import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:analytics/analytics.dart';
import 'package:coach_domain/coach_domain.dart';
import 'package:failures/failures.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'usage_sharing.g.dart';

/// The PostHog project key, from `--dart-define=POSTHOG_KEY=phc_...`.
/// Empty, the default, sends nothing.
const postHogKey = String.fromEnvironment('POSTHOG_KEY');

/// The PostHog ingestion host, from `--dart-define=POSTHOG_HOST=...`:
/// `https://us.i.posthog.com` or `https://eu.i.posthog.com`.
const postHogHost = String.fromEnvironment(
  'POSTHOG_HOST',
  defaultValue: 'https://us.i.posthog.com',
);

/// Where this copy of Steady was installed from.
enum InstallSource {
  /// TestFlight: usage sharing is offered.
  testFlight,

  /// The App Store: nothing is ever sent.
  appStore,

  /// A debug build: offered, so events can be checked before a TestFlight
  /// upload (only with a key passed in by hand).
  development,

  /// Couldn't tell: nothing is sent.
  unknown,
}

/// Reads [InstallSource].
abstract interface class InstallSourceReader {
  /// Where this copy was installed from. Never throws: [InstallSource.unknown]
  /// on any error.
  Future<InstallSource> read();
}

/// [InstallSourceReader] over the `steady/install` channel
/// (`ios/Runner/AppDelegate.swift`).
final class MethodChannelInstallSource implements InstallSourceReader {
  /// Creates the reader.
  const MethodChannelInstallSource();

  static const _channel = MethodChannel('steady/install');

  @override
  Future<InstallSource> read() async {
    try {
      final source = await _channel.invokeMethod<String>('source');
      return InstallSource.values.asNameMap()[source] ?? InstallSource.unknown;
    } on Object {
      return InstallSource.unknown;
    }
  }
}

/// Whether the person turned usage sharing off.
abstract interface class UsageSharingStore {
  /// Whether it's off. Never throws: `false` when it can't be read.
  Future<bool> isOff();

  /// Remembers [off]. Throws if it can't be saved.
  Future<void> setOff({required bool off});
}

/// [UsageSharingStore] as a marker file in the application support
/// directory: present means off. On the device only, like the cravings
/// file.
final class FileUsageSharingStore implements UsageSharingStore {
  /// Creates the store over the file [locate] returns.
  const FileUsageSharingStore(this.locate);

  /// Finds the marker file, on first use.
  final Future<File> Function() locate;

  @override
  Future<bool> isOff() async {
    try {
      return (await locate()).existsSync();
    } on Object {
      return false;
    }
  }

  @override
  Future<void> setOff({required bool off}) async {
    final file = await locate();
    if (off) {
      await file.writeAsString('off');
    } else if (file.existsSync()) {
      await file.delete();
    }
  }
}

/// The marker file: `usage_sharing_off` in the application support
/// directory.
Future<File> usageSharingFile() async =>
    File('${(await getApplicationSupportDirectory()).path}/usage_sharing_off');

/// The calls [PostHogAnalytics] makes on the PostHog SDK.
abstract interface class PostHogClient {
  /// Sets the SDK up, opted out when [optOut].
  Future<void> setup({required bool optOut});

  /// Sends one event.
  Future<void> capture(String name, Map<String, Object> properties);

  /// Starts sending again.
  Future<void> optIn();

  /// Stops sending, including the lifecycle events.
  Future<void> optOut();
}

/// [PostHogClient] on `posthog_flutter`, with everything Steady doesn't use
/// turned off.
final class PosthogFlutterClient implements PostHogClient {
  /// Creates the client for project [key] at [host].
  const PosthogFlutterClient({required this.key, required this.host});

  /// The project key.
  final String key;

  /// The ingestion host.
  final String host;

  @override
  Future<void> setup({required bool optOut}) {
    final config = PostHogConfig(key)
      ..host = host
      ..optOut = optOut
      // Anonymous: a random id per install, and no person profiles.
      ..personProfiles = PostHogPersonProfiles.never
      // Installed / opened / backgrounded, for first opens and retention.
      ..captureApplicationLifecycleEvents = true
      // Off: the screens show Health values, cravings and coach messages.
      ..sessionReplay = false
      ..surveys = false
      ..preloadFeatureFlags = false
      ..sendFeatureFlagEvent = false
      ..capturePushNotificationSubscriptions = false
      ..capturePushNotificationOpened = false;
    config.rageClickConfig.enabled = false;
    return Posthog().setup(config);
  }

  @override
  Future<void> capture(String name, Map<String, Object> properties) =>
      Posthog().capture(eventName: name, properties: properties);

  @override
  Future<void> optIn() => Posthog().optIn();

  @override
  Future<void> optOut() => Posthog().optOut();
}

/// Whether usage sharing applies to this install and, if so, whether it's
/// on.
enum UsageSharingStatus {
  /// Not this build or install: nothing is sent, and Settings says nothing.
  notOffered,

  /// Sending.
  on,

  /// Offered, but turned off in Settings.
  off,
}

/// The app's [Analytics] on a TestFlight build: sends each event to PostHog
/// while usage sharing is on.
///
/// [status] starts it: it reads where the app was installed from and the
/// Settings switch, then sets PostHog up (opted out if the switch is off).
/// Events recorded before that finishes wait, up to [_maxPending], and are
/// sent or dropped once it does.
final class PostHogAnalytics implements Analytics {
  /// Creates the sink. Nothing happens until [status] is first read.
  PostHogAnalytics({
    required this._client,
    required this._installSource,
    required this._store,
  });

  final PostHogClient _client;
  final InstallSourceReader _installSource;
  final UsageSharingStore _store;

  static const _maxPending = 50;
  final _pending = <AnalyticsEvent>[];
  UsageSharingStatus? _current;

  /// Whether sharing is offered here and on. Starts PostHog on first read.
  late final Future<UsageSharingStatus> status = _start();

  Future<UsageSharingStatus> _start() async {
    var status = UsageSharingStatus.notOffered;
    try {
      final source = await _installSource.read();
      if (source == InstallSource.testFlight ||
          source == InstallSource.development) {
        final off = await _store.isOff();
        await _client.setup(optOut: off);
        status = off ? UsageSharingStatus.off : UsageSharingStatus.on;
      }
    } on Object catch (error, stackTrace) {
      _log('Usage sharing setup failed', error, stackTrace);
    }
    _current = status;
    final pending = [..._pending];
    _pending.clear();
    if (status == UsageSharingStatus.on) pending.forEach(_send);
    return status;
  }

  @override
  void record(AnalyticsEvent event) {
    switch (_current) {
      case null:
        if (_pending.length < _maxPending) _pending.add(event);
      case UsageSharingStatus.on:
        _send(event);
      case UsageSharingStatus.off || UsageSharingStatus.notOffered:
        break;
    }
  }

  /// Turns sharing on or off and remembers it. Returns the new status;
  /// [UsageSharingStatus.notOffered] stays as it is. Throws if the choice
  /// can't be saved, leaving sharing as it was.
  Future<UsageSharingStatus> share({required bool on}) async {
    if (await status == UsageSharingStatus.notOffered) {
      return UsageSharingStatus.notOffered;
    }
    await _store.setOff(off: !on);
    // Stop locally first, so nothing more goes out even if the SDK call
    // fails.
    _current = on ? UsageSharingStatus.on : UsageSharingStatus.off;
    await (on ? _client.optIn() : _client.optOut());
    return _current!;
  }

  void _send(AnalyticsEvent event) {
    unawaited(
      _client
          .capture(event.name, event.properties)
          .catchError(
            (Object error, StackTrace stackTrace) =>
                _log('Sending ${event.name} failed', error, stackTrace),
          ),
    );
  }

  static void _log(String message, Object error, StackTrace stackTrace) =>
      developer.log(
        message,
        name: 'steady.usage',
        error: error,
        stackTrace: stackTrace,
      );
}

/// The app's [PostHogAnalytics], or `null` where there's none: no key, not
/// iOS, and tests. `main.dart` overrides it; `providers.dart` binds
/// `analyticsProvider` to it.
///
/// `keepAlive`: app-scoped, it holds the SDK's state (CLAUDE.md §4).
@Riverpod(keepAlive: true)
PostHogAnalytics? postHogAnalytics(Ref ref) => null;

/// Settings' usage-sharing switch.
///
/// `keepAlive`: app-scoped and cheap; the switch shows the same state on
/// every visit to Settings.
@Riverpod(keepAlive: true)
class UsageSharingController extends _$UsageSharingController {
  @override
  Future<UsageSharingStatus> build() async =>
      await ref.watch(postHogAnalyticsProvider)?.status ??
      UsageSharingStatus.notOffered;

  /// Domain event: UsageSharingTurnedOn.
  ///
  /// Both events end in `AsyncData` with the new status, or in an
  /// `AsyncError` carrying a [Failure] whose `value` is still the old
  /// status (the setter carries it over), so the switch stays put. Ignored
  /// while a change is in flight, and where sharing isn't offered.
  Future<void> turnOnUsageSharing() => _share(on: true);

  /// Domain event: UsageSharingTurnedOff.
  Future<void> turnOffUsageSharing() => _share(on: false);

  Future<void> _share({required bool on}) async {
    final analytics = ref.read(postHogAnalyticsProvider);
    if (analytics == null || !ref.mounted || state.isLoading) return;
    state = const AsyncLoading<UsageSharingStatus>();
    try {
      final status = await analytics.share(on: on);
      if (ref.mounted) state = AsyncData(status);
    } on Object catch (error) {
      if (!ref.mounted) return;
      state = AsyncError<UsageSharingStatus>(
        error is Failure
            ? error
            : UnknownFailure("Couldn't save that setting.", cause: error),
        StackTrace.current,
      );
    }
  }
}

/// [CoachAvailabilityReason] for the coach model's availability check.
CoachAvailabilityReason coachAvailabilityReason(
  Result<CoachModelInfo> result,
) => switch (result) {
  Ok() => CoachAvailabilityReason.available,
  Err(failure: CoachDeviceNotEligibleFailure()) =>
    CoachAvailabilityReason.deviceNotEligible,
  Err(failure: CoachAppleIntelligenceNotEnabledFailure()) =>
    CoachAvailabilityReason.appleIntelligenceNotEnabled,
  Err(failure: CoachModelNotReadyFailure()) =>
    CoachAvailabilityReason.modelNotReady,
  Err(failure: CoachOsTooOldFailure()) => CoachAvailabilityReason.osTooOld,
  Err() => CoachAvailabilityReason.unknown,
};
