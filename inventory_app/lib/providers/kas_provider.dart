// ============================================================
// PROVIDER KAS (BUKU BESAR ARUS KAS)
// ============================================================
// Mengelola state buku kas toko dan sinkronisasi ke Supabase.
// Tabel Supabase: 'kas'
// ============================================================

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/kas_model.dart';
import '../main.dart';

class KasProvider extends ChangeNotifier {
  List<KasTransaction> _transactions = [];
  bool _isLoading = false;
  String? _errorMessage;

  // ==================== GETTER ====================

  List<KasTransaction> get allTransactions => List.unmodifiable(_transactions);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Hitung total saldo kas saat ini (Kas Masuk - Kas Keluar)
  int get saldoKas {
    int total = 0;
    for (final tx in _transactions) {
      if (tx.tipe == 'masuk') {
        total += tx.jumlah;
      } else if (tx.tipe == 'keluar') {
        total -= tx.jumlah;
      }
    }
    return total;
  }

  // ==================== FETCH ====================

  /// Mengambil riwayat transaksi kas dari Supabase.
  Future<void> fetchTransactions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await supabase
          .from('kas')
          .select()
          .order('created_at', ascending: false);

      _transactions = (data as List)
          .map((item) => KasTransaction.fromMap(item as Map<String, dynamic>))
          .toList();
      _isLoading = false;
      notifyListeners();
    } on PostgrestException catch (e) {
      _isLoading = false;
      _errorMessage = 'Gagal memuat transaksi kas: ${e.message}';
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Gagal terhubung ke server: $e';
      notifyListeners();
    }
  }

  // ==================== OPERASI ====================

  /// Mencatat transaksi kas baru (Masuk/Keluar) ke Supabase.
  Future<bool> tambahTransaksiKas({
    required String tipe,
    required String kategori,
    required int jumlah,
    String? keterangan,
    String? saleId,
    required String userId,
    required String userName,
  }) async {
    try {
      final tx = KasTransaction(
        id: '', // Supabase otomatis generate UUID
        tipe: tipe,
        kategori: kategori,
        jumlah: jumlah,
        keterangan: keterangan,
        saleId: saleId,
        userId: userId,
        userName: userName,
        createdAt: DateTime.now(),
      );

      await supabase.from('kas').insert(tx.toMap());
      await fetchTransactions(); // Refresh data lokal
      return true;
    } on PostgrestException catch (e) {
      _errorMessage = 'Gagal mencatat kas: ${e.message}';
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Gagal terhubung ke server: $e';
      notifyListeners();
      return false;
    }
  }
}
