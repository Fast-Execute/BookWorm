import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/book_service.dart';
import '../../services/storage_service.dart';
import '../../utils/pdf_file_validator.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _title = TextEditingController();
  final _author = TextEditingController();
  final _pages = TextEditingController();
  final _bookService = BookService();
  final _storageService = StorageService();
  final _authService = AuthService();

  PlatformFile? _selectedPdf;
  bool _saving = false;

  @override void dispose() {
    _title.dispose(); _author.dispose(); _pages.dispose(); super.dispose();
  }

  Future<void> _pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any, withData: false);
      if (result == null || result.files.single.path == null) return;
      final pdf = result.files.single;
      final file = File(pdf.path!);

      // Validate the actual file, not just its extension or picker-reported size.
      if (!await PdfFileValidator.hasPdfSignature(file)) {
        _showMessage('Please select a valid PDF file.'); return;
      }
      final actualSize = await file.length();
      if (!PdfFileValidator.isWithinSizeLimit(actualSize)) {
        _showMessage('PDF is too large. Maximum file size is 15 MiB.'); return;
      }
      if (!mounted) return;
      setState(() => _selectedPdf = pdf);
    } catch (error) { _showMessage('Could not select PDF: ' + error.toString()); }
  }

  Future<void> _saveBook() async {
    final title = _title.text.trim();
    final author = _author.text.trim();
    final pages = int.tryParse(_pages.text.trim());
    final pdf = _selectedPdf;

    if (title.isEmpty || author.isEmpty || pages == null || pages <= 0) {
      _showMessage('Enter title, author and a valid page count.'); return;
    }
    if (pdf == null || pdf.path == null) {
      _showMessage('Select a PDF first.'); return;
    }

    final pdfFile = File(pdf.path!);
    try {
      // Recheck immediately before upload in case the selected file changed.
      if (!await PdfFileValidator.hasPdfSignature(pdfFile)) {
        _showMessage('The selected file is no longer a valid PDF. Select it again.'); return;
      }
      final actualSize = await pdfFile.length();
      if (!PdfFileValidator.isWithinSizeLimit(actualSize)) {
        _showMessage('PDF is too large. Maximum file size is 15 MiB.'); return;
      }
    } catch (error) {
      _showMessage('Could not read selected PDF: ' + error.toString()); return;
    }

    setState(() => _saving = true);
    String? bookId;
    String? objectPath;

    try {
      final isAdmin = await _isAdmin();
      if (!isAdmin) throw const AuthException('Administrator authorization is required.');

      bookId = await _bookService.createPendingBook(title: title, author: author, totalPages: pages);
      final fileName = pdf.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
      objectPath = bookId + '/' + fileName;

      await _storageService.uploadPdf(objectPath: objectPath, file: pdfFile);
      await _bookService.setPdfPath(bookId: bookId, pdfPath: objectPath);

      _title.clear(); _author.clear(); _pages.clear();
      if (mounted) {
        setState(() => _selectedPdf = null);
        _showMessage('Book uploaded successfully to Supabase.');
      }
    } catch (error) {
      if (bookId != null) {
        try {
          if (objectPath != null) await _storageService.deletePdf(objectPath!);
        } catch (_) {}
        try { await _bookService.deleteBook(bookId!); } catch (_) {}
      }
      if (mounted) _showMessage('Upload failed: ' + error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _isAdmin() => _authService.isAdmin();

  Future<void> _logout() async {
    await _authService.signOut();
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('BookWorm Admin'),
      actions: [IconButton(onPressed: _logout, icon: const Icon(Icons.logout), tooltip: 'Sign out')],
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Add book', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: _author, decoration: const InputDecoration(labelText: 'Author', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: _pages, keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Total pages', border: OutlineInputBorder())),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _saving ? null : _pickPdf,
          icon: const Icon(Icons.picture_as_pdf),
          label: Text(_selectedPdf == null ? 'Select PDF' : _selectedPdf!.name),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _saving ? null : _saveBook,
          child: Text(_saving ? 'Uploading...' : 'Upload Book to Supabase'),
        ),
      ],
    ),
  );
}
