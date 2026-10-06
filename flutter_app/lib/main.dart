import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/library_screen.dart';

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
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'BookWorm needs SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );
}

class BookWormApp extends StatelessWidget {
  const BookWormApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'BookWorm',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      useMaterial3: true,
    ),
    home: const LibraryScreen(),
  );
}
