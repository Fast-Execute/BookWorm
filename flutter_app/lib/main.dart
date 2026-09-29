import 'dart:io';
import 'package:file_picker/file_picker.dart';
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
  int taps = 0;
  DateTime? lastTap;

  Future<void> handleLogoTap() async {
    final now = DateTime.now();
    if (lastTap == null || now.difference(lastTap!) > const Duration(seconds: 2)) taps = 0;
    lastTap = now;
    taps++;
    if (taps >= 7) {
      taps = 0;
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminScreen()));
    }
  }

  Future<List<Map<String, dynamic>>> loadBooks() async {
    final response = await Supabase.instance.client.from('books').select().eq('is_active', true).order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: GestureDetector(onTap: handleLogoTap, child: const Text('b. BookWorm'))),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: loadBooks(),
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
  PlatformFile? selectedPdf;
  bool saving = false;

  @override
  void dispose() { title.dispose(); author.dispose(); pages.dispose(); super.dispose(); }

  Future<void> pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: false,
    );
    if (result != null && result.files.single.path != null) {
      setState(() => selectedPdf = result.files.single);
    }
  }

  Future<void> saveBook() async {
    final pageCount = int.tryParse(pages.text.trim());
    if (title.text.trim().isEmpty || author.text.trim().isEmpty || pageCount == null || pageCount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter title, author and valid pages.')));
      return;
    }
    if (selectedPdf == null || selectedPdf!.path == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a PDF first.')));
      return;
    }

    setState(() => saving = true);
    try {
      final client = Supabase.instance.client;
      final book = await client.from('books').insert({
        'title': title.text.trim(),
        'author': author.text.trim(),
        'total_pages': pageCount,
        'pdf_path': 'pending',
      }).select('id').single();

      final bookId = book['id'] as String;
      final fileName = selectedPdf!.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
      final objectPath = '$bookId/$fileName';

      await client.storage.from('books').upload(
        objectPath,
        File(selectedPdf!.path!),
        fileOptions: const FileOptions(contentType: 'application/pdf', upsert: false),
      );

      await client.from('books').update({'pdf_path': objectPath}).eq('id', bookId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Book uploaded to Supabase and added to the library.')));
      title.clear();
      author.clear();
      pages.clear();
      setState(() => selectedPdf = null);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $error')));
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
      const SizedBox(height: 16),
      OutlinedButton.icon(
        onPressed: saving ? null : pickPdf,
        icon: const Icon(Icons.picture_as_pdf),
        label: Text(selectedPdf == null ? 'Select PDF' : selectedPdf!.name),
      ),
      const SizedBox(height: 16),
      FilledButton(
        onPressed: saving ? null : saveBook,
        child: Text(saving ? 'Uploading...' : 'Upload Book to Supabase'),
      ),
    ]),
  );
}
