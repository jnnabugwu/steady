/// The app shell: the tab branches with the floating [GlassTabBar] over
/// them (issue #66). Routing lives in `app_router.dart`; this file only
/// lays the bar out and turns a tap into a branch switch.
library;

import 'dart:math' as math;

import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

/// The shell's tabs, in branch order (`AppShellRoute`'s branches).
///
/// The Coach tab joins once the coach screen exists; until then it isn't
/// shown at all, rather than being a dead tab.
const appShellTabs = <GlassTabItem>[
  GlassTabItem(icon: LucideIcons.sun, label: 'Today'),
  GlassTabItem(icon: LucideIcons.chartColumn, label: 'Week'),
  GlassTabItem(icon: LucideIcons.settings, label: 'Settings'),
];

/// Lays [navigationShell] (the current branch's navigator) out full-screen
/// and floats the [GlassTabBar] over its bottom edge.
///
/// **Content scrolls under the bar.** The branch fills the whole screen, so
/// the bar's backdrop blur has the content behind it. Below the bar, the
/// shell raises `MediaQuery.padding.bottom` (and `viewPadding.bottom`) by
/// the bar's footprint, [bottomInset], the same contract as a Material
/// `Scaffold` with `extendBody`: a screen that wraps itself in `SafeArea`
/// keeps its last card's buttons above the bar, and a scroll view that
/// pads its end by `MediaQuery.paddingOf(context).bottom` scrolls under it
/// and still stops with its last item clear of it.
class AppShell extends StatelessWidget {
  /// Creates the shell around [navigationShell].
  const AppShell({required this.navigationShell, super.key});

  /// The branch navigators, from `StatefulShellRoute`.
  final StatefulNavigationShell navigationShell;

  /// The bar's gap from the screen's sides and bottom (the artboard's 18px).
  static const double barMargin = 18;

  /// Breathing room between the bar's top and the end of the content.
  static const double contentGap = 16;

  /// The space the bar takes up from the bottom of a screen whose system
  /// bottom inset (the home indicator) is [systemBottom]. Also the bottom
  /// padding the shell hands its content.
  static double bottomInset(double systemBottom) =>
      _barBottom(systemBottom) + GlassTabBar.height + contentGap;

  /// The bar sits [barMargin] above the screen's bottom edge, or on the
  /// home indicator's inset where that's larger.
  static double _barBottom(double systemBottom) =>
      math.max(barMargin, systemBottom);

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final systemBottom = media.padding.bottom;
    final inset = bottomInset(systemBottom);
    return Stack(
      children: [
        Positioned.fill(
          child: MediaQuery(
            data: media.copyWith(
              padding: media.padding.copyWith(bottom: inset),
              viewPadding: media.viewPadding.copyWith(
                bottom: math.max(media.viewPadding.bottom, inset),
              ),
            ),
            child: navigationShell,
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: GlassTabBar(
            key: const Key('appTabBar'),
            items: appShellTabs,
            selectedIndex: navigationShell.currentIndex,
            margin: EdgeInsets.fromLTRB(
              barMargin,
              0,
              barMargin,
              _barBottom(systemBottom),
            ),
            // Re-tapping the current tab pops its stack back to the tab's
            // root (e.g. from a check-in back to Today).
            onSelected: (index) => navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            ),
          ),
        ),
      ],
    );
  }
}
