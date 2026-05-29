// ============================================================
// MODEL CUSTOMER (PELANGGAN)
// ============================================================
// Merepresentasikan data pembeli (retail / grosir / member).
// Tabel Supabase: 'customers'
// ============================================================

class Customer {
  final String id;
  final String nama;
  final String? kontak;
  final String tipe; // 'retail' | 'grosir'
  final DateTime createdAt;

  const Customer({
    required this.id,
    required this.nama,
    this.kontak,
    this.tipe = 'retail',
    required this.createdAt,
  });

  String get tipeLabel {
    switch (tipe) {
      case 'grosir':
        return 'Grosir';
      case 'retail':
      default:
        return 'Retail';
    }
  }

  factory Customer.fromMap(Map<String, dynamic> data) {
    return Customer(
      id: data['id'] ?? '',
      nama: data['nama'] ?? '',
      kontak: data['kontak'],
      tipe: data['tipe'] ?? 'retail',
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'kontak': kontak,
      'tipe': tipe,
    };
  }

  Customer copyWith({
    String? id,
    String? nama,
    String? kontak,
    bool clearKontak = false,
    String? tipe,
    DateTime? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      kontak: clearKontak ? null : (kontak ?? this.kontak),
      tipe: tipe ?? this.tipe,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
