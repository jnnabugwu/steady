import 'package:checkin_presentation/checkin_presentation.dart';
import 'package:coach_data/coach_data.dart';
import 'package:coach_domain/coach_domain.dart';
import 'package:coach_presentation/coach_presentation.dart';
import 'package:cravings_presentation/cravings_presentation.dart';
import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderException;
import 'package:flutter_test/flutter_test.dart';
import 'package:metrics_presentation/metrics_presentation.dart';
import 'package:steady/providers.dart';

/// The coach is iPhone only (CLAUDE.md §11): the real override list binds
/// its model on iOS and nothing on macOS.
void main() {
  test('iOS binds the coach model to the hosted proxy', () {
    final ios = ProviderContainer.test(
      overrides: appProviderOverridesFor(isIOS: true),
    );
    expect(ios.read(coachModelProvider), isA<HostedCoachModel>());
  });

  test('iOS keeps consent in the device-only file store; macOS binds none', () {
    final ios = ProviderContainer.test(
      overrides: appProviderOverridesFor(isIOS: true),
    );
    expect(
      ios.read(coachConsentRepositoryProvider),
      isA<FileCoachConsentRepository>(),
    );
    final mac = ProviderContainer.test(
      overrides: appProviderOverridesFor(isIOS: false),
    );
    expect(mac.read(coachConsentRepositoryProvider), isNull);
  });

  test('the real wiring sends nothing without consent: a store with no '
      'agreement (here, one that has no file to read) is not given', () async {
    final ios = ProviderContainer.test(
      overrides: appProviderOverridesFor(isIOS: true),
    );
    expect(await ios.read(coachConsentGivenProvider.future), isFalse);
    final reply = await ios
        .read(coachModelProvider)
        .reply(
          const CoachRequest(
            kind: CoachRequestKind.chat,
            weekContext: 'week',
            turns: [CoachTurn.person('Hi')],
          ),
        )
        .single;
    expect(
      reply,
      isA<Err<CoachReplySnapshot>>().having(
        (e) => e.failure,
        'failure',
        isA<CoachConsentNotGivenFailure>(),
      ),
    );
    await expectLater(
      ios.read(coachAvailabilityProvider.future),
      throwsA(isA<CoachConsentNotGivenFailure>()),
    );
  });

  test('the hosted model signs with the App Attest channel and the '
      'device-only key file', () {
    final ios = ProviderContainer.test(
      overrides: appProviderOverridesFor(isIOS: true),
    );
    expect(ios.read(coachAppAttestProvider), isA<MethodChannelAppAttest>());
    expect(
      ios.read(coachAppAttestKeyStoreProvider),
      isA<FileAppAttestKeyStore>(),
    );
  });

  test('a build without COACH_PROXY_URL (this test run) says the coach is '
      'off', () async {
    final ios = ProviderContainer.test(
      overrides: appProviderOverridesFor(isIOS: true),
    );
    // The model's own local check, the one `coachAvailability` runs once
    // consent is given.
    expect(
      await ios.read(coachModelProvider).checkAvailability(),
      isA<Err<Unit>>().having(
        (e) => e.failure,
        'failure',
        isA<CoachTurnedOffFailure>(),
      ),
    );
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

  test('macOS binds no App Attest', () {
    final mac = ProviderContainer.test(
      overrides: appProviderOverridesFor(isIOS: false),
    );
    expect(
      () => mac.read(coachAppAttestProvider),
      throwsA(isA<ProviderException>()),
    );
    expect(
      () => mac.read(coachAppAttestKeyStoreProvider),
      throwsA(isA<ProviderException>()),
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
