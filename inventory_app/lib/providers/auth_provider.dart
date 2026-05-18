// ============================================================
// PROVIDER AUTENTIKASI - Supabase Auth
// ============================================================
// Versi Supabase: Menggantikan Firebase Auth + Firestore.
// - Login/logout menggunakan Supabase Auth (GoTrue)
// - Data profil user (nama, role) diambil dari tabel 'users' PostgreSQL
// ============================================================

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../main.dart';

/// Provider untuk mengelola seluruh logika autentikasi via Supabase Auth.
class AuthProvider extends ChangeNotifier {

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // ==================== GETTER ====================

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ==================== METHOD ====================

  /// Login menggunakan Supabase Auth (email & password).
  /// Setelah login berhasil, ambil data profil dari tabel 'users'.
  Future<bool> login(String email, String password) async {
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();

    try {
      // Sign in dengan Supabase Auth
      final response = await supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = response.user;
      if (user == null) {
        _errorMessage = 'Login gagal. Coba lagi.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Ambil data profil user dari tabel 'users' berdasarkan UUID
      final data = await supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .single();

      _currentUser = UserModel.fromMap(data);
      _isLoading = false;
      notifyListeners();
      return true;

    } on AuthException catch (e) {
      _isLoading = false;
      // Terjemahkan pesan error Supabase Auth ke Bahasa Indonesia
      switch (e.message.toLowerCase()) {
        case 'invalid login credentials':
        case 'email not confirmed':
          _errorMessage = 'Email atau password salah';
          break;
        case 'too many requests':
          _errorMessage = 'Terlalu banyak percobaan. Coba lagi nanti.';
          break;
        default:
          _errorMessage = 'Terjadi kesalahan: ${e.message}';
      }
      notifyListeners();
      return false;

    } on PostgrestException catch (e) {
      // Error saat membaca data profil dari tabel 'users'
      _isLoading = false;
      _errorMessage = 'Data user tidak ditemukan. Hubungi admin. (${e.message})';
      notifyListeners();
      return false;

    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Gagal terhubung ke server. Periksa koneksi internet.';
      notifyListeners();
      return false;
    }
  }

  /// Logout dari Supabase Auth dan hapus state lokal.
  Future<void> logout() async {
    await supabase.auth.signOut();
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Menghapus pesan error.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
