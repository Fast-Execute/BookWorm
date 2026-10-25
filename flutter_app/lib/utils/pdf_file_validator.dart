import 'dart:io';

/// Validation helpers for PDFs selected for upload to BookWorm.
class PdfFileValidator {
  PdfFileValidator._();

  /// 15 MiB, matching the intended Supabase `books` bucket limit.
  static const int maxBytes = 15 * 1024 * 1024;

  static bool isWithinSizeLimit(int bytes) => bytes > 0 && bytes <= maxBytes;

  /// Checks the file signature instead of trusting a filename extension.
  static Future<bool> hasPdfSignature(File file) async {
    RandomAccessFile? handle;
    try {
      handle = await file.open();
      final header = await handle.read(5);
      return header.length == 5 &&
          header[0] == 0x25 && // %
          header[1] == 0x50 && // P
          header[2] == 0x44 && // D
          header[3] == 0x46 && // F
          header[4] == 0x2D; // -
    } on FileSystemException {
      return false;
    } finally {
      await handle?.close();
    }
  }
}
