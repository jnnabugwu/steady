import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_import_data/pdf_import_data.dart';

import 'support/pdfium.dart';

/// `CalAIParser.parse` end to end through PDFium, on a synthetic PDF built
/// in memory (no personal data, so it runs in CI). The reference exports in
/// `cal_ai_parser_test.dart` are gitignored and self-skip on CI; without this
/// test, CI would never load PDFium or call `parse` at all.
///
/// The PDF puts each line at its own baseline, the way a Cal AI table row is
/// one text line, so PDFium's text extraction yields the same line shapes
/// `cal_ai_parser_lines_test.dart` feeds `parsePageLines` directly.
void main() {
  setUpAll(usePdfiumBuiltByFlutterTest);

  test('parses a two-page PDF through PDFium into ParsedDays', () async {
    final pdf = _buildPdf([
      [
        "Sam's Report",
        'Foods Calories Protein Carbs Fat Fiber Sugar Sodium Time',
        'August 1, 2025',
        'Ground Turkey 780 96g 0g 48g 0g 0g 1440mg 3:11pm',
        'Muscle Milk Chocolate Peanut Butter',
        'Protein Shake 160 20g 5g 3g 1g 2g 200mg 8:04pm',
        'TOTAL Calories eaten: 940',
      ],
      [
        'August 2, 2025',
        'Oatmeal 300 10g 54g 5g 8g 1g 0mg 7:30am',
        'TOTAL Calories eaten: 300',
      ],
    ]);

    final days = await CalAIParser().parse(pdf);

    expect(days.map((d) => d.date), [DateTime(2025, 8), DateTime(2025, 8, 2)]);
    expect(days.map((d) => d.caloriesEaten), [940, 300]);
    expect(days.first.foodEntries.map((e) => e.name), [
      'Ground Turkey',
      'Muscle Milk Chocolate Peanut Butter Protein Shake',
    ]);
    expect(days.first.foodEntries.map((e) => e.calories), [780, 160]);
    expect(days.last.foodEntries.single.name, 'Oatmeal');
  });
}

/// A minimal PDF 1.4 file: one page per entry in [pages], each line drawn in
/// Helvetica at its own baseline, with a correct xref table.
Uint8List _buildPdf(List<List<String>> pages) {
  String escape(String s) =>
      s.replaceAll(r'\', r'\\').replaceAll('(', r'\(').replaceAll(')', r'\)');

  // Object numbers: 1 catalog, 2 page tree, 3 font, then per page
  // (page, content stream) pairs.
  final objects = <String>[];
  final pageRefs = <String>[];
  for (var i = 0; i < pages.length; i++) {
    final pageNum = 4 + i * 2;
    pageRefs.add('$pageNum 0 R');
  }
  objects
    ..add('<< /Type /Catalog /Pages 2 0 R >>')
    ..add(
      '<< /Type /Pages /Kids [${pageRefs.join(' ')}] '
      '/Count ${pages.length} >>',
    )
    ..add(
      '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica '
      '/Encoding /WinAnsiEncoding >>',
    );
  for (var i = 0; i < pages.length; i++) {
    final contentNum = 5 + i * 2;
    final content = StringBuffer();
    var y = 750;
    for (final line in pages[i]) {
      content.writeln('BT /F1 10 Tf 1 0 0 1 50 $y Tm (${escape(line)}) Tj ET');
      y -= 20;
    }
    final stream = content.toString();
    objects
      ..add(
        '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] '
        '/Resources << /Font << /F1 3 0 R >> >> '
        '/Contents $contentNum 0 R >>',
      )
      ..add(
        '<< /Length ${latin1.encode(stream).length} >>\n'
        'stream\n${stream}endstream',
      );
  }

  final out = BytesBuilder();
  void write(String s) => out.add(latin1.encode(s));

  write('%PDF-1.4\n');
  final offsets = <int>[];
  for (var i = 0; i < objects.length; i++) {
    offsets.add(out.length);
    write('${i + 1} 0 obj\n${objects[i]}\nendobj\n');
  }
  final xrefOffset = out.length;
  write('xref\n0 ${objects.length + 1}\n0000000000 65535 f \n');
  for (final offset in offsets) {
    write('${offset.toString().padLeft(10, '0')} 00000 n \n');
  }
  write(
    'trailer\n<< /Size ${objects.length + 1} /Root 1 0 R >>\n'
    'startxref\n$xrefOffset\n%%EOF\n',
  );
  return out.toBytes();
}
