import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabasePublishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (supabaseUrl.isEmpty || supabasePublishableKey.isEmpty) {
    runApp(const ConfigurationMissingApp());
    return;
  }
  await Supabase.initialize(url: supabaseUrl, anonKey: supabasePublishableKey);
  runApp(const BookWormApp());
}

class ConfigurationMissingApp extends StatelessWidget {
  const ConfigurationMissingApp({super.key});
  @override
  Widget build(BuildContext context) => const MaterialApp(
    home: Scaffold(body: Center(child: Padding(
      padding: EdgeInsets.all(24),
      child: Text('BookWorm needs SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY.', textAlign: TextAlign.center),
    ))),
  );
}

class BookWormApp extends StatelessWidget {
  const BookWormApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'BookWorm',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo), useMaterial3: true),
    home: const LibraryScreen(),
  );
}

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  int _logoTaps = 0;
  DateTime? _lastTap;

  Future<void> _handleLogoTap() async {
    final now = DateTime.now();
    if (_lastTap == null || now.difference(_lastTap!) > const Duration(seconds: 2)) _logoTaps = 0;
    _lastTap = now;
    _logoTaps++;
    if (_logoTaps >= 7) {
      _logoTaps = 0;
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminScreen()));
    }
  }

  Future<List<Map<String, dynamic>>> _loadBooks() async {
    final response = await Supabase.instance.client.from('books').select().eq('is_active', true).order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: GestureDetector(onTap: _handleLogoTap, child: const Text('b. BookWorm'))),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadBooks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Could not load books: ${snapshot.error}')));
        final books = snapshot.data ?? [];
        if (books.isEmpty) return const Center(child: Text('No books available yet.'));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: books.length,
          itemBuilder: (context, index) {
            final book = books[index];
            return Card(child: ListTile(
              title: Text(book['title'] as String? ?? 'Untitled'),
              subtitle: Text('${book['author'] as String? ?? 'Unknown author'} • ${book['total_pages']} pages'),
            ));
          },
        );
      },
    ),
  );
}

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final title = TextEditingController();
  final author = TextEditingController();
  final pages = TextEditingController();
  bool saving = false;

  @override
  void dispose() { title.dispose(); author.dispose(); pages.dispose(); super.dispose(); }

  Future<void> _saveMetadata() async {
    final pageCount = int.tryParse(pages.text.trim());
    if (title.text.trim().isEmpty || author.text.trim().isEmpty || pageCount == null || pageCount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter title, author and valid pages.')));
      return;
    }
    setState(() => saving = true);
    try {
      await Supabase.instance.client.from('books').insert({
        'title': title.text.trim(),
        'author': author.text.trim(),
        'total_pages': pageCount,
        'pdf_path': 'pending-upload',
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Book metadata saved to Supabase.')));
      title.clear(); author.clear(); pages.clear();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $error')));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('BookWorm Admin')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Add book', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
      TextField(controller: author, decoration: const InputDecoration(labelText: 'Author')),
      TextField(controller: pages, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total pages')),
      const SizedBox(height: 20),
      FilledButton(onPressed: saving ? null : _saveMetadata, child: Text(saving ? 'Saving...' : 'Save to Supabase')),
    ]),
  );
}