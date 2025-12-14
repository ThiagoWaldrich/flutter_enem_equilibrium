// lib/services/auth_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final _supabase = Supabase.instance.client;

  // Obter usuário atual
  static User? get currentUser => _supabase.auth.currentUser;
  
  // Verificar se está autenticado
  static bool get isAuthenticated => currentUser != null;
  
  // Stream de mudanças de autenticação
  static Stream<AuthState> get authStateChanges =>
      _supabase.auth.onAuthStateChange;

  // Sign Up
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );
      
      return response;
    } catch (e) {
      print('❌ Erro no cadastro: $e');
      rethrow;
    }
  }

  // Sign In
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      return response;
    } catch (e) {
      print('❌ Erro no login: $e');
      rethrow;
    }
  }

  // Sign Out
  static Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      print('❌ Erro ao sair: $e');
      rethrow;
    }
  }

  // Recuperar senha
  static Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      print('❌ Erro ao recuperar senha: $e');
      rethrow;
    }
  }

  // Atualizar perfil
  static Future<UserResponse> updateProfile({
    String? name,
    String? avatarUrl,
  }) async {
    try {
      return await _supabase.auth.updateUser(
        UserAttributes(
          data: {
            if (name != null) 'name': name,
            if (avatarUrl != null) 'avatar_url': avatarUrl,
          },
        ),
      );
    } catch (e) {
      print('❌ Erro ao atualizar perfil: $e');
      rethrow;
    }
  }
}