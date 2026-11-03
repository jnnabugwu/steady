import 'dart:async';

import 'package:coach_domain/coach_domain.dart';
import 'package:coach_presentation/src/coach_consent_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

/// The coach's consent screen (App Store 5.1.2): what the coach sends, to
/// whom (Anthropic) and why, before anything is sent. The words are
/// [CoachConsent]'s.
///
/// Shown before the first request from every way into the coach: the Coach
/// tab's "Turn on the coach", the nudge's "Talk now", a session opened
/// without consent, and the Settings switch turned on. **Nothing is sent
/// before "Allow and continue"**, which records agreement to
/// [CoachConsent.currentVersion] (`giveCoachConsent`) and then calls
/// [onConsentGiven]. **Not now** ([onNotNow], also the close button) leaves
/// the coach off and changes nothing.
///
/// Knows nothing about routing (CLAUDE.md §5): the app layer decides where
/// each answer goes. Built from `shadcn_flutter` and `ui_kit` only.
class CoachConsentModule extends ConsumerWidget {
  /// Creates the consent screen.
  const CoachConsentModule({
    required this.onConsentGiven,
    required this.onNotNow,
    super.key,
  });

  /// Called once the agreement is saved.
  final void Function() onConsentGiven;

  /// Called by "Not now" or the close button. Nothing was changed.
  final void Function() onNotNow;

  /// Keeps the text phone-width on a wide window.
  static const double maxWidth = 480;

  Future<void> _allow(WidgetRef ref) async {
    await ref.read(coachConsentGivenProvider.notifier).giveCoachConsent();
    if (!ref.context.mounted) return;
    if (isCoachConsentGiven(ref.read(coachConsentGivenProvider))) {
      onConsentGiven();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consent = ref.watch(coachConsentGivenProvider);
    final saving = consent.isLoading;

    return Scaffold(
      headers: [
        AppBar(
          leading: [
            Semantics(
              label: 'Close',
              button: true,
              child: IconButton.ghost(
                key: const Key('coachConsentClose'),
                icon: const Icon(LucideIcons.x),
                onPressed: onNotNow,
              ),
            ),
          ],
          title: const Text('Coach'),
        ),
      ],
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          key: const Key('coachConsentScroll'),
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: maxWidth),
              child: Column(
                key: const Key('coachConsentScreen'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: const Text(
                      CoachConsent.title,
                      style: SteadyType.headline,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(CoachConsent.intro, style: SteadyType.body),
                  const SizedBox(height: 12),
                  for (final item in CoachConsent.items)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 10,
                        children: [
                          const ExcludeSemantics(
                            child: Text('•', style: SteadyType.body),
                          ),
                          Expanded(
                            child: Text(
                              item,
                              style: SteadyType.body.copyWith(
                                color: SteadyColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  const Text(CoachConsent.use, style: SteadyType.body),
                  const SizedBox(height: 12),
                  const Text(CoachConsent.closing, style: SteadyType.body),
                  const SizedBox(height: 28),
                  if (consent case AsyncError()) ...[
                    const Text(
                      "Couldn't save that on this iPhone. Try again.",
                      key: Key('coachConsentError'),
                      style: SteadyType.body,
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    height: 52,
                    child: PrimaryButton(
                      key: const Key('coachConsentAllow'),
                      onPressed: saving ? null : () => unawaited(_allow(ref)),
                      child: const Center(child: Text(CoachConsent.allow)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 52,
                    child: OutlineButton(
                      key: const Key('coachConsentNotNow'),
                      onPressed: saving ? null : onNotNow,
                      child: const Center(child: Text(CoachConsent.notNow)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
