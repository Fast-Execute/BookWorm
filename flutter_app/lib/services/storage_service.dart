import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  StorageService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;
  final SupabaseClient _client;

  /// Uploads bytes so the same path works on web, desktop, and mobile.
  Future<void> uploadPdf({required String objectPath, required List<int> bytes}) async {
    await _client.storage.from('books').uploadBinary(
      objectPath,
      bytes,
      fileOptions: const FileOptions(contentType: 'application/pdf', upsert: false),
    );
  }

  Future<void> deletePdf(String objectPath) async {
    await _client.storage.from('books').remove([objectPath]);
  }
}
