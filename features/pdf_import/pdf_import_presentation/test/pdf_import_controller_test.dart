import 'dart:async';

import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_import_domain/pdf_import_domain.dart';
import 'package:pdf_import_presentation/pdf_import_presentation.dart';

import 'helpers/fakes.dart';

void main() {
  late FakePdfImportRepository repository;
  late FakePdfFilePicker picker;
  late ProviderContainer container;
  late List<PdfImportState> states;

  setUp(() {
    repository = FakePdfImportRepository();
    picker = FakePdfFilePicker(bytes: pdfBytes);
    container = ProviderContainer.test(
      overrides: [
        pdfImportRepositoryProvider.overrideWithValue(repository),
        pdfFilePickerProvider.overrideWithValue(picker.call),
      ],
    );
    states = [];
    // Keeps the auto-dispose provider alive and records every state.
    container.listen<PdfImportState>(
      pdfImportControllerProvider,
      (_, next) => states.add(next),
      fireImmediately: true,
    );
  });

  PdfImportController notifier() =>
      container.read(pdfImportControllerProvider.notifier);

  Matcher isPreview({
    bool isCommitting = false,
    Matcher commitFailure = isNull,
  }) => isA<PdfImportPreview>()
      .having((s) => s.days, 'days', sampleDays)
      .having((s) => s.isCommitting, 'isCommitting', isCommitting)
      .having((s) => s.commitFailure, 'commitFailure', commitFailure);

  test('starts empty', () {
    expect(states, [isA<PdfImportEmpty>()]);
  });

  group('parsePdf', () {
    test('goes parsing -> preview with the parsed days', () async {
      await notifier().parsePdf(pdfBytes);

      expect(states, [
        isA<PdfImportEmpty>(),
        isA<PdfImportParsing>(),
        isPreview(),
      ]);
      expect(repository.parseCalls, [pdfBytes]);
    });

    test('goes parsing -> parse failed carrying the Failure', () async {
      const failure = ValidationFailure('not a Cal AI export');
      repository.onParse = (_) => const Err(failure);

      await notifier().parsePdf(pdfBytes);

      expect(
        states.last,
        isA<PdfImportParseFailed>().having(
          (s) => s.failure,
          'failure',
          failure,
        ),
      );
    });

    test('zero days parsed is an empty preview, not a failure', () async {
      repository.onParse = (_) => const Ok([]);

      await notifier().parsePdf(pdfBytes);

      expect(
        states.last,
        isA<PdfImportPreview>().having((s) => s.days, 'days', isEmpty),
      );
    });

    test('a second parse while one is in flight is ignored', () async {
      final parse = Completer<Result<List<ParsedDay>>>();
      repository.onParse = (_) => parse.future;

      final first = notifier().parsePdf(pdfBytes);
      await notifier().parsePdf(pdfBytes);
      parse.complete(Ok(sampleDays));
      await first;

      expect(repository.parseCalls, hasLength(1));
    });
  });

  group('choosePdf', () {
    test('picks then parses the chosen bytes', () async {
      await notifier().choosePdf();

      expect(picker.calls, 1);
      expect(repository.parseCalls, [pdfBytes]);
      expect(states.last, isPreview());
    });

    test('a cancelled pick changes nothing', () async {
      picker.bytes = null;

      await notifier().choosePdf();

      expect(picker.calls, 1);
      expect(repository.parseCalls, isEmpty);
      expect(states, [isA<PdfImportEmpty>()]);
    });

    test('a picker error becomes a parse failure', () async {
      picker.error = Exception('sandbox denied');

      await notifier().choosePdf();

      expect(
        states.last,
        isA<PdfImportParseFailed>().having(
          (s) => s.failure,
          'failure',
          isA<UnknownFailure>(),
        ),
      );
      expect(repository.parseCalls, isEmpty);
    });
  });

  group('commitImport', () {
    setUp(() => notifier().parsePdf(pdfBytes));

    test('goes committing -> committed and writes the days', () async {
      states.clear();

      await notifier().commitImport();

      expect(states, [
        isPreview(isCommitting: true),
        isA<PdfImportCommitted>().having((s) => s.days, 'days', sampleDays),
      ]);
      expect(repository.commitCalls, [sampleDays]);
    });

    test('a failed commit keeps the preview with the Failure', () async {
      const failure = PlatformChannelFailure('store down', code: 'E_IO');
      repository.onCommit = (_) => const Err(failure);
      states.clear();

      await notifier().commitImport();

      expect(states, [
        isPreview(isCommitting: true),
        isPreview(commitFailure: equals(failure)),
      ]);
    });

    test('retrying after a failed commit can succeed', () async {
      repository.onCommit = (_) => const Err(UnknownFailure('flaky'));
      await notifier().commitImport();
      repository.onCommit = (_) => const Ok(unit);

      await notifier().commitImport();

      expect(states.last, isA<PdfImportCommitted>());
      expect(repository.commitCalls, hasLength(2));
    });

    test('a second commit while one is in flight is ignored', () async {
      final commit = Completer<Result<Unit>>();
      repository.onCommit = (_) => commit.future;

      final first = notifier().commitImport();
      await notifier().commitImport();
      commit.complete(const Ok(unit));
      await first;

      expect(repository.commitCalls, hasLength(1));
    });

    test('nothing to commit with an empty preview', () async {
      repository.onParse = (_) => const Ok([]);
      await notifier().parsePdf(pdfBytes);

      await notifier().commitImport();

      expect(repository.commitCalls, isEmpty);
    });
  });

  test('commitImport before any parse is ignored', () async {
    await notifier().commitImport();

    expect(repository.commitCalls, isEmpty);
    expect(states, [isA<PdfImportEmpty>()]);
  });
}
