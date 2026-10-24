import 'package:cravings_domain/cravings_domain.dart';
import 'package:cravings_presentation/cravings_presentation.dart';
import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

import 'helpers/fake_craving_repository.dart';

void main() {
  late FakeCravingRepository repository;
  late List<Uri> opened;
  late bool openResult;

  setUp(() {
    repository = FakeCravingRepository([
      CravingEvent(
        id: 'a',
        startedAt: DateTime(2026, 10, 22, 19),
        intensityBefore: 3,
        reasons: const {},
        tookMinute: false,
        outcome: CravingOutcome.notSure,
      ),
    ]);
    opened = [];
    openResult = true;
  });

  Future<void> pump(WidgetTester tester, {bool available = true}) async {
    tester.view.physicalSize = const Size(390, 1200) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cravingRepositoryProvider.overrideWithValue(repository),
          cravingSupportAvailableProvider.overrideWithValue(available),
          cravingLinkOpenerProvider.overrideWithValue((uri) async {
            opened.add(uri);
            return openResult;
          }),
        ],
        child: const ShadcnApp(
          theme: steadyTheme,
          home: Scaffold(
            child: SingleChildScrollView(child: CravingSettingsCard()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders nothing where craving support is off (macOS)', (
    tester,
  ) async {
    await pump(tester, available: false);
    expect(find.byKey(const Key('cravingSettingsCard')), findsNothing);
  });

  testWidgets('says where check-ins are kept, and offers help', (tester) async {
    await pump(tester);
    expect(find.text('Cravings'), findsOneWidget);
    expect(
      find.text(
        "Craving check-ins stay on this iPhone. Steady doesn't sync them. "
        "If your iPhone backs up to iCloud, they're included in that "
        'backup, like other app data.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('1-888-375-7767'), findsOneWidget);
    expect(find.text('In a crisis, call or text 988.'), findsOneWidget);
  });

  testWidgets('delete asks first; cancelling keeps everything', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('cravingDeleteHistoryButton')));
    await tester.pumpAndSettle();

    expect(find.text('Delete craving history?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('cravingDeleteCancel')));
    await tester.pumpAndSettle();

    expect(repository.deleteAllCalls, 0);
    expect(repository.events, hasLength(1));
    expect(find.byKey(const Key('cravingDeleteStatus')), findsNothing);
  });

  testWidgets('confirming deletes the history and says so', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('cravingDeleteHistoryButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('cravingDeleteConfirm')));
    await tester.pumpAndSettle();

    expect(repository.deleteAllCalls, 1);
    expect(repository.events, isEmpty);
    expect(find.text('Craving history deleted.'), findsOneWidget);
  });

  testWidgets('a failed delete says so', (tester) async {
    repository.onDeleteAll = () async => const Err(UnknownFailure('locked'));
    await pump(tester);
    await tester.tap(find.byKey(const Key('cravingDeleteHistoryButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('cravingDeleteConfirm')));
    await tester.pumpAndSettle();

    expect(
      find.text("Couldn't delete craving history. Try again."),
      findsOneWidget,
    );
  });

  testWidgets('the help link opens ANAD', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('cravingHelpLink')));
    await tester.pumpAndSettle();
    expect(opened, [anadHelplineUri]);
    expect(
      anadHelplineUri.toString(),
      'https://anad.org/get-support/eating-disorders-helpline/',
    );
    expect(find.byKey(const Key('cravingHelpLinkError')), findsNothing);
  });

  testWidgets('a link that will not open falls back to text', (tester) async {
    openResult = false;
    await pump(tester);
    await tester.tap(find.byKey(const Key('cravingHelpLink')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('cravingHelpLinkError')), findsOneWidget);
  });

  testWidgets('controls are labelled and at least 44pt tall', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester);
    for (final key in ['cravingDeleteHistoryButton', 'cravingHelpLink']) {
      expect(
        tester.getSize(find.byKey(Key(key))).height,
        greaterThanOrEqualTo(44),
      );
    }
    expect(find.bySemanticsLabel('Delete craving history'), findsOneWidget);
    expect(find.bySemanticsLabel('ANAD helpline'), findsOneWidget);
    semantics.dispose();
  });
}
