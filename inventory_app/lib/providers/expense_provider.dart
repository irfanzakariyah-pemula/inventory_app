// ============================================================
// PROVIDER EXPENSE (BIAYA OPERASIONAL)
// ============================================================
// Mengelola data pengeluaran operasional dan sinkronisasi kas.
// Tabel Supabase: 'expenses'
// ============================================================

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/expense_model.dart';
import '../main.dart';

class ExpenseProvider extends ChangeNotifier {
  List<Expense> _expenses = [];
  bool _isLoading = false;
  String? _errorMessage;

  // ==================== GETTER ====================

  List<Expense> get allExpenses => List.unmodifiable(_expenses);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Hitung total akumulasi pengeluaran
  int get totalPengeluaran {
    return _expenses.fold(0, (sum, exp) => sum + exp.jumlah);
  }

  // ==================== FETCH ====================

  /// Mengambil data pengeluaran dari Supabase.
  Future<void> fetchExpenses() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await supabase
          .from('expenses')
          .select()
          .order('tanggal', ascending: false)
          .order('created_at', ascending: false);

      _expenses = (data as List)
          .map((item) => Expense.fromMap(item as Map<String, dynamic>))
          .toList();
      _isLoading = false;
      notifyListeners();
    } on PostgrestException catch (e) {
      _isLoading = false;
      _errorMessage = 'Gagal memuat pengeluaran: ${e.message}';
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Gagal terhubung ke server: $e';
      notifyListeners();
    }
  }

  /// Mengambil data pengeluaran terfilter berdasarkan range tanggal
  List<Expense> getExpensesByPeriod(DateTime start, DateTime end) {
    return _expenses.where((exp) {
      // Hilangkan komponen waktu untuk pencocokan tanggal saja
      final expDate = DateTime(exp.tanggal.year, exp.tanggal.month, exp.tanggal.day);
      final startDate = DateTime(start.year, start.month, start.day);
      final endDate = DateTime(end.year, end.month, end.day);
      return (expDate.isAtSameMomentAs(startDate) || expDate.isAfter(startDate)) &&
          (expDate.isAtSameMomentAs(endDate) || expDate.isBefore(endDate));
    }).toList();
  }

  /// Mengambil pengeluaran berdasarkan periode filter ('hari' | 'minggu' | 'bulan' | 'semua')
  List<Expense> getExpensesByPeriodString(String periode) {
    final now = DateTime.now();
    return _expenses.where((exp) {
      switch (periode) {
        case 'hari':
          return exp.tanggal.year == now.year &&
              exp.tanggal.month == now.month &&
              exp.tanggal.day == now.day;
        case 'minggu':
          final weekAgo = now.subtract(const Duration(days: 7));
          return exp.tanggal.isAfter(weekAgo);
        case 'bulan':
          return exp.tanggal.year == now.year &&
              exp.tanggal.month == now.month;
        default:
          return true;
      }
    }).toList();
  }

  // ==================== CRUD ====================

  /// Menambahkan pencatatan biaya operasional baru dan mengurangkan kas secara otomatis.
  Future<bool> tambahPengeluaran({
    required String kategori,
    required int jumlah,
    String? keterangan,
    required DateTime tanggal,
    required String userId,
    required String userName,
  }) async {
    try {
      final exp = Expense(
        id: '', // Supabase generate UUID
        kategori: kategori,
        jumlah: jumlah,
        keterangan: keterangan,
        tanggal: tanggal,
        userId: userId,
        userName: userName,
        createdAt: DateTime.now(),
      );

      // 1. Simpan pengeluaran ke tabel 'expenses'
      await supabase.from('expenses').insert(exp.toMap());

      // 2. Catat otomatis kas keluar ke tabel 'kas'
      await supabase.from('kas').insert({
        'tipe': 'keluar',
        'kategori': 'biaya',
        'jumlah': jumlah,
        'keterangan': 'Biaya [${exp.kategoriLabel}]: ${keterangan ?? ""}',
        'user_id': userId,
        'user_name': userName,
      });

      await fetchExpenses(); // Refresh data lokal
      return true;
    } on PostgrestException catch (e) {
      _errorMessage = 'Gagal menyimpan pengeluaran: ${e.message}';
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Gagal terhubung ke server: $e';
      notifyListeners();
      return false;
    }
  }
}
