import 'package:failures/failures.dart';
import 'package:flutter/services.dart';
import 'package:health_sync_data/src/health_kit_wire.dart';
import 'package:health_sync_domain/health_sync_domain.dart';

/// [HealthKitRepository] backed by the `steady/healthkit` platform channel
/// ([HealthKitChannel]), iOS only.
///
/// The native side lives runner-adjacent, not in a separate plugin
/// (CLAUDE.md §8): `app/ios/Runner/HealthKitChannel.swift`. macOS has no
/// handler, so every call there would be a [MissingPluginException]; the
/// app doesn't bind this repository on macOS at all.
///
/// Every platform error becomes a typed [Failure] here, so the UI never
/// sees a raw [PlatformException] (CLAUDE.md §9): [PlatformException] and
/// [MissingPluginException] become a [PlatformChannelFailure], a reply in
/// the wrong shape (a [FormatException], or a [TypeError] from a cast) and
/// any other exception an [UnknownFailure].
class MethodChannelHealthKitRepository implements HealthKitRepository {
  /// Creates the repository. [channel] is for tests; the default is the
  /// real `steady/healthkit` channel.
  MethodChannelHealthKitRepository({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(HealthKitChannel.name);

  final MethodChannel _channel;

  @override
  ResultFuture<bool> isAvailable() =>
      _call('Could not check whether Apple Health is available', () async {
        final raw = await _channel.invokeMethod<Object?>(
          HealthKitChannel.isAvailableMethod,
        );
        if (raw is! bool) throw FormatException('Expected a bool', raw);
        return raw;
      });

  @override
  ResultFuture<HealthAuthorizationStatus> authorizationStatus() => _call(
    'Could not read the Apple Health permission status',
    () async => healthAuthorizationStatusFromWire(
      await _channel.invokeMethod<Object?>(
        HealthKitChannel.authorizationStatusMethod,
      ),
    ),
  );

  @override
  ResultFuture<Unit> requestAuthorization() =>
      _call('Could not ask for Apple Health access', () async {
        await _channel.invokeMethod<void>(
          HealthKitChannel.requestAuthorizationMethod,
        );
        return unit;
      });

  @override
  ResultFuture<List<HealthDayTotals>> dailyTotals(
    DateTime start,
    DateTime end,
  ) async {
    // Local calendar days, even for a UTC DateTime (the wire contract).
    final first = healthLocalDay(start);
    final last = healthLocalDay(end);
    if (!isSupportedHealthDate(first) || !isSupportedHealthDate(last)) {
      return const Err(
        ValidationFailure('start and end must be in the years 0000 to 9999'),
      );
    }
    if (first.isAfter(last)) {
      return const Err(ValidationFailure('start must not be after end'));
    }
    return await _call(
      'Could not read daily totals from Apple Health',
      () async => healthDayTotalsFromWire(
        await _channel.invokeMethod<Object?>(
          HealthKitChannel.dailyTotalsMethod,
          {'start': formatHealthDate(first), 'end': formatHealthDate(last)},
        ),
      ),
    );
  }

  @override
  ResultFuture<WeightUnit> preferredWeightUnit() => _call(
    'Could not read the weight unit from Apple Health',
    () async => weightUnitFromWire(
      await _channel.invokeMethod<Object?>(
        HealthKitChannel.preferredWeightUnitMethod,
      ),
    ),
  );

  /// Runs [body], mapping every exception to a [Failure] described by
  /// [what].
  Future<Result<T>> _call<T>(String what, Future<T> Function() body) async {
    try {
      return Ok(await body());
    } on PlatformException catch (e) {
      return Err(
        PlatformChannelFailure(e.message ?? what, code: e.code, cause: e),
      );
    } on MissingPluginException catch (e) {
      return Err(
        PlatformChannelFailure(
          'Apple Health is not available on this platform',
          code: 'missingPlugin',
          cause: e,
        ),
      );
    } on FormatException catch (e) {
      return Err(UnknownFailure('$what: unexpected reply', cause: e));
    } on Object catch (e) {
      // A `TypeError` from a cast in the reply's shape, or anything else
      // the channel throws: never let it escape the `Result`.
      return Err(UnknownFailure(what, cause: e));
    }
  }
}
