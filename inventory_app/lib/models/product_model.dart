// ============================================================
// MODEL PRODUK & LOG TRANSAKSI - Versi Supabase
// ============================================================
// Versi ini tidak lagi bergantung pada cloud_firestore.
// Semua data dibaca dari PostgreSQL Supabase sebagai Map<String, dynamic>.
//
// [1] Class Product  — Blueprint data barang di gudang.
//     Field lengkap versi Minimarket:
//       - barcode      : Kode EAN-13/UPC dari kemasan fisik barang
//       - hargaBeli    : Harga modal / beli (untuk kalkulasi profit)
//       - hargaJual    : Harga eceran / jual ke konsumen
//       - expiredDate  : Tanggal kedaluwarsa (null jika tidak berlaku)
//       - imageUrl     : URL gambar dari Supabase Storage
//
// [2] Enum TransactionType — Jenis perubahan stok.
//     Nilai: masuk | keluar | adjustment
//
// [3] Class TransactionLog — Riwayat setiap perubahan stok.
// ============================================================

// ============================================================
// [1] MODEL PRODUK
// ============================================================

/// Model data produk/barang yang tersimpan di tabel 'products' Supabase.
class Product {
  final String id;           // UUID dari Supabase (auto-generated)
  final String nama;         // Nama lengkap barang
  final String sku;          // Stock Keeping Unit — kode unik internal toko
  final String barcode;      // Kode barcode fisik kemasan (EAN-13 / UPC-A)
  final String kategori;     // Kategori barang (Minuman, Snack, Sembako, dll)
  int stok;                  // Jumlah stok saat ini
  final int stokMinimum;     // Ambang batas minimum stok sebelum dianggap kritis
  final String rakLokasi;    // Lokasi rak penyimpanan fisik di toko/gudang
  final int hargaBeli;       // Harga beli / modal per unit (dalam Rupiah)
  final int hargaJual;       // Harga jual ke konsumen per unit (dalam Rupiah)
  final DateTime? expiredDate; // Tanggal kedaluwarsa (null jika tidak ada)
  final String? imageUrl;    // URL gambar produk dari Supabase Storage
  final String satuan;       // Satuan kuantitas barang (pcs, kg, pack, dus, dll)

  Product({
    required this.id,
    required this.nama,
    required this.sku,
    required this.barcode,
    required this.kategori,
    required this.stok,
    required this.stokMinimum,
    required this.rakLokasi,
    required this.hargaBeli,
    required this.hargaJual,
    this.satuan = 'pcs',
    this.expiredDate,
    this.imageUrl,
  });

  // ==================== GETTER ====================

  /// True jika stok barang sudah di bawah batas minimum.
  bool get isStokKritis => stok < stokMinimum;

  /// True jika barang ini memiliki tanggal kedaluwarsa yang terdaftar.
  bool get hasExpiredDate => expiredDate != null;

  /// Menghitung sisa hari hingga kedaluwarsa dari hari ini.
  int? get sisaHariExpired {
    if (expiredDate == null) return null;
    final now = DateTime.now();
    return expiredDate!
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
  }

  /// True jika barang sudah melampaui tanggal kedaluwarsa.
  bool get isSudahExpired {
    final sisa = sisaHariExpired;
    return sisa != null && sisa <= 0;
  }

  /// True jika barang akan kedaluwarsa dalam 30 hari ke depan.
  bool get isMendekatiExpired {
    final sisa = sisaHariExpired;
    return sisa != null && sisa > 0 && sisa <= 30;
  }

  /// Menghitung margin profit per unit dalam Rupiah.
  int get marginProfit => hargaJual - hargaBeli;

  /// Menghitung persentase margin profit terhadap harga beli.
  double get persenMargin {
    if (hargaBeli == 0) return 0;
    return (marginProfit / hargaBeli) * 100;
  }

  // ==================== SERIALIZATION ====================

  /// Factory constructor dari Map Supabase (hasil query PostgreSQL).
  /// Nama kolom di Supabase menggunakan snake_case sesuai konvensi SQL.
  factory Product.fromMap(Map<String, dynamic> data) {
    return Product(
      id: data['id'] ?? '',
      nama: data['nama'] ?? '',
      sku: data['sku'] ?? '',
      barcode: data['barcode'] ?? data['sku'] ?? '',
      kategori: data['kategori'] ?? '',
      stok: (data['stok'] ?? 0) as int,
      stokMinimum: (data['stok_minimum'] ?? 0) as int,
      rakLokasi: data['rak_lokasi'] ?? '',
      hargaBeli: (data['harga_beli'] ?? 0) as int,
      hargaJual: (data['harga_jual'] ?? 0) as int,
      satuan: data['satuan'] ?? 'pcs',
      // Supabase mengembalikan datetime sebagai String ISO 8601
      expiredDate: data['expired_date'] != null
          ? DateTime.parse(data['expired_date'])
          : null,
      imageUrl: data['image_url'],
    );
  }

  /// Konversi ke Map untuk disimpan/diperbarui ke Supabase.
  /// Nama key menggunakan snake_case sesuai nama kolom di PostgreSQL.
  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'sku': sku,
      'barcode': barcode,
      'kategori': kategori,
      'stok': stok,
      'stok_minimum': stokMinimum,
      'rak_lokasi': rakLokasi,
      'harga_beli': hargaBeli,
      'harga_jual': hargaJual,
      'satuan': satuan,
      // Simpan expiredDate sebagai String ISO 8601, atau null
      'expired_date': expiredDate?.toIso8601String(),
      'image_url': imageUrl,
    };
  }

  /// Membuat salinan objek Product dengan nilai tertentu yang bisa diubah.
  Product copyWith({
    String? id,
    String? nama,
    String? sku,
    String? barcode,
    String? kategori,
    int? stok,
    int? stokMinimum,
    String? rakLokasi,
    int? hargaBeli,
    int? hargaJual,
    String? satuan,
    DateTime? expiredDate,
    bool clearExpiredDate = false,
    String? imageUrl,
    bool clearImageUrl = false,
  }) {
    return Product(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      kategori: kategori ?? this.kategori,
      stok: stok ?? this.stok,
      stokMinimum: stokMinimum ?? this.stokMinimum,
      rakLokasi: rakLokasi ?? this.rakLokasi,
      hargaBeli: hargaBeli ?? this.hargaBeli,
      hargaJual: hargaJual ?? this.hargaJual,
      satuan: satuan ?? this.satuan,
      expiredDate: clearExpiredDate ? null : (expiredDate ?? this.expiredDate),
      imageUrl: clearImageUrl ? null : (imageUrl ?? this.imageUrl),
    );
  }
}

// ============================================================
// [2] ENUM TIPE TRANSAKSI
// ============================================================

/// Enum untuk mendefinisikan jenis perubahan stok yang terjadi.
enum TransactionType { masuk, keluar, adjustment }

// ============================================================
// [3] MODEL LOG TRANSAKSI
// ============================================================

/// Model log yang merekam setiap event perubahan stok.
class TransactionLog {
  final String id;
  final String productId;
  final String productName;
  final String userId;
  final String userName;
  final TransactionType type;
  final int jumlah;
  final int stokSebelum;
  final int stokSesudah;
  final DateTime waktu;
  final String catatan;

  const TransactionLog({
    required this.id,
    required this.productId,
    required this.productName,
    required this.userId,
    required this.userName,
    required this.type,
    required this.jumlah,
    required this.stokSebelum,
    required this.stokSesudah,
    required this.waktu,
    this.catatan = '',
  });

  // ==================== GETTER ====================

  String get typeLabel {
    switch (type) {
      case TransactionType.masuk:
        return 'Stok Masuk';
      case TransactionType.keluar:
        return 'Stok Keluar';
      case TransactionType.adjustment:
        return 'Penyesuaian Stok';
    }
  }

  // ==================== SERIALIZATION ====================

  /// Factory constructor dari Map Supabase (hasil query PostgreSQL).
  factory TransactionLog.fromMap(Map<String, dynamic> data) {
    TransactionType typeFromString(String? typeStr) {
      switch (typeStr) {
        case 'keluar':
          return TransactionType.keluar;
        case 'adjustment':
          return TransactionType.adjustment;
        case 'masuk':
        default:
          return TransactionType.masuk;
      }
    }

    return TransactionLog(
      id: data['id'] ?? '',
      productId: data['product_id'] ?? '',
      productName: data['product_name'] ?? '',
      userId: data['user_id'] ?? '',
      userName: data['user_name'] ?? '',
      type: typeFromString(data['type']),
      jumlah: (data['jumlah'] ?? 0) as int,
      stokSebelum: (data['stok_sebelum'] ?? 0) as int,
      stokSesudah: (data['stok_sesudah'] ?? 0) as int,
      // Supabase mengembalikan timestamp sebagai String ISO 8601
      waktu: data['waktu'] != null
          ? DateTime.parse(data['waktu'])
          : DateTime.now(),
      catatan: data['catatan'] ?? '',
    );
  }

  /// Konversi ke Map untuk disimpan ke Supabase.
  Map<String, dynamic> toMap() {
    String typeToString(TransactionType type) {
      switch (type) {
        case TransactionType.masuk:
          return 'masuk';
        case TransactionType.keluar:
          return 'keluar';
        case TransactionType.adjustment:
          return 'adjustment';
      }
    }

    return {
      'product_id': productId,
      'product_name': productName,
      'user_id': userId,
      'user_name': userName,
      'type': typeToString(type),
      'jumlah': jumlah,
      'stok_sebelum': stokSebelum,
      'stok_sesudah': stokSesudah,
      'waktu': waktu.toIso8601String(),
      'catatan': catatan,
    };
  }
}
