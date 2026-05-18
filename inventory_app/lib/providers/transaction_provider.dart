// ============================================================
// PROVIDER TRANSAKSI - Versi Supabase
// ============================================================
// Mengelola log transaksi stok dari Supabase PostgreSQL.
// Tidak lagi menggunakan Cloud Firestore.
// Setiap addLog() langsung menulis ke tabel 'transactions'.
// Data di-fetch ulang setiap kali HomeScreen diinisialisasi.
// ============================================================

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart';
import '../main.dart';

/// Provider untuk mengelola log transaksi stok dari Supabase PostgreSQL.
class TransactionProvider extends ChangeNotifier {

  List<TransactionLog> _logs = [];
  bool _isLoading = false;
  String? _errorMessage;

  // ==================== GETTER ====================

  /// Semua log, diurutkan dari yang terbaru (sudah dihandle di query).
  List<TransactionLog> get allLogs => List.unmodifiable(_logs);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Jumlah transaksi yang terjadi hari ini.
  int get totalTransaksiHariIni {
    final now = DateTime.now();
    return _logs.where((log) {
      return log.waktu.year == now.year &&
          log.waktu.month == now.month &&
          log.waktu.day == now.day;
    }).length;
  }

  // ==================== SETUP ====================

  /// Mengambil log transaksi dari Supabase.
  /// [userId] null = Admin (tampilkan semua). Ada isi = Petugas (filter miliknya).
  Future<void> startListening({String? userId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Mulai query dasar: ambil semua, urutkan dari terbaru
      var query = supabase
          .from('transactions')
          .select()
          .order('waktu', ascending: false)
          .limit(200); // Batasi 200 log terbaru agar tidak overload memori

      // Jika bukan admin, filter hanya log miliknya
      if (userId != null) {
        final data = await supabase
            .from('transactions')
            .select()
            .eq('user_id', userId)
            .order('waktu', ascending: false)
            .limit(200);

        _logs = (data as List)
            .map((item) => TransactionLog.fromMap(item as Map<String, dynamic>))
            .toList();
      } else {
        final data = await query;
        _logs = (data as List)
            .map((item) => TransactionLog.fromMap(item as Map<String, dynamic>))
            .toList();
      }

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } on PostgrestException catch (e) {
      _isLoading = false;
      _errorMessage = 'Gagal memuat log: ${e.message}';
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Gagal terhubung ke server: $e';
      notifyListeners();
    }
  }

  // ==================== METHOD ====================

  /// Menambahkan log transaksi baru ke tabel 'transactions' di Supabase.
  /// Dipanggil secara otomatis oleh ProductProvider saat stok berubah.
  Future<void> addLog({
    required String productId,
    required String productName,
    required String userId,
    required String userName,
    required TransactionType type,
    required int jumlah,
    required int stokSebelum,
    required int stokSesudah,
    String catatan = '',
  }) async {
    final log = TransactionLog(
      id: '',
      productId: productId,
      productName: productName,
      userId: userId,
      userName: userName,
      type: type,
      jumlah: jumlah,
      stokSebelum: stokSebelum,
      stokSesudah: stokSesudah,
      waktu: DateTime.now(),
      catatan: catatan,
    );

    try {
      await supabase.from('transactions').insert(log.toMap());

      // Tambahkan log baru ke state lokal (tanpa perlu fetch ulang semua)
      // untuk menjaga UI tetap responsif
      _logs.insert(0, log);
      notifyListeners();
    } on PostgrestException catch (e) {
      _errorMessage = 'Gagal mencatat transaksi: ${e.message}';
      notifyListeners();
    }
  }

  /// Mendapatkan log transaksi untuk produk tertentu.
  List<TransactionLog> getLogsByProduct(String productId) {
    return _logs.where((log) => log.productId == productId).toList();
  }

  /// Mendapatkan log transaksi oleh user tertentu.
  List<TransactionLog> getLogsByUser(String userId) {
    return _logs.where((log) => log.userId == userId).toList();
  }
}
