/// Validation helpers for PDFs selected for upload to BookWorm.
class PdfFileValidator {
  PdfFileValidator._();

  /// 15 MiB, matching the intended Supabase `books` bucket limit.
  static const int maxBytes = 15 * 1024 * 1024;

  static bool isWithinSizeLimit(int bytes) => bytes > 0 && bytes <= maxBytes;

  /// Checks the PDF signature instead of trusting the filename extension.
  static bool hasPdfSignature(List<int> bytes) =>
      bytes.length >= 5 &&
      bytes[0] == 0x25 && // %
      bytes[1] == 0x50 && // P
      bytes[2] == 0x44 && // D
      bytes[3] == 0x46 && // F
      bytes[4] == 0x2D; // -
}
