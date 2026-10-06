import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/book.dart';

class BookService {
  BookService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;
  final SupabaseClient _client;

  Future<List<Book>> getActiveBooks() async {
    final response = await _client.from('books').select().eq('is_active', true).order('created_at', ascending: false);
    return (response as List).map((row) => Book.fromMap(Map<String, dynamic>.from(row))).toList();
  }

  Future<String> createPendingBook({required String title, required String author, required int totalPages}) async {
    final row = await _client.from('books').insert({
      'title': title, 'author': author, 'total_pages': totalPages, 'pdf_path': 'pending',
    }).select('id').single();
    return row['id'] as String;
  }

  Future<void> setPdfPath({required String bookId, required String pdfPath}) async {
    await _client.from('books').update({'pdf_path': pdfPath}).eq('id', bookId);
  }

  Future<void> deleteBook(String bookId) async {
    await _client.from('books').delete().eq('id', bookId);
  }
}
