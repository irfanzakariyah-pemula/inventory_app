// ============================================================
// PROVIDER CUSTOMER (PELANGGAN)
// ============================================================
// Mengelola seluruh state dan operasi CRUD data pelanggan dari Supabase.
// Tabel Supabase: 'customers'
// ============================================================

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/customer_model.dart';
import '../main.dart';

/// Provider untuk mengelola data pelanggan dari Supabase PostgreSQL.
class CustomerProvider extends ChangeNotifier {
  List<Customer> _customers = [];
  bool _isLoading = false;
  String? _errorMessage;

  // ==================== GETTER ====================

  List<Customer> get allCustomers => List.unmodifiable(_customers);
  int get totalCustomer => _customers.length;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ==================== FETCH ====================

  /// Mengambil semua data pelanggan dari Supabase.
  Future<void> fetchCustomers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await supabase
          .from('customers')
          .select()
          .order('nama', ascending: true);

      _customers = (data as List)
          .map((item) => Customer.fromMap(item as Map<String, dynamic>))
          .toList();
      _isLoading = false;
      notifyListeners();
    } on PostgrestException catch (e) {
      _isLoading = false;
      _errorMessage = 'Gagal memuat pelanggan: ${e.message}';
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Gagal terhubung ke server: $e';
      notifyListeners();
    }
  }

  // ==================== SEARCH ====================

  /// Mencari pelanggan berdasarkan nama atau kontak.
  List<Customer> searchCustomers(String query) {
    if (query.isEmpty) return allCustomers;
    final q = query.toLowerCase();
    return _customers
        .where((c) =>
            c.nama.toLowerCase().contains(q) ||
            (c.kontak?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  // ==================== CRUD ====================

  /// Menambahkan pelanggan baru ke Supabase.
  Future<bool> addCustomer(Customer customer) async {
    try {
      await supabase.from('customers').insert(customer.toMap());
      await fetchCustomers();
      return true;
    } on PostgrestException catch (e) {
      _errorMessage = 'Gagal menambah pelanggan: ${e.message}';
      notifyListeners();
      return false;
    }
  }

  /// Mengupdate data pelanggan yang sudah ada.
  Future<bool> updateCustomer(Customer customer) async {
    try {
      await supabase
          .from('customers')
          .update(customer.toMap())
          .eq('id', customer.id);
      await fetchCustomers();
      return true;
    } on PostgrestException catch (e) {
      _errorMessage = 'Gagal mengupdate pelanggan: ${e.message}';
      notifyListeners();
      return false;
    }
  }

  /// Menghapus pelanggan berdasarkan ID.
  Future<bool> deleteCustomer(String id) async {
    try {
      await supabase.from('customers').delete().eq('id', id);
      await fetchCustomers();
      return true;
    } on PostgrestException catch (e) {
      _errorMessage = 'Gagal menghapus pelanggan: ${e.message}';
      notifyListeners();
      return false;
    }
  }
}
