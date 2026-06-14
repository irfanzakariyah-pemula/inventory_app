// ============================================================
// PROVIDER PRODUK - Versi Supabase
// ============================================================
// Mengelola seluruh state dan operasi data produk dari Supabase PostgreSQL.
// Tidak lagi menggunakan Cloud Firestore atau stream real-time otomatis.
// Data di-refresh secara manual setiap kali ada operasi CRUD.
//
// Fitur lengkap:
//   [+] getProductByBarcode() : Cari produk via barcode fisik
//   [+] Getter barangMendekatiExpired & barangSudahExpired
//   [+] jumlahMendekatiExpired : Untuk badge peringatan di Dashboard
//   [+] fastUpdateStok()  : Update stok +1/-1 instan untuk Scanner
//   [+] adjustStock()     : Penyesuaian stok opname
//   [~] searchProducts()  : Bisa cari berdasarkan nama, SKU, barcode, kategori
// ============================================================


import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart';
import '../main.dart';
import 'transaction_provider.dart';

/// Provider untuk mengelola data produk dari Supabase PostgreSQL.
class ProductProvider extends ChangeNotifier {

  TransactionProvider? _transactionProvider;

  List<Product> _products = [];
  bool _isLoading = false;
  String? _errorMessage;

  // ==================== GETTER DASAR ====================

  List<Product> get allProducts => List.unmodifiable(_products);
  int get totalBarang => _products.length;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ==================== GETTER STOK KRITIS ====================

  List<Product> get stokKritis =>
      _products.where((p) => p.isStokKritis).toList();

  int get jumlahStokKritis => stokKritis.length;

  // ==================== GETTER EXPIRED DATE ====================

  /// Daftar produk mendekati kedaluwarsa, diurutkan dari yang paling dekat.
  List<Product> get barangMendekatiExpired {
    return _products
        .where((p) => p.isMendekatiExpired)
        .toList()
      ..sort((a, b) =>
          (a.sisaHariExpired ?? 0).compareTo(b.sisaHariExpired ?? 0));
  }

  List<Product> get barangSudahExpired =>
      _products.where((p) => p.isSudahExpired).toList();

  int get jumlahMendekatiExpired => barangMendekatiExpired.length;

  // ==================== SETUP ====================

  /// Hubungkan ProductProvider dengan TransactionProvider untuk pencatatan log.
  void setTransactionProvider(TransactionProvider provider) {
    _transactionProvider = provider;
  }

  /// Mengambil semua data produk dari Supabase dan menyimpannya di state lokal.
  /// Dipanggil sekali saat HomeScreen pertama kali diinisialisasi,
  /// dan dipanggil ulang setelah setiap operasi CRUD untuk menjaga data sinkron.
  Future<void> fetchProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await supabase
          .from('products')
          .select()
          .order('nama', ascending: true);

      _products = (data as List)
          .map((item) => Product.fromMap(item as Map<String, dynamic>))
          .toList();
      _isLoading = false;
      notifyListeners();
    } on PostgrestException catch (e) {
      _isLoading = false;
      _errorMessage = 'Gagal memuat data: ${e.message}';
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Gagal terhubung ke server: $e';
      notifyListeners();
    }
  }

  // Alias untuk kompatibilitas dengan HomeScreen yang memanggil startListening()
  void startListening() => fetchProducts();

  // ==================== PENCARIAN ====================

  /// Mencari produk berdasarkan kata kunci (nama, SKU, barcode, kategori).
  List<Product> searchProducts(String query) {
    if (query.isEmpty) return allProducts;
    final lowerQuery = query.toLowerCase();
    return _products
        .where((p) =>
            p.nama.toLowerCase().contains(lowerQuery) ||
            p.sku.toLowerCase().contains(lowerQuery) ||
            p.barcode.toLowerCase().contains(lowerQuery) ||
            p.kategori.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// Mencari produk berdasarkan barcode fisik secara tepat (exact match).
  Product? getProductByBarcode(String barcode) {
    try {
      return _products.firstWhere((p) => p.barcode == barcode);
    } catch (_) {
      return null;
    }
  }

  /// Mencari produk berdasarkan ID.
  Product? getProductById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  // ==================== CRUD OPERATIONS ====================

  /// Menambahkan produk baru ke Supabase.
  Future<void> addProduct(
    Product product, {
    String? userId,
    String? userName,
  }) async {
    try {
      final inserted = await supabase
          .from('products')
          .insert(product.toMap())
          .select()
          .single();

      final newProduct = Product.fromMap(inserted);

      if (product.stok > 0 && userId != null && userName != null) {
        await _transactionProvider?.addLog(
          productId: newProduct.id,
          productName: newProduct.nama,
          userId: userId,
          userName: userName,
          type: TransactionType.masuk,
          jumlah: product.stok,
          stokSebelum: 0,
          stokSesudah: product.stok,
          catatan: 'Stok awal saat barang pertama kali didaftarkan',
        );
      }

      await fetchProducts();
    } on PostgrestException catch (e) {
      _errorMessage = 'Gagal menambah produk: ${e.message}';
      notifyListeners();
    }
  }

  /// Menambahkan produk baru dan mengembalikan ID-nya secara langsung.
  /// Digunakan oleh ProductFormScreen agar bisa upload gambar segera
  /// setelah produk tersimpan tanpa harus mencari via SKU.
  Future<String> addProductAndGetId(
    Product product, {
    String? userId,
    String? userName,
  }) async {
    try {
      final inserted = await supabase
          .from('products')
          .insert(product.toMap())
          .select()
          .single();

      final newProduct = Product.fromMap(inserted);

      if (product.stok > 0 && userId != null && userName != null) {
        await _transactionProvider?.addLog(
          productId: newProduct.id,
          productName: newProduct.nama,
          userId: userId,
          userName: userName,
          type: TransactionType.masuk,
          jumlah: product.stok,
          stokSebelum: 0,
          stokSesudah: product.stok,
          catatan: 'Stok awal saat barang pertama kali didaftarkan',
        );
      }

      await fetchProducts();
      return newProduct.id; // ← Kembalikan ID langsung dari response
    } on PostgrestException catch (e) {
      _errorMessage = 'Gagal menambah produk: ${e.message}';
      notifyListeners();
      return ''; // Kembalikan string kosong jika gagal
    } catch (e) {
      _errorMessage = 'Error: $e';
      notifyListeners();
      return '';
    }
  }

  /// Mengupdate data produk yang sudah ada di Supabase.
  Future<void> updateProduct(
    Product product, {
    String? userId,
    String? userName,
  }) async {
    try {
      // Ambil stok lama dari data lokal sebelum di-update
      final oldProduct = _products.firstWhere(
        (p) => p.id == product.id,
        orElse: () => product,
      );
      final stokLama = oldProduct.stok;

      await supabase
          .from('products')
          .update(product.toMap())
          .eq('id', product.id);

      // Catat log otomatis jika stok ikut berubah
      if (stokLama != product.stok && userId != null && userName != null) {
        final selisih = product.stok - stokLama;
        await _transactionProvider?.addLog(
          productId: product.id,
          productName: product.nama,
          userId: userId,
          userName: userName,
          type: selisih > 0 ? TransactionType.masuk : TransactionType.keluar,
          jumlah: selisih.abs(),
          stokSebelum: stokLama,
          stokSesudah: product.stok,
          catatan: 'Perubahan stok melalui form edit barang',
        );
      }

      await fetchProducts();
    } on PostgrestException catch (e) {
      _errorMessage = 'Gagal mengupdate produk: ${e.message}';
      notifyListeners();
    }
  }

  /// Menghapus produk dari Supabase berdasarkan ID.
  Future<void> deleteProduct(String id) async {
    try {
      await supabase.from('products').delete().eq('id', id);
      await fetchProducts();
    } on PostgrestException catch (e) {
      _errorMessage = 'Gagal menghapus produk: ${e.message}';
      notifyListeners();
    }
  }

  // ==================== STOK OPERATIONS ====================

  /// Update stok barang secara manual (input angka jumlah).
  /// Membaca stok terkini dari server dahulu sebelum update
  /// untuk mencegah race condition.
  Future<bool> updateStock({
    required String productId,
    required int jumlah,
    required TransactionType type,
    required String userId,
    required String userName,
    String catatan = '',
  }) async {
    try {
      // Baca stok terkini dari Supabase (bukan dari cache lokal)
      final current = await supabase
          .from('products')
          .select('stok, nama')
          .eq('id', productId)
          .single();

      final stokSebelum = current['stok'] as int;
      final namaProduk = current['nama'] as String;
      int stokBaru;

      if (type == TransactionType.masuk) {
        stokBaru = stokSebelum + jumlah;
      } else {
        stokBaru = stokSebelum - jumlah;
        if (stokBaru < 0) return false; // Tolak jika stok tidak cukup
      }

      // Update stok di Supabase
      await supabase
          .from('products')
          .update({'stok': stokBaru})
          .eq('id', productId);

      // Catat log transaksi
      await _transactionProvider?.addLog(
        productId: productId,
        productName: namaProduk,
        userId: userId,
        userName: userName,
        type: type,
        jumlah: jumlah,
        stokSebelum: stokSebelum,
        stokSesudah: stokBaru,
        catatan: catatan,
      );

      await fetchProducts();
      return true;
    } on PostgrestException catch (e) {
      _errorMessage = 'Gagal update stok: ${e.message}';
      notifyListeners();
      return false;
    }
  }

  /// Update stok instan sebesar +1 atau -1 (untuk fitur Barcode Scanner).
  Future<bool> fastUpdateStok({
    required String productId,
    required TransactionType type,
    required String userId,
    required String userName,
  }) async {
    return updateStock(
      productId: productId,
      jumlah: 1,
      type: type,
      userId: userId,
      userName: userName,
      catatan: 'Update cepat via Scan Barcode',
    );
  }



  // ==================== STOK OPERATIONS ====================

  /// Penyesuaian stok manual untuk Stock Opname.
  /// Admin langsung menetapkan jumlah stok aktual di lapangan.
  Future<bool> adjustStock({
    required String productId,
    required int stokAktual,
    required String userId,
    required String userName,
    String catatan = 'Penyesuaian dari Stock Opname',
  }) async {
    try {
      final current = await supabase
          .from('products')
          .select('stok, nama')
          .eq('id', productId)
          .single();

      final stokSebelum = current['stok'] as int;
      final namaProduk = current['nama'] as String;

      if (stokSebelum == stokAktual) return true;

      await supabase
          .from('products')
          .update({'stok': stokAktual})
          .eq('id', productId);

      await _transactionProvider?.addLog(
        productId: productId,
        productName: namaProduk,
        userId: userId,
        userName: userName,
        type: TransactionType.adjustment,
        jumlah: (stokAktual - stokSebelum).abs(),
        stokSebelum: stokSebelum,
        stokSesudah: stokAktual,
        catatan: catatan,
      );

      await fetchProducts();
      return true;
    } on PostgrestException catch (e) {
      _errorMessage = 'Gagal menyesuaikan stok: ${e.message}';
      notifyListeners();
      return false;
    }
  }
}
