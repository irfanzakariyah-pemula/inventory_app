// ============================================================
// MODEL EXPENSE (BIAYA OPERASIONAL)
// ============================================================
// Merepresentasikan data pengeluaran operasional toko.
// Tabel Supabase: 'expenses'
// ============================================================

class Expense {
  final String id;
  final String kategori; // 'listrik' | 'gaji' | 'sewa' | 'transportasi' | 'operasional' | 'lainnya'
  final int jumlah;
  final String? keterangan;
  final DateTime tanggal;
  final String userId;
  final String userName;
  final DateTime createdAt;

  const Expense({
    required this.id,
    required this.kategori,
    required this.jumlah,
    this.keterangan,
    required this.tanggal,
    required this.userId,
    required this.userName,
    required this.createdAt,
  });

  String get kategoriLabel {
    switch (kategori) {
      case 'listrik':
        return 'Listrik & Air';
      case 'gaji':
        return 'Gaji Karyawan';
      case 'sewa':
        return 'Sewa Tempat';
      case 'transportasi':
        return 'Transportasi / Bensin';
      case 'operasional':
        return 'Operasional Toko';
      case 'lainnya':
      default:
        return 'Lain-lain';
    }
  }

  factory Expense.fromMap(Map<String, dynamic> data) {
    return Expense(
      id: data['id'] ?? '',
      kategori: data['kategori'] ?? 'lainnya',
      jumlah: data['jumlah'] ?? 0,
      keterangan: data['keterangan'],
      tanggal: data['tanggal'] != null
          ? DateTime.parse(data['tanggal'])
          : DateTime.now(),
      userId: data['user_id'] ?? '',
      userName: data['user_name'] ?? '',
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'kategori': kategori,
      'jumlah': jumlah,
      'keterangan': keterangan,
      'tanggal': tanggal.toIso8601String().substring(0, 10), // Hanya format YYYY-MM-DD
      'user_id': userId,
      'user_name': userName,
    };
  }

  Expense copyWith({
    String? id,
    String? kategori,
    int? jumlah,
    String? keterangan,
    bool clearKeterangan = false,
    DateTime? tanggal,
    String? userId,
    String? userName,
    DateTime? createdAt,
  }) {
    return Expense(
      id: id ?? this.id,
      kategori: kategori ?? this.kategori,
      jumlah: jumlah ?? this.jumlah,
      keterangan: clearKeterangan ? null : (keterangan ?? this.keterangan),
      tanggal: tanggal ?? this.tanggal,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
