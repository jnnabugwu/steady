import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:steady/providers.dart';
import 'package:ui_kit/ui_kit.dart';

/// Where Steady's privacy policy lives: the same address as the App Store
/// Connect "Privacy Policy URL" (`docs/testflight.md`).
final Uri privacyPolicyUrl = Uri.parse(
  'https://github.com/jnnabugwu/steady/blob/main/docs/PRIVACY.md',
);

/// The "Privacy" section of Settings: a line on what the policy covers and
/// a link that opens it in the browser. App Store guideline 5.1.1(i) asks
/// for the policy inside the app as well as in the store listing.
///
/// If the link can't be opened, the address is shown so it can still be
/// typed or copied.
class PrivacyCard extends ConsumerStatefulWidget {
  /// Creates the card.
  const PrivacyCard({super.key});

  @override
  ConsumerState<PrivacyCard> createState() => _PrivacyCardState();
}

class _PrivacyCardState extends ConsumerState<PrivacyCard> {
  var _failed = false;

  Future<void> _open() async {
    bool opened;
    try {
      opened = await ref.read(appLinkOpenerProvider)(privacyPolicyUrl);
    } on Object {
      opened = false;
    }
    if (mounted) setState(() => _failed = !opened);
  }

  @override
  Widget build(BuildContext context) {
    return SteadyCard(
      key: const Key('privacyCard'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Privacy', style: SteadyType.cardTitle),
          const SizedBox(height: 8),
          const Text(
            'What Steady stores, where it keeps it, and how to delete it.',
            style: SteadyType.body,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 44,
            child: OutlineButton(
              key: const Key('privacyPolicyButton'),
              leading: const Icon(LucideIcons.shieldCheck),
              onPressed: _open,
              child: const Text('Privacy policy'),
            ),
          ),
          if (_failed) ...[
            const SizedBox(height: 12),
            SelectableText(
              "Couldn't open the link. It's at $privacyPolicyUrl",
              key: const Key('privacyPolicyFallback'),
              style: SteadyType.body,
            ),
          ],
        ],
      ),
    );
  }
}
