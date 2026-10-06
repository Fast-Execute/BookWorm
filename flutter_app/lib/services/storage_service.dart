import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  StorageService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;
  final SupabaseClient _client;

  Future<void> uploadPdf({required String objectPath, required File file}) async {
    await _client.storage.from('books').upload(
      objectPath, file,
      fileOptions: const FileOptions(contentType: 'application/pdf', upsert: false),
    );
  }

  Future<void> deletePdf(String objectPath) async {
    await _client.storage.from('books').remove([objectPath]);
  }
}
