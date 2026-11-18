// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'about_me_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Settings → About me (#172): every onboarding answer, each editable on
/// its own, over the stored `OnboardingRecord`.
///
/// `build` reads the record. An unreadable one (`OnboardingUnreadableFailure`)
/// opens with nothing answered, since the next save replaces it
/// (`OnboardingRepository`); any other failed read is an `AsyncError`
/// carrying the `Failure`, and the screen offers to try again.
///
/// **Every event shows at once and saves behind it**, through
/// `saveAboutMe`, which never changes whether onboarding is done. Clearing
/// an answer (`null`, or an empty set) puts it back to skipped. Saves
/// never overlap and always write the latest answers: an edit made while
/// one is being written is saved right after it, together with any other
/// edits made meanwhile (a note typed letter by letter is a few writes,
/// not one per letter). A failed save sets
/// [AboutMeEditorState.saveFailure] and keeps the edit on screen; the next
/// edit's save, if it works, clears it.
///
/// Each event's future completes once a save holding that edit has
/// finished, whether it worked or not, so the caller can refresh what
/// reads the record (Today's tracking).
///
/// Auto-dispose: screen-scoped. Saves still to run when the screen goes
/// run anyway (only the state updates are dropped), so leaving right after
/// an edit doesn't lose it.

@ProviderFor(AboutMeController)
final aboutMeControllerProvider = AboutMeControllerProvider._();

/// Settings → About me (#172): every onboarding answer, each editable on
/// its own, over the stored `OnboardingRecord`.
///
/// `build` reads the record. An unreadable one (`OnboardingUnreadableFailure`)
/// opens with nothing answered, since the next save replaces it
/// (`OnboardingRepository`); any other failed read is an `AsyncError`
/// carrying the `Failure`, and the screen offers to try again.
///
/// **Every event shows at once and saves behind it**, through
/// `saveAboutMe`, which never changes whether onboarding is done. Clearing
/// an answer (`null`, or an empty set) puts it back to skipped. Saves
/// never overlap and always write the latest answers: an edit made while
/// one is being written is saved right after it, together with any other
/// edits made meanwhile (a note typed letter by letter is a few writes,
/// not one per letter). A failed save sets
/// [AboutMeEditorState.saveFailure] and keeps the edit on screen; the next
/// edit's save, if it works, clears it.
///
/// Each event's future completes once a save holding that edit has
/// finished, whether it worked or not, so the caller can refresh what
/// reads the record (Today's tracking).
///
/// Auto-dispose: screen-scoped. Saves still to run when the screen goes
/// run anyway (only the state updates are dropped), so leaving right after
/// an edit doesn't lose it.
final class AboutMeControllerProvider
    extends $AsyncNotifierProvider<AboutMeController, AboutMeEditorState> {
  /// Settings → About me (#172): every onboarding answer, each editable on
  /// its own, over the stored `OnboardingRecord`.
  ///
  /// `build` reads the record. An unreadable one (`OnboardingUnreadableFailure`)
  /// opens with nothing answered, since the next save replaces it
  /// (`OnboardingRepository`); any other failed read is an `AsyncError`
  /// carrying the `Failure`, and the screen offers to try again.
  ///
  /// **Every event shows at once and saves behind it**, through
  /// `saveAboutMe`, which never changes whether onboarding is done. Clearing
  /// an answer (`null`, or an empty set) puts it back to skipped. Saves
  /// never overlap and always write the latest answers: an edit made while
  /// one is being written is saved right after it, together with any other
  /// edits made meanwhile (a note typed letter by letter is a few writes,
  /// not one per letter). A failed save sets
  /// [AboutMeEditorState.saveFailure] and keeps the edit on screen; the next
  /// edit's save, if it works, clears it.
  ///
  /// Each event's future completes once a save holding that edit has
  /// finished, whether it worked or not, so the caller can refresh what
  /// reads the record (Today's tracking).
  ///
  /// Auto-dispose: screen-scoped. Saves still to run when the screen goes
  /// run anyway (only the state updates are dropped), so leaving right after
  /// an edit doesn't lose it.
  AboutMeControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: retryUnlessFailure,
        name: r'aboutMeControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aboutMeControllerHash();

  @$internal
  @override
  AboutMeController create() => AboutMeController();
}

String _$aboutMeControllerHash() => r'59aa559201c018c41688e1cb63e8f90dd715974b';

/// Settings → About me (#172): every onboarding answer, each editable on
/// its own, over the stored `OnboardingRecord`.
///
/// `build` reads the record. An unreadable one (`OnboardingUnreadableFailure`)
/// opens with nothing answered, since the next save replaces it
/// (`OnboardingRepository`); any other failed read is an `AsyncError`
/// carrying the `Failure`, and the screen offers to try again.
///
/// **Every event shows at once and saves behind it**, through
/// `saveAboutMe`, which never changes whether onboarding is done. Clearing
/// an answer (`null`, or an empty set) puts it back to skipped. Saves
/// never overlap and always write the latest answers: an edit made while
/// one is being written is saved right after it, together with any other
/// edits made meanwhile (a note typed letter by letter is a few writes,
/// not one per letter). A failed save sets
/// [AboutMeEditorState.saveFailure] and keeps the edit on screen; the next
/// edit's save, if it works, clears it.
///
/// Each event's future completes once a save holding that edit has
/// finished, whether it worked or not, so the caller can refresh what
/// reads the record (Today's tracking).
///
/// Auto-dispose: screen-scoped. Saves still to run when the screen goes
/// run anyway (only the state updates are dropped), so leaving right after
/// an edit doesn't lose it.

abstract class _$AboutMeController extends $AsyncNotifier<AboutMeEditorState> {
  FutureOr<AboutMeEditorState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<AboutMeEditorState>, AboutMeEditorState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AboutMeEditorState>, AboutMeEditorState>,
              AsyncValue<AboutMeEditorState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
