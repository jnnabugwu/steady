/// Onboarding's data layer: `FileOnboardingRepository`, a JSON file on this
/// iPhone only (`onboarding.json`). Never SwiftData or CloudKit, never
/// synced (CLAUDE.md §7).
///
/// `package:onboarding_data/testing/onboarding_repository_contract.dart` is
/// the behaviour every `OnboardingRepository` shares; this package runs it
/// against the file store and the domain's in-memory one.
library;

export 'src/file_onboarding_repository.dart';
export 'src/onboarding_json.dart'
    show
        decodeOnboardingFile,
        encodeAboutMe,
        encodeOnboardingFile,
        onboardingSchemaVersion;
