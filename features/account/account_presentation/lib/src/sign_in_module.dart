import 'dart:async';

import 'package:account_domain/account_domain.dart';
import 'package:account_presentation/src/account_status_controller.dart';
import 'package:failures/failures.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

/// The iCloud sign-in screen.
///
/// Steady keeps everything in the user's own iCloud account, and iCloud is
/// required with no local-only fallback (CLAUDE.md §7), so this screen says
/// what's wrong and how to fix it, in plain words and without blame
/// (product doc §1). There is no login form: the Apple Account is the
/// account (CLAUDE.md §1).
///
/// Knows nothing about routing (CLAUDE.md §5). The app router decides when
/// this screen is shown and when to leave it, from
/// [accountStatusControllerProvider]. "Check again" fires the
/// AccountRechecked domain event on that controller; "Open Settings" calls
/// [onOpenSettings], and the app layer decides how to open them.
///
/// Built from `shadcn_flutter` and `ui_kit` widgets only, so it needs a
/// `ShadcnApp` ancestor and no Material ones.
class SignInModule extends ConsumerWidget {
  /// Creates the sign-in screen.
  const SignInModule({required this.onOpenSettings, super.key});

  /// Called when the user taps "Open Settings".
  final void Function() onOpenSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(accountStatusControllerProvider);
    final copy = switch (status) {
      AsyncData(:final value) => _copyFor(value),
      AsyncError(error: final Failure failure) => _SignInCopy(
        title: "Couldn't reach iCloud",
        body:
            "Steady couldn't check your iCloud account: ${failure.message}. "
            'Check again in a moment.',
      ),
      AsyncError() => const _SignInCopy(
        title: "Couldn't reach iCloud",
        body:
            "Steady couldn't check your iCloud account. "
            'Check again in a moment.',
      ),
      AsyncLoading() => const _SignInCopy(
        title: 'Checking iCloud',
        body: 'Looking for your iCloud account on this device.',
      ),
    };

    return Scaffold(
      headers: const [AppBar(title: Text('iCloud'))],
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SteadyCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    copy.title,
                    key: const Key('signIn_title'),
                    style: SteadyType.headline,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    copy.body,
                    key: const Key('signIn_body'),
                    style: SteadyType.body,
                  ),
                  if (copy.steps case final steps?) ...[
                    const SizedBox(height: 12),
                    Text(
                      steps,
                      key: const Key('signIn_steps'),
                      style: SteadyType.body,
                    ),
                  ],
                  if (status.isLoading) ...[
                    const SizedBox(height: 16),
                    const Center(child: CircularProgressIndicator()),
                  ],
                  const SizedBox(height: 20),
                  PrimaryButton(
                    key: const Key('signInButton_openSettings'),
                    onPressed: onOpenSettings,
                    child: const Text('Open Settings'),
                  ),
                  const SizedBox(height: 8),
                  OutlineButton(
                    key: const Key('signInButton_checkAgain'),
                    // Disabled while a read is in flight; the controller
                    // also ignores a re-check then.
                    onPressed: status.isLoading
                        ? null
                        : () => unawaited(
                            ref
                                .read(accountStatusControllerProvider.notifier)
                                .recheckAccount(),
                          ),
                    child: const Text('Check again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static _SignInCopy _copyFor(AccountStatus status) {
    final isMac = defaultTargetPlatform == TargetPlatform.macOS;
    return switch (status) {
      AccountStatus.noAccount => _SignInCopy(
        title: 'Sign in to iCloud',
        body:
            'Steady keeps your check-ins and history in your own iCloud '
            "account, so this ${isMac ? 'Mac' : 'device'} needs to be signed "
            'in to iCloud first.',
        steps: isMac
            ? 'Open System Settings, choose "Sign in" with your Apple '
                  'Account, then come back here.'
            : 'Open Settings, go back to the top of the main list and tap '
                  '"Sign in to your iPhone", then come back here.',
      ),
      AccountStatus.restricted => const _SignInCopy(
        title: 'iCloud is turned off on this device',
        body:
            'Something on this device is keeping apps from using iCloud, '
            'usually Screen Time or a work or school profile. Steady keeps '
            'your data in iCloud, so it needs that turned back on.',
        steps:
            'Check Screen Time in Settings, or ask whoever manages this '
            'device. Then come back here.',
      ),
      AccountStatus.temporarilyUnavailable => const _SignInCopy(
        title: "iCloud isn't ready yet",
        body:
            "Your iCloud account is signed in but can't be used right now. "
            'This usually clears up on its own, or after you accept any new '
            'iCloud terms in Settings.',
      ),
      AccountStatus.couldNotDetermine => const _SignInCopy(
        title: "Couldn't reach iCloud",
        body:
            "Steady couldn't check your iCloud account just now. "
            'Check again in a moment.',
      ),
      AccountStatus.notConfigured => const _SignInCopy(
        title: "iCloud isn't set up in this build",
        body:
            "This build of Steady doesn't use iCloud yet, so there's "
            'nothing to sign in to. You can keep using the app.',
      ),
      AccountStatus.available => const _SignInCopy(
        title: "You're signed in",
        body: 'Your iCloud account is ready.',
      ),
    };
  }
}

/// The words on the sign-in screen for one state.
class _SignInCopy {
  const _SignInCopy({required this.title, required this.body, this.steps});

  final String title;
  final String body;

  /// What to do about it, when there's something the user can do.
  final String? steps;
}
