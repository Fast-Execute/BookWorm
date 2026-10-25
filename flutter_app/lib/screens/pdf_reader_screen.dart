import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import '../models/book.dart';
import '../services/storage_service.dart';

class PdfReaderScreen extends StatefulWidget {
  const PdfReaderScreen({super.key, required this.book});
  final Book book;

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  final _storage = StorageService();
  PdfController? _controller;
  Object? _error;
  bool _loading = true;
  int _currentPage = 1;
  int? _totalPages;

  @override
  void initState() {
    super.initState();
    _openPdf();
  }

  Future<void> _openPdf() async {
    try {
      if (widget.book.pdfPath.isEmpty || widget.book.pdfPath == 'pending') {
        throw Exception('This book does not have a PDF attached yet.');
      }
      final Uint8List bytes = await _storage.downloadPdf(widget.book.pdfPath);
      if (bytes.isEmpty) throw Exception('The downloaded PDF is empty.');
      final controller = PdfController(document: PdfDocument.openData(bytes));
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _loading = false;
      });
    } catch (error) {
      if (mounted) setState(() { _error = error; _loading = false; });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.book.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      bottom: _controller == null ? null : PreferredSize(
        preferredSize: const Size.fromHeight(28),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            _totalPages == null ? 'Page $_currentPage' : 'Page $_currentPage of $_totalPages',
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
      ),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.picture_as_pdf_outlined, size: 48),
                      const SizedBox(height: 12),
                      const Text('Could not open this book. Check your connection and access permissions.'),
                      const SizedBox(height: 8),
                      Text(_error.toString(), textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => setState(() { _loading = true; _error = null; _openPdf(); }),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              )
            : PdfView(
                controller: _controller!,
                onPageChanged: (page) => setState(() => _currentPage = page),
                onDocumentLoaded: (document) => setState(() => _totalPages = document.pagesCount),
                builders: PdfViewBuilders<DefaultBuilderOptions>(
                  options: const DefaultBuilderOptions(),
                  documentLoaderBuilder: (_) => const Center(child: CircularProgressIndicator()),
                  pageLoaderBuilder: (_) => const Center(child: CircularProgressIndicator()),
                  errorBuilder: (_, error) => Center(child: Text('PDF rendering failed: $error')),
                ),
              ),
  );
}
