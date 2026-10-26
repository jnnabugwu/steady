import 'dart:io';

import 'package:coach_data/coach_data.dart';
import 'package:coach_domain/coach_domain.dart';
import 'package:failures/failures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Smoke test for the real `steady/coach` channel
/// (`ios/Runner/CoachChannel.swift`) and Apple Foundation Models, on an
/// iPhone or the iOS simulator (which uses the host Mac's model when Apple
/// Intelligence is on there). iOS only: there's no macOS handler.
///
/// Prints the availability. Where the model is available, it starts a chat
/// session with the real coach instructions, streams a reply to a short
/// prompt (printing each snapshot), checks the snapshots are cumulative,
/// then cancels a second reply partway and checks the session still
/// answers afterwards. Where it isn't, it checks the reason is one of the
/// typed failures and stops there.
///
/// `flutter test integration_test/coach_model_smoke_test.dart -d <id>`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final model = MethodChannelCoachModel();

  testWidgets(
    'streams a reply from the on-device model',
    skip: !Platform.isIOS,
    (_) async {
      final availability = await model.checkAvailability();
      final CoachModelInfo info;
      switch (availability) {
        case Err(:final failure):
          debugPrint(
            'steady/coach unavailable: ${failure.runtimeType}: '
            '${failure.message}',
          );
          expect(failure, isA<CoachModelUnavailableFailure>());
          markTestSkipped('The on-device model is unavailable here');
          return;
        case Ok(:final value):
          info = value;
      }
      debugPrint('steady/coach available, contextSize ${info.contextSize}');
      expect(info.contextSize, greaterThan(0));

      final started = await model.startSession(
        instructions: CoachInstructions.chat,
      );
      final session = switch (started) {
        Ok(:final value) => value,
        Err(:final failure) => fail(
          'Could not start a session: ${failure.runtimeType}: '
          '${failure.message}',
        ),
      };

      final stopwatch = Stopwatch()..start();
      final snapshots = <String>[];
      await for (final event in model.streamResponse(
        session,
        'In two sentences: what can you help me with?',
      )) {
        switch (event) {
          case Ok(:final value):
            snapshots.add(value.text);
            debugPrint(
              'steady/coach snapshot ${snapshots.length} '
              '(${value.outputTokens ?? 'no'} tokens): ${value.text}',
            );
          case Err(:final failure):
            fail('Reply failed: ${failure.runtimeType}: ${failure.message}');
        }
      }
      debugPrint(
        'steady/coach reply done in ${stopwatch.elapsedMilliseconds} '
        'ms, ${snapshots.length} snapshots',
      );
      expect(snapshots, isNotEmpty);
      expect(snapshots.last.trim(), isNotEmpty);
      // Cumulative snapshots: each one starts with the one before.
      for (var i = 1; i < snapshots.length; i++) {
        expect(snapshots[i].startsWith(snapshots[i - 1]), isTrue);
      }

      // Cancel a second reply after its first snapshot.
      var cancelledAfter = 0;
      await for (final event in model.streamResponse(
        session,
        'Tell me a long story about a walk in the park.',
      )) {
        expect(event, isA<Ok<CoachReplySnapshot>>());
        cancelledAfter++;
        expect(await model.cancelResponse(session), isA<Ok<Unit>>());
      }
      // Without this, the cancel-then-reuse check below would pass on a
      // reply that never streamed and so was never actually cancelled.
      expect(cancelledAfter, greaterThan(0));
      debugPrint('steady/coach cancelled after $cancelledAfter snapshot(s)');

      // The session still answers after a cancel.
      final after = await model
          .streamResponse(session, 'Say hello in three words.')
          .last;
      debugPrint('steady/coach after cancel: $after');
      expect(after, isA<Ok<CoachReplySnapshot>>());

      expect(await model.endSession(session), isA<Ok<Unit>>());
      final ended = await model.streamResponse(session, 'Hello?').single;
      expect(
        (ended as Err<CoachReplySnapshot>).failure,
        isA<CoachInferenceFailure>().having(
          (f) => f.reason,
          'reason',
          CoachInferenceFailureReason.sessionEnded,
        ),
      );
    },
  );
}
