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
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminLoginScreen()));
    }
  }

  Future<List<Map<String, dynamic>>> loadBooks() async {
    final response = await Supabase.instance.client
        .from('books')
        .select()
        .eq('is_active', true)
        .order('created_at', ascending: false);
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

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});
  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  bool obscurePassword = true;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter your admin email and password.')));
      return;
    }

    setState(() => loading = true);
    try {
      final client = Supabase.instance.client;
      await client.auth.signInWithPassword(
        email: email.text.trim(),
        password: password.text,
      );

      final isAdmin = await client.rpc('is_admin');
      if (isAdmin != true) {
        await client.auth.signOut();
        throw const AuthException('This account is not authorized as a BookWorm administrator.');
      }

      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AdminScreen()),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Admin login failed: $error')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Administrator Login')),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('BookWorm Admin', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Sign in with the administrator account configured in Supabase Auth.'),
              const SizedBox(height: 24),
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.username],
                decoration: const InputDecoration(labelText: 'Admin email', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: password,
                obscureText: obscurePassword,
                autofillHints: const [AutofillHints.password],
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => obscurePassword = !obscurePassword),
                    icon: Icon(obscurePassword ? Icons.visibility : Icons.visibility_off),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: loading ? null : login,
                child: Text(loading ? 'Signing in...' : 'Sign in'),
              ),
            ],
          ),
        ),
      ),
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
      if (await client.rpc('is_admin') != true) {
        throw const AuthException('Administrator authorization is required.');
      }

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

  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('BookWorm Admin'),
      actions: [IconButton(onPressed: logout, icon: const Icon(Icons.logout), tooltip: 'Sign out')],
    ),
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
