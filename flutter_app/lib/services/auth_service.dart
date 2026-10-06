import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;
  final SupabaseClient _client;

  Future<void> signInAdmin({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
    final isAdmin = await _client.rpc('is_admin');
    if (isAdmin != true) {
      await _client.auth.signOut();
      throw const AuthException('This account is not authorized as a BookWorm administrator.');
    }
  }

  Future<void> signOut() => _client.auth.signOut();
}
