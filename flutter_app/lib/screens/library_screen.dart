import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/book_service.dart';
import 'admin/admin_login_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});
  @override State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _bookService = BookService();
  int _taps = 0;
  DateTime? _lastTap;
  late Future<List<Book>> _booksFuture;

  @override void initState() { super.initState(); _booksFuture = _bookService.getActiveBooks(); }

  Future<void> _handleLogoTap() async {
    final now = DateTime.now();
    if (_lastTap == null || now.difference(_lastTap!) > const Duration(seconds: 2)) _taps = 0;
    _lastTap = now;
    _taps++;
    if (_taps >= 7) {
      _taps = 0;
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminLoginScreen()));
    }
  }

  Future<void> _refresh() async {
    setState(() => _booksFuture = _bookService.getActiveBooks());
    await _booksFuture;
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: GestureDetector(onTap: _handleLogoTap, child: const Text('b. BookWorm'))),
    body: RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<Book>>(
        future: _booksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
            Padding(padding: const EdgeInsets.all(24), child: Text('Could not load books.\n\n' + snapshot.error.toString(), textAlign: TextAlign.center))
          ]);
          final books = snapshot.data ?? [];
          if (books.isEmpty) return ListView(physics: const AlwaysScrollableScrollPhysics(), children: const [
            Padding(padding: EdgeInsets.all(40), child: Center(child: Text('No books available yet.')))
          ]);
          return ListView.builder(
            padding: const EdgeInsets.all(16), itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return Card(child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.menu_book)),
                title: Text(book.title),
                subtitle: Text(book.author + ' • ' + book.totalPages.toString() + ' pages'),
              ));
            },
          );
        },
      ),
    ),
  );
}
