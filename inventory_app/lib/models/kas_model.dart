// ============================================================
// MODEL KAS (BUKU BESAR ARUS KAS)
// ============================================================
// Merepresentasikan data aliran kas masuk dan keluar.
// Tabel Supabase: 'kas'
// ============================================================

class KasTransaction {
  final String id;
  final String tipe; // 'masuk' | 'keluar'
  final String kategori; // 'penjualan' | 'modal' | 'biaya' | 'pembelian' | 'tarik' | 'lainnya'
  final int jumlah;
  final String? keterangan;
  final String? saleId;
  final String userId;
  final String userName;
  final DateTime createdAt;

  const KasTransaction({
    required this.id,
    required this.tipe,
    required this.kategori,
    required this.jumlah,
    this.keterangan,
    this.saleId,
    required this.userId,
    required this.userName,
    required this.createdAt,
  });

  String get kategoriLabel {
    switch (kategori) {
      case 'penjualan':
        return 'Penjualan POS';
      case 'modal':
        return 'Setoran Modal';
      case 'biaya':
        return 'Biaya Operasional';
      case 'pembelian':
        return 'Pembelian Supplier';
      case 'tarik':
        return 'Tarik Kas (Prive)';
      case 'lainnya':
      default:
        return 'Lain-lain';
    }
  }

  factory KasTransaction.fromMap(Map<String, dynamic> data) {
    return KasTransaction(
      id: data['id'] ?? '',
      tipe: data['tipe'] ?? 'masuk',
      kategori: data['kategori'] ?? 'lainnya',
      jumlah: data['jumlah'] ?? 0,
      keterangan: data['keterangan'],
      saleId: data['sale_id'],
      userId: data['user_id'] ?? '',
      userName: data['user_name'] ?? '',
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tipe': tipe,
      'kategori': kategori,
      'jumlah': jumlah,
      'keterangan': keterangan,
      'sale_id': saleId,
      'user_id': userId,
      'user_name': userName,
    };
  }

  KasTransaction copyWith({
    String? id,
    String? tipe,
    String? kategori,
    int? jumlah,
    String? keterangan,
    bool clearKeterangan = false,
    String? saleId,
    bool clearSaleId = false,
    String? userId,
    String? userName,
    DateTime? createdAt,
  }) {
    return KasTransaction(
      id: id ?? this.id,
      tipe: tipe ?? this.tipe,
      kategori: kategori ?? this.kategori,
      jumlah: jumlah ?? this.jumlah,
      keterangan: clearKeterangan ? null : (keterangan ?? this.keterangan),
      saleId: clearSaleId ? null : (saleId ?? this.saleId),
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
