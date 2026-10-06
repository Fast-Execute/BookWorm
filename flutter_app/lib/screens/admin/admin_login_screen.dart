import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'admin_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});
  @override State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _authService = AuthService();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;

  @override void dispose() { _email.dispose(); _password.dispose(); super.dispose(); }

  Future<void> _login() async {
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      _showMessage('Enter your admin email and password.'); return;
    }
    setState(() => _loading = true);
    try {
      await _authService.signInAdmin(email: _email.text.trim(), password: _password.text);
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AdminScreen()));
    } catch (error) {
      if (mounted) _showMessage('Admin login failed: ' + error.toString());
    } finally { if (mounted) setState(() => _loading = false); }
  }

  void _showMessage(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Administrator Login')),
    body: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('BookWorm Admin', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Sign in with the administrator account configured in Supabase Auth.'),
          const SizedBox(height: 24),
          TextField(controller: _email, keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Admin email', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _password, obscureText: _obscurePassword,
            decoration: InputDecoration(labelText: 'Password', border: const OutlineInputBorder(),
              suffixIcon: IconButton(onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off)))),
          const SizedBox(height: 20),
          FilledButton(onPressed: _loading ? null : _login, child: Text(_loading ? 'Signing in...' : 'Sign in')),
        ]),
      ),
    )),
  );
}
