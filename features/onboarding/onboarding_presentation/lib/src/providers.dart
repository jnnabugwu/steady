import 'package:onboarding_domain/onboarding_domain.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

/// The `OnboardingRepository` this feature reads and writes through.
///
/// Typed against the domain interface only: this package never depends on
/// `onboarding_data` (CLAUDE.md §3). `app/lib/providers.dart` overrides it
/// with the real implementation (CLAUDE.md §9); tests override it with
/// `InMemoryOnboardingRepository`. Reading it without an override throws.
///
/// `keepAlive`: repositories are cheap and stateless, so recreating one
/// gains nothing (D6).
@Riverpod(keepAlive: true)
OnboardingRepository onboardingRepository(Ref ref) =>
    throw UnimplementedError('Override onboardingRepositoryProvider in app/');
