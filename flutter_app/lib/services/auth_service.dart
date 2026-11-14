import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;
  final SupabaseClient _client;

  Future<void> signInAdmin({required String email, required String password}) async {
    final authResponse = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final isAdmin = await isAdmin();
    if (!isAdmin) {
      await _client.auth.signOut();
      throw const AuthException('This account is not authorized as a BookWorm administrator.');
    }

    if (authResponse.user == null) {
      throw const AuthException('No authenticated user returned for admin sign in.');
    }
  }

  Future<bool> isAdmin() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return false;
    }

    try {
      final isAdmin = await _client.rpc<bool>('is_admin');
      return isAdmin == true;
    } on PostgrestException catch (_) {
      return false;
    } on AuthException catch (_) {
      return false;
    }
  }

  Future<void> signOut() => _client.auth.signOut();
}
