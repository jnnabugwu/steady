import 'package:checkin_presentation/checkin_presentation.dart';
import 'package:coach_data/coach_data.dart';
import 'package:coach_presentation/coach_presentation.dart';
import 'package:cravings_presentation/cravings_presentation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderException;
import 'package:flutter_test/flutter_test.dart';
import 'package:metrics_presentation/metrics_presentation.dart';
import 'package:steady/providers.dart';

/// The coach is iPhone only (#79, CLAUDE.md §11): the real override list
/// binds its model on iOS and nothing on macOS.
void main() {
  test('iOS binds the coach model to the steady/coach channel', () {
    final ios = ProviderContainer.test(
      overrides: appProviderOverridesFor(isIOS: true),
    );
    expect(ios.read(coachModelProvider), isA<MethodChannelCoachModel>());
  });

  test('macOS binds no coach provider', () {
    final mac = ProviderContainer.test(
      overrides: appProviderOverridesFor(isIOS: false),
    );
    expect(
      () => mac.read(coachModelProvider),
      throwsA(
        isA<ProviderException>().having(
          (e) => e.exception,
          'exception',
          isA<UnimplementedError>(),
        ),
      ),
    );
  });

  test("iOS binds the coach's context to each feature's own repository, "
      'never a second instance (the shared-store invariant)', () {
    final ios = ProviderContainer.test(
      overrides: appProviderOverridesFor(isIOS: true),
    );
    expect(
      ios.read(coachCheckInRepositoryProvider),
      same(ios.read(checkInRepositoryProvider)),
    );
    expect(
      ios.read(coachMetricsRepositoryProvider),
      same(ios.read(metricsRepositoryProvider)),
    );
    expect(
      ios.read(coachCravingRepositoryProvider),
      same(ios.read(cravingRepositoryProvider)),
    );
    expect(ios.read(coachHealthKitRepositoryProvider), isNotNull);
    expect(
      ios.read(coachHealthKitRepositoryProvider),
      same(ios.read(healthKitRepositoryProvider)),
    );
  });

  test("macOS leaves the coach's context unbound", () {
    final mac = ProviderContainer.test(
      overrides: appProviderOverridesFor(isIOS: false),
    );
    expect(mac.read(coachHealthKitRepositoryProvider), isNull);
    expect(mac.read(coachCravingRepositoryProvider), isNull);
    expect(
      () => mac.read(coachCheckInRepositoryProvider),
      throwsA(isA<ProviderException>()),
    );
  });

  test('no override in the macOS list touches a coach provider', () {
    // Every coach provider comes from `coach_presentation`; none may appear
    // in the Mac list, not even one bound to a stub.
    final coachOverrides = appProviderOverridesFor(
      isIOS: false,
    ).where((override) => override.toString().toLowerCase().contains('coach'));
    expect(coachOverrides, isEmpty);
    expect(
      appProviderOverridesFor(isIOS: true)
          .where((o) => o.toString().toLowerCase().contains('coach')),
      isNotEmpty,
      reason: 'the check above has to be able to see a coach override',
    );
  });
}
