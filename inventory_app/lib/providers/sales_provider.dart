// ============================================================
// PROVIDER SALES (PENJUALAN)
// ============================================================
// Provider paling kritis dalam MVP Smart Retail.
// Bertanggung jawab atas:
//   [1] Menyimpan transaksi penjualan via RPC `checkout_transaction()`
//       — 1 request, aman (atomic), stok dipotong di server-side
//   [2] Menyediakan data KPI untuk Dashboard:
//       — omsetHariIni, jumlahTransaksiHariIni, profitHariIni, omsetBulanIni
//   [3] Menyediakan data Chart:
//       — omset7Hari: [{tanggal, total}]
//       — top5Terlaris: [{nama, jumlahTerjual}]
//   [4] Menyediakan data Laporan:
//       — riwayat transaksi (30 hari terakhir)
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sales_model.dart';
import '../main.dart';

class SalesProvider extends ChangeNotifier {
  List<SalesTransaction> _sales = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  // ==================== GETTER DASAR ====================

  List<SalesTransaction> get allSales => List.unmodifiable(_sales);
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  // ==================== KPI DASHBOARD ====================

  /// Total omset (revenue) hari ini dalam Rupiah.
  int get omsetHariIni {
    final now = DateTime.now();
    return _sales
        .where((s) =>
            s.createdAt.year == now.year &&
            s.createdAt.month == now.month &&
            s.createdAt.day == now.day)
        .fold(0, (sum, s) => sum + s.total);
  }

  /// Jumlah struk / transaksi yang terjadi hari ini.
  int get jumlahTransaksiHariIni {
    final now = DateTime.now();
    return _sales
        .where((s) =>
            s.createdAt.year == now.year &&
            s.createdAt.month == now.month &&
            s.createdAt.day == now.day)
        .length;
  }

  /// Estimasi profit hari ini berdasarkan data item.
  int get profitHariIni {
    final now = DateTime.now();
    return _sales
        .where((s) =>
            s.createdAt.year == now.year &&
            s.createdAt.month == now.month &&
            s.createdAt.day == now.day)
        .fold(0, (sum, s) => sum + s.totalProfit);
  }

  /// Total omset bulan ini dalam Rupiah.
  int get omsetBulanIni {
    final now = DateTime.now();
    return _sales
        .where((s) =>
            s.createdAt.year == now.year &&
            s.createdAt.month == now.month)
        .fold(0, (sum, s) => sum + s.total);
  }

  /// Total transaksi bulan ini.
  int get jumlahTransaksiBulanIni {
    final now = DateTime.now();
    return _sales
        .where((s) =>
            s.createdAt.year == now.year &&
            s.createdAt.month == now.month)
        .length;
  }

  /// Rata-rata nilai transaksi hari ini.
  int get rataRataTransaksiHariIni {
    final jumlah = jumlahTransaksiHariIni;
    if (jumlah == 0) return 0;
    return omsetHariIni ~/ jumlah;
  }

  // ==================== DATA CHART ====================

  /// Data omset 7 hari terakhir untuk Bar Chart.
  /// Returns: List of {tanggal, label, total}
  List<Map<String, dynamic>> get omset7Hari {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final date = now.subtract(Duration(days: 6 - i));
      final total = _sales
          .where((s) =>
              s.createdAt.year == date.year &&
              s.createdAt.month == date.month &&
              s.createdAt.day == date.day)
          .fold(0, (sum, s) => sum + s.total);
      return {
        'tanggal': date,
        'label': DateFormat('EEE', 'id_ID').format(date), // Sen, Sel, Rab...
        'total': total,
      };
    });
  }

  /// Top 5 produk terlaris berdasarkan jumlah unit terjual.
  /// Returns: List of {nama, jumlahTerjual}
  List<Map<String, dynamic>> get top5Terlaris {
    final Map<String, int> penjualanPerProduk = {};
    final Map<String, String> satuanPerProduk = {};

    for (final sale in _sales) {
      for (final item in sale.items) {
        final key = item.namaProduk;
        penjualanPerProduk[key] = (penjualanPerProduk[key] ?? 0) + item.jumlah;
        satuanPerProduk[key] = item.satuan;
      }
    }

    final sorted = penjualanPerProduk.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted
        .take(5)
        .map((e) => {
              'nama': e.key,
              'jumlahTerjual': e.value,
              'satuan': satuanPerProduk[e.key] ?? 'pcs',
            })
        .toList();
  }

  // ==================== DATA LAPORAN ====================

  /// Filter transaksi berdasarkan periode (untuk Laporan tab Ringkasan).
  List<SalesTransaction> getSalesByPeriode(String periode) {
    final now = DateTime.now();
    return _sales.where((s) {
      switch (periode) {
        case 'hari':
          return s.createdAt.year == now.year &&
              s.createdAt.month == now.month &&
              s.createdAt.day == now.day;
        case 'minggu':
          final weekAgo = now.subtract(const Duration(days: 7));
          return s.createdAt.isAfter(weekAgo);
        case 'bulan':
          return s.createdAt.year == now.year &&
              s.createdAt.month == now.month;
        default:
          return true;
      }
    }).toList();
  }

  /// Hitung total omset dari list transaksi yang diberikan.
  int getTotalOmset(List<SalesTransaction> sales) =>
      sales.fold(0, (sum, s) => sum + s.total);

  /// Hitung total profit dari list transaksi yang diberikan.
  int getTotalProfit(List<SalesTransaction> sales) =>
      sales.fold(0, (sum, s) => sum + s.totalProfit);

  // ==================== FETCH ====================

  /// Mengambil data penjualan 30 hari terakhir dari Supabase.
  /// Setiap transaksi di-join dengan sales_items untuk data lengkap.
  Future<void> fetchSales() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Ambil header transaksi 30 hari terakhir
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final salesData = await supabase
          .from('sales')
          .select()
          .gte('created_at', thirtyDaysAgo.toIso8601String())
          .order('created_at', ascending: false);

      final List<SalesTransaction> transactions = [];

      // Untuk setiap transaksi, ambil detail items-nya
      for (final saleMap in (salesData as List)) {
        final saleId = saleMap['id'];
        final itemsData = await supabase
            .from('sales_items')
            .select()
            .eq('sale_id', saleId);

        final items = (itemsData as List)
            .map((item) => SalesItem.fromMap(item as Map<String, dynamic>))
            .toList();

        transactions.add(
          SalesTransaction.fromMap(saleMap as Map<String, dynamic>,
              items: items),
        );
      }

      _sales = transactions;
      _isLoading = false;
      notifyListeners();
    } on PostgrestException catch (e) {
      _isLoading = false;
      _errorMessage = 'Gagal memuat data penjualan: ${e.message}';
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Gagal terhubung ke server: $e';
      notifyListeners();
    }
  }

  // ==================== CHECKOUT ====================

  /// Menyimpan transaksi penjualan baru via RPC `checkout_transaction()`.
  ///
  /// Keuntungan vs insert manual:
  ///   ✅ Satu request HTTP saja (lebih cepat)
  ///   ✅ Atomic — insert sales + items + potong stok dalam satu DB transaction
  ///   ✅ Aman dari race condition / partial failure
  ///
  /// Returns: nomor struk yang berhasil dibuat, atau null jika gagal.
  Future<String?> createSale({
    required List<SalesItem> items,
    required String userId,
    required String userName,
    required int bayar,
    required String metodeBayar,

    int diskon = 0,
    String? catatan,
  }) async {
    if (items.isEmpty) return null;

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Hitung total
      final subtotal = items.fold(0, (sum, item) => sum + item.subtotal);
      final total = subtotal - diskon;
      final kembalian = bayar - total;

      // Generate nomor struk: STR-YYYYMMDD-NNN
      final now = DateTime.now();
      final dateStr = DateFormat('yyyyMMdd').format(now);
      // Hitung jumlah transaksi hari ini + 1 untuk nomor urut
      final nomorUrut = (jumlahTransaksiHariIni + 1).toString().padLeft(3, '0');
      final nomorStruk = 'STR-$dateStr-$nomorUrut';

      // Siapkan items sebagai JSONB untuk RPC
      final itemsJson = items
          .map((item) => {
                'product_id': item.productId,
                'nama_produk': item.namaProduk,
                'harga_jual': item.hargaJual,
                'harga_beli': item.hargaBeli,
                'jumlah': item.jumlah,
                'subtotal': item.subtotal,
                'satuan': item.satuan,
              })
          .toList();

      // Panggil RPC checkout_transaction di Supabase
      await supabase.rpc('checkout_transaction', params: {
        'p_nomor_struk': nomorStruk,
        'p_customer_id': null,
        'p_customer_name': null,
        'p_user_id': userId,
        'p_user_name': userName,
        'p_subtotal': subtotal,
        'p_diskon': diskon,
        'p_total': total,
        'p_bayar': bayar,
        'p_kembalian': kembalian,
        'p_metode_bayar': metodeBayar,
        'p_catatan': catatan,
        'p_items': itemsJson,
      });



      // Refresh data lokal
      await fetchSales();

      _isSubmitting = false;
      notifyListeners();
      return nomorStruk;
    } on PostgrestException catch (e) {
      _isSubmitting = false;
      _errorMessage = 'Transaksi gagal: ${e.message}';
      notifyListeners();
      return null;
    } catch (e) {
      _isSubmitting = false;
      _errorMessage = 'Gagal terhubung ke server: $e';
      notifyListeners();
      return null;
    }
  }
}
