// ============================================================
// MODEL PENJUALAN (SALES)
// ============================================================
// Merepresentasikan satu transaksi penjualan di kasir/POS.
// Terdiri dari 2 class:
//   [1] SalesItem     — Satu baris produk dalam sebuah struk
//   [2] SalesTransaction — Header struk penjualan (1 transaksi lengkap)
//
// Tabel Supabase: 'sales' (header) dan 'sales_items' (detail)
// ============================================================

// ============================================================
// [1] SALES ITEM — Detail baris produk dalam struk
// ============================================================

class SalesItem {
  final String? id;
  final String? saleId;
  final String? productId;
  final String namaProduk;
  final int hargaJual;
  final int hargaBeli;
  int jumlah;
  final String satuan;

  SalesItem({
    this.id,
    this.saleId,
    this.productId,
    required this.namaProduk,
    required this.hargaJual,
    required this.hargaBeli,
    this.jumlah = 1,
    this.satuan = 'pcs',
  });

  // ==================== GETTER ====================

  /// Total harga untuk item ini (harga × jumlah).
  int get subtotal => hargaJual * jumlah;

  /// Keuntungan bersih untuk item ini ((jual - beli) × jumlah).
  int get profit => (hargaJual - hargaBeli) * jumlah;

  // ==================== SERIALIZATION ====================

  /// Factory constructor dari Map Supabase (hasil query PostgreSQL).
  factory SalesItem.fromMap(Map<String, dynamic> data) {
    return SalesItem(
      id: data['id'],
      saleId: data['sale_id'],
      productId: data['product_id'],
      namaProduk: data['nama_produk'] ?? '',
      hargaJual: (data['harga_jual'] ?? 0) as int,
      hargaBeli: (data['harga_beli'] ?? 0) as int,
      jumlah: (data['jumlah'] ?? 1) as int,
      satuan: data['satuan'] ?? 'pcs',
    );
  }

  /// Konversi ke Map untuk dikirim ke Supabase.
  Map<String, dynamic> toMap() {
    return {
      if (saleId != null) 'sale_id': saleId,
      if (productId != null) 'product_id': productId,
      'nama_produk': namaProduk,
      'harga_jual': hargaJual,
      'harga_beli': hargaBeli,
      'jumlah': jumlah,
      'subtotal': subtotal,
      'satuan': satuan,
    };
  }

  /// Membuat salinan item ini dengan jumlah yang diubah.
  SalesItem copyWith({
    String? id,
    String? saleId,
    String? productId,
    String? namaProduk,
    int? hargaJual,
    int? hargaBeli,
    int? jumlah,
    String? satuan,
  }) {
    return SalesItem(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      productId: productId ?? this.productId,
      namaProduk: namaProduk ?? this.namaProduk,
      hargaJual: hargaJual ?? this.hargaJual,
      hargaBeli: hargaBeli ?? this.hargaBeli,
      jumlah: jumlah ?? this.jumlah,
      satuan: satuan ?? this.satuan,
    );
  }
}

// ============================================================
// [2] SALES TRANSACTION — Header / Struk penjualan lengkap
// ============================================================

class SalesTransaction {
  final String id;
  final String? nomorStruk;
  final String userId;
  final String userName;
  final List<SalesItem> items;
  final int subtotal;
  final int diskon;
  final int total;
  final int bayar;
  final int kembalian;
  final String metodeBayar; // 'tunai' | 'transfer' | 'qris'
  final String? catatan;
  final DateTime createdAt;

  const SalesTransaction({
    required this.id,
    this.nomorStruk,
    required this.userId,
    required this.userName,
    this.items = const [],
    required this.subtotal,
    this.diskon = 0,
    required this.total,
    required this.bayar,
    required this.kembalian,
    this.metodeBayar = 'tunai',
    this.catatan,
    required this.createdAt,
  });

  // ==================== GETTER ====================

  /// Total keuntungan dari seluruh item dalam transaksi ini.
  int get totalProfit => items.fold(0, (sum, item) => sum + item.profit);

  /// Jumlah total item (qty) dalam transaksi ini.
  int get totalItem => items.fold(0, (sum, item) => sum + item.jumlah);

  // ==================== SERIALIZATION ====================

  /// Factory constructor dari Map Supabase.
  /// [items] di-pass terpisah setelah query join (opsional).
  factory SalesTransaction.fromMap(
    Map<String, dynamic> data, {
    List<SalesItem>? items,
  }) {
    return SalesTransaction(
      id: data['id'] ?? '',
      nomorStruk: data['nomor_struk'],
      userId: data['user_id'] ?? '',
      userName: data['user_name'] ?? '',
      items: items ?? [],
      subtotal: (data['subtotal'] ?? 0) as int,
      diskon: (data['diskon'] ?? 0) as int,
      total: (data['total'] ?? 0) as int,
      bayar: (data['bayar'] ?? 0) as int,
      kembalian: (data['kembalian'] ?? 0) as int,
      metodeBayar: data['metode_bayar'] ?? 'tunai',
      catatan: data['catatan'],
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : DateTime.now(),
    );
  }

  /// Konversi ke Map untuk disimpan ke Supabase.
  Map<String, dynamic> toMap() {
    return {
      if (nomorStruk != null) 'nomor_struk': nomorStruk,
      'user_id': userId,
      'user_name': userName,
      'subtotal': subtotal,
      'diskon': diskon,
      'total': total,
      'bayar': bayar,
      'kembalian': kembalian,
      'metode_bayar': metodeBayar,
      if (catatan != null) 'catatan': catatan,
    };
  }
}
