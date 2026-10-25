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
    test('accepts bytes with a PDF header', () {
      expect(
        PdfFileValidator.hasPdfSignature(<int>[0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x37]),
        isTrue,
      );
    });

    test('rejects a non-PDF file even if its name ends in .pdf', () {
      expect(
        PdfFileValidator.hasPdfSignature('This is not a PDF'.codeUnits),
        isFalse,
      );
    });

    test('rejects bytes shorter than the PDF header', () {
      expect(PdfFileValidator.hasPdfSignature(<int>[0x25, 0x50, 0x44]), isFalse);
    });
  });
}
