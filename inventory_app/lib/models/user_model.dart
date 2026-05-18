// ============================================================
// MODEL USER - Definisi data pengguna & role akses
// ============================================================
// Versi Supabase: Tidak lagi bergantung pada cloud_firestore.
// Data dibaca dari PostgreSQL Supabase sebagai Map<String, dynamic>.
// Password dikelola oleh Supabase Auth (GoTrue) — tidak disimpan di sini.
// ============================================================

/// Enum untuk mendefinisikan role/peran pengguna dalam sistem.
/// - [admin]   : Memiliki akses penuh (CRUD barang, lihat semua log, dll)
/// - [petugas] : Hanya bisa update stok dan melihat log miliknya
enum UserRole { admin, petugas }

/// Model data pengguna yang merepresentasikan user dalam sistem.
/// Data disimpan di tabel 'users' di Supabase PostgreSQL.
class UserModel {
  final String id;       // UUID dari Supabase Auth
  final String nama;     // Nama lengkap pengguna
  final String email;    // Email untuk login
  final UserRole role;   // Role/peran pengguna

  /// Constructor dengan named parameters, semua field wajib diisi.
  const UserModel({
    required this.id,
    required this.nama,
    required this.email,
    required this.role,
  });

  /// Helper method untuk mengecek apakah user adalah admin.
  bool get isAdmin => role == UserRole.admin;

  /// Menghasilkan label role yang mudah dibaca.
  String get roleLabel => isAdmin ? 'Administrator' : 'Petugas Gudang';

  /// Factory constructor dari Map Supabase (hasil query PostgreSQL).
  /// Digunakan saat membaca data dari tabel 'users'.
  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      id: data['id'] ?? '',
      nama: data['nama'] ?? '',
      email: data['email'] ?? '',
      role: (data['role'] ?? 'petugas') == 'admin'
          ? UserRole.admin
          : UserRole.petugas,
    );
  }

  /// Konversi ke Map untuk disimpan ke Supabase.
  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'email': email,
      'role': isAdmin ? 'admin' : 'petugas',
    };
  }
}
