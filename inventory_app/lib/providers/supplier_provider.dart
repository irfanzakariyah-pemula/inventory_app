// ============================================================
// PROVIDER SUPPLIER
// ============================================================
// Mengelola seluruh state dan operasi CRUD data supplier dari Supabase.
// Tabel Supabase: 'suppliers'
// ============================================================

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/supplier_model.dart';
import '../main.dart';

/// Provider untuk mengelola data supplier/vendor dari Supabase PostgreSQL.
class SupplierProvider extends ChangeNotifier {
  List<Supplier> _suppliers = [];
  bool _isLoading = false;
  String? _errorMessage;

  // ==================== GETTER ====================

  List<Supplier> get allSuppliers => List.unmodifiable(_suppliers);
  int get totalSupplier => _suppliers.length;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ==================== FETCH ====================

  /// Mengambil semua data supplier dari Supabase.
  Future<void> fetchSuppliers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await supabase
          .from('suppliers')
          .select()
          .order('nama', ascending: true);

      _suppliers = (data as List)
          .map((item) => Supplier.fromMap(item as Map<String, dynamic>))
          .toList();
      _isLoading = false;
      notifyListeners();
    } on PostgrestException catch (e) {
      _isLoading = false;
      _errorMessage = 'Gagal memuat supplier: ${e.message}';
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Gagal terhubung ke server: $e';
      notifyListeners();
    }
  }

  // ==================== SEARCH ====================

  /// Mencari supplier berdasarkan nama, kontak, atau alamat.
  List<Supplier> searchSuppliers(String query) {
    if (query.isEmpty) return allSuppliers;
    final q = query.toLowerCase();
    return _suppliers
        .where((s) =>
            s.nama.toLowerCase().contains(q) ||
            (s.kontak?.toLowerCase().contains(q) ?? false) ||
            (s.alamat?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  // ==================== CRUD ====================

  /// Menambahkan supplier baru ke Supabase.
  Future<bool> addSupplier(Supplier supplier) async {
    try {
      await supabase.from('suppliers').insert(supplier.toMap());
      await fetchSuppliers();
      return true;
    } on PostgrestException catch (e) {
      _errorMessage = 'Gagal menambah supplier: ${e.message}';
      notifyListeners();
      return false;
    }
  }

  /// Mengupdate data supplier yang sudah ada.
  Future<bool> updateSupplier(Supplier supplier) async {
    try {
      await supabase
          .from('suppliers')
          .update(supplier.toMap())
          .eq('id', supplier.id);
      await fetchSuppliers();
      return true;
    } on PostgrestException catch (e) {
      _errorMessage = 'Gagal mengupdate supplier: ${e.message}';
      notifyListeners();
      return false;
    }
  }

  /// Menghapus supplier berdasarkan ID.
  Future<bool> deleteSupplier(String id) async {
    try {
      await supabase.from('suppliers').delete().eq('id', id);
      await fetchSuppliers();
      return true;
    } on PostgrestException catch (e) {
      _errorMessage = 'Gagal menghapus supplier: ${e.message}';
      notifyListeners();
      return false;
    }
  }
}
