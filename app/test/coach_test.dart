import 'dart:convert';
import 'dart:io';

import 'package:coach_data/coach_data.dart';
import 'package:coach_domain/coach_domain.dart';
import 'package:coach_presentation/coach_presentation.dart';
import 'package:data_export_domain/data_export_domain.dart';
import 'package:data_export_presentation/data_export_presentation.dart';
import 'package:failures/failures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderException;
import 'package:flutter_test/flutter_test.dart';
import 'package:steady/main.dart';
import 'package:steady/providers.dart';

/// Coach session storage (#78) on the real override list: iPhone only (by
/// the injected platform), device-only file storage, the Settings card,
/// and the export's coach summaries.
void main() {
  final settingsCard = find.byKey(const Key('coachSettingsCard'));
  final session = CoachSession(
    id: 'w1',
    kind: CoachSessionKind.weekly,
    startedAt: DateTime(2026, 10, 23, 19),
    endedAt: DateTime(2026, 10, 23, 19, 15),
    summary: 'A steady week.',
    messages: [
      CoachMessage(
        role: CoachMessageRole.coach,
        text: 'How did the week feel?',
        at: DateTime(2026, 10, 23, 19),
      ),
    ],
  );

  group('binding', () {
    test('iOS binds the coach: the device-only file store, also read by '
        'the export', () {
      final ios = ProviderContainer.test(
        overrides: appProviderOverridesFor(isIOS: true),
      );
      expect(ios.read(coachSupportAvailableProvider), isTrue);
      expect(ios.read(coachRepositoryProvider), isA<FileCoachRepository>());
      expect(
        ios.read(exportCoachRepositoryProvider),
        same(ios.read(coachRepositoryProvider)),
      );
    });

    test('macOS binds no coach provider', () {
      final mac = ProviderContainer.test(
        overrides: appProviderOverridesFor(isIOS: false),
      );
      expect(mac.read(coachSupportAvailableProvider), isFalse);
      expect(mac.read(exportCoachRepositoryProvider), isNull);
      expect(
        () => mac.read(coachRepositoryProvider),
        throwsA(
          isA<ProviderException>().having(
            (e) => e.exception,
            'exception',
            isA<UnimplementedError>(),
          ),
        ),
      );
    });

    test('the iOS file store keeps sessions across a restart', () async {
      final dir = Directory.systemTemp.createTempSync('steady_coach');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/coach_sessions.json');
      // The iOS binding, pointed at a temp file instead of the app
      // support directory (no path_provider plugin in a unit test).
      ProviderContainer launch() => ProviderContainer.test(
        overrides: [
          ...appProviderOverridesFor(isIOS: false),
          coachSupportAvailableProvider.overrideWithValue(true),
          coachRepositoryProvider.overrideWith(
            (ref) => FileCoachRepository(file),
          ),
        ],
      );

      expect(
        await launch().read(coachRepositoryProvider).saveSession(session),
        isA<Ok<Unit>>(),
      );
      final result = await launch()
          .read(coachRepositoryProvider)
          .listSessions();
      expect((result as Ok<List<CoachSession>>).value, [session]);
    });
  });

  group('in the app', () {
    late _MemoryCoachRepository coach;
    late List<String> sharedContents;

    setUp(() {
      coach = _MemoryCoachRepository()..sessions.add(session);
      sharedContents = [];
    });

    /// Pumps the real app at `/settings`. [isIOS] is the injected platform.
    ///
    /// On iOS the coach repository is the in-memory [coach] instead of the
    /// file store, which needs `path_provider`. Overrides can't be stacked
    /// on `appProviderOverridesFor(isIOS: true)` (Riverpod rejects
    /// overriding a provider twice), so that case builds on the macOS list
    /// and adds exactly what iOS binds for the coach; the `binding` tests
    /// above check that's the same.
    Future<ProviderContainer> pumpSettings(
      WidgetTester tester, {
      required bool isIOS,
    }) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.defaultRouteNameTestValue = '/settings';
      addTearDown(tester.platformDispatcher.clearDefaultRouteNameTestValue);
      final container = ProviderContainer(
        overrides: [
          ...appProviderOverridesFor(isIOS: false),
          if (isIOS) ...[
            coachSupportAvailableProvider.overrideWithValue(true),
            coachRepositoryProvider.overrideWithValue(coach),
            exportCoachRepositoryProvider.overrideWith(
              (ref) => ref.watch(coachRepositoryProvider),
            ),
          ],
          exportFileSharerProvider.overrideWithValue((
            file, {
            sharePositionOrigin,
          }) async {
            sharedContents.add(file.contents);
            return const Ok(ExportShareOutcome.shared);
          }),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const SteadyApp(),
        ),
      );
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('iOS: Settings has the Coach card, and deleting clears the '
        'history', (tester) async {
      await pumpSettings(tester, isIOS: true);
      expect(find.byType(DataExportModule), findsOneWidget);
      expect(settingsCard, findsOneWidget);

      final delete = find.byKey(const Key('coachDeleteHistoryButton'));
      await tester.ensureVisible(delete);
      await tester.tap(delete);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('coachDeleteConfirm')));
      await tester.pumpAndSettle();

      expect(coach.sessions, isEmpty);
      expect(find.text('Coach history deleted.'), findsOneWidget);
    });

    testWidgets("iOS: the JSON export has the session's summary, not its "
        'transcript', (tester) async {
      final container = await pumpSettings(tester, isIOS: true);
      container.listen(dataExportControllerProvider, (_, _) {});
      await container
          .read(dataExportControllerProvider.notifier)
          .exportData(ExportFormat.json);

      final json = jsonDecode(sharedContents.single) as Map<String, Object?>;
      expect(json['schemaVersion'], 2);
      expect(json['coachSessions'], [
        {'date': '2026-10-23', 'kind': 'weekly', 'summary': 'A steady week.'},
      ]);
      expect(sharedContents.single, isNot(contains('How did the week feel')));
    });

    testWidgets('macOS: Settings has no Coach card, and the export has no '
        'coach sessions', (tester) async {
      final container = await pumpSettings(tester, isIOS: false);
      expect(find.byType(DataExportModule), findsOneWidget);
      expect(settingsCard, findsNothing);

      container.listen(dataExportControllerProvider, (_, _) {});
      await container
          .read(dataExportControllerProvider.notifier)
          .exportData(ExportFormat.json);
      final json = jsonDecode(sharedContents.single) as Map<String, Object?>;
      expect(json.containsKey('coachSessions'), isFalse);
    });
  });
}

/// An in-memory [CoachRepository] for widget tests (the file store's own
/// tests live in `coach_data`; real file I/O doesn't run under a widget
/// test's fake clock).
class _MemoryCoachRepository implements CoachRepository {
  final List<CoachSession> sessions = [];

  @override
  ResultFuture<List<CoachSession>> listSessions() async =>
      Ok([...sessions]..sort(compareCoachSessionsNewestFirst));

  @override
  ResultFuture<CoachSession?> getSession(String id) async =>
      Ok(sessions.where((s) => s.id == id).firstOrNull);

  @override
  ResultFuture<Unit> saveSession(CoachSession session) async {
    sessions
      ..removeWhere((s) => s.id == session.id)
      ..add(session);
    return const Ok(unit);
  }

  @override
  ResultFuture<Unit> deleteAll() async {
    sessions.clear();
    return const Ok(unit);
  }
}
