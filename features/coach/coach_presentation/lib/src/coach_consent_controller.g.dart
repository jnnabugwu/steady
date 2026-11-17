// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coach_consent_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the person has agreed to what the coach sends, to whom and for
/// what, in the **current** version of the consent text
/// ([CoachConsent.currentVersion]; App Store 5.1.2). An agreement to an
/// earlier version doesn't count, so a bumped version asks again.
///
/// **Nothing reaches the proxy unless this is a settled `true`**
/// ([isCoachConsentGiven]): the coach screens check it before they offer a
/// session (`coachAvailability`, `CoachSessionController`), the session
/// checks it before every request and stops a reply in flight when it turns
/// `false`, and the hosted model checks it again before every request
/// (`app/lib/providers.dart` binds its `consentGiven` to this provider).
///
/// Read from [coachConsentRepositoryProvider], the device-only store; with
/// none bound (the Mac, a test), not given.
///
/// `keepAlive`: the one answer for the whole app, which every coach screen
/// and the model read.

@ProviderFor(CoachConsentGiven)
final coachConsentGivenProvider = CoachConsentGivenProvider._();

/// Whether the person has agreed to what the coach sends, to whom and for
/// what, in the **current** version of the consent text
/// ([CoachConsent.currentVersion]; App Store 5.1.2). An agreement to an
/// earlier version doesn't count, so a bumped version asks again.
///
/// **Nothing reaches the proxy unless this is a settled `true`**
/// ([isCoachConsentGiven]): the coach screens check it before they offer a
/// session (`coachAvailability`, `CoachSessionController`), the session
/// checks it before every request and stops a reply in flight when it turns
/// `false`, and the hosted model checks it again before every request
/// (`app/lib/providers.dart` binds its `consentGiven` to this provider).
///
/// Read from [coachConsentRepositoryProvider], the device-only store; with
/// none bound (the Mac, a test), not given.
///
/// `keepAlive`: the one answer for the whole app, which every coach screen
/// and the model read.
final class CoachConsentGivenProvider
    extends $AsyncNotifierProvider<CoachConsentGiven, bool> {
  /// Whether the person has agreed to what the coach sends, to whom and for
  /// what, in the **current** version of the consent text
  /// ([CoachConsent.currentVersion]; App Store 5.1.2). An agreement to an
  /// earlier version doesn't count, so a bumped version asks again.
  ///
  /// **Nothing reaches the proxy unless this is a settled `true`**
  /// ([isCoachConsentGiven]): the coach screens check it before they offer a
  /// session (`coachAvailability`, `CoachSessionController`), the session
  /// checks it before every request and stops a reply in flight when it turns
  /// `false`, and the hosted model checks it again before every request
  /// (`app/lib/providers.dart` binds its `consentGiven` to this provider).
  ///
  /// Read from [coachConsentRepositoryProvider], the device-only store; with
  /// none bound (the Mac, a test), not given.
  ///
  /// `keepAlive`: the one answer for the whole app, which every coach screen
  /// and the model read.
  CoachConsentGivenProvider._()
    : super(
        from: null,
        argument: null,
        retry: _retryUnlessFailure,
        name: r'coachConsentGivenProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coachConsentGivenHash();

  @$internal
  @override
  CoachConsentGiven create() => CoachConsentGiven();
}

String _$coachConsentGivenHash() => r'278652af251d789d08631dd5e77f846b8d75b440';

/// Whether the person has agreed to what the coach sends, to whom and for
/// what, in the **current** version of the consent text
/// ([CoachConsent.currentVersion]; App Store 5.1.2). An agreement to an
/// earlier version doesn't count, so a bumped version asks again.
///
/// **Nothing reaches the proxy unless this is a settled `true`**
/// ([isCoachConsentGiven]): the coach screens check it before they offer a
/// session (`coachAvailability`, `CoachSessionController`), the session
/// checks it before every request and stops a reply in flight when it turns
/// `false`, and the hosted model checks it again before every request
/// (`app/lib/providers.dart` binds its `consentGiven` to this provider).
///
/// Read from [coachConsentRepositoryProvider], the device-only store; with
/// none bound (the Mac, a test), not given.
///
/// `keepAlive`: the one answer for the whole app, which every coach screen
/// and the model read.

abstract class _$CoachConsentGiven extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
