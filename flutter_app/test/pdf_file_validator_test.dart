import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:bookworm/utils/pdf_file_validator.dart';

void main() {
  group('PdfFileValidator.isWithinSizeLimit', () {
    test('accepts a non-empty file up to exactly 15 MiB', () {
      expect(PdfFileValidator.isWithinSizeLimit(1), isTrue);
      expect(PdfFileValidator.isWithinSizeLimit(PdfFileValidator.maxBytes), isTrue);
    });

    test('rejects empty files and files above 15 MiB', () {
      expect(PdfFileValidator.isWithinSizeLimit(0), isFalse);
      expect(PdfFileValidator.isWithinSizeLimit(PdfFileValidator.maxBytes + 1), isFalse);
    });
  });

  group('PdfFileValidator.hasPdfSignature', () {
    late Directory tempDirectory;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp('bookworm_pdf_test_');
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('accepts a file with a PDF header', () async {
      final file = File('${tempDirectory.path}/valid.pdf');
      await file.writeAsBytes(<int>[0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x37]);
      expect(await PdfFileValidator.hasPdfSignature(file), isTrue);
    });

    test('rejects a non-PDF file even when it has a .pdf extension', () async {
      final file = File('${tempDirectory.path}/fake.pdf');
      await file.writeAsString('This is not a PDF');
      expect(await PdfFileValidator.hasPdfSignature(file), isFalse);
    });

    test('rejects a file shorter than the PDF header', () async {
      final file = File('${tempDirectory.path}/short.pdf');
      await file.writeAsBytes(<int>[0x25, 0x50, 0x44]);
      expect(await PdfFileValidator.hasPdfSignature(file), isFalse);
    });
  });
}
