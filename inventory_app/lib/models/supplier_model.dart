// ============================================================
// MODEL SUPPLIER
// ============================================================
// Merepresentasikan data vendor/pemasok barang di toko.
// Tabel Supabase: 'suppliers'
// ============================================================

class Supplier {
  final String id;
  final String nama;
  final String? kontak;
  final String? alamat;
  final DateTime createdAt;

  const Supplier({
    required this.id,
    required this.nama,
    this.kontak,
    this.alamat,
    required this.createdAt,
  });

  factory Supplier.fromMap(Map<String, dynamic> data) {
    return Supplier(
      id: data['id'] ?? '',
      nama: data['nama'] ?? '',
      kontak: data['kontak'],
      alamat: data['alamat'],
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'kontak': kontak,
      'alamat': alamat,
    };
  }

  Supplier copyWith({
    String? id,
    String? nama,
    String? kontak,
    bool clearKontak = false,
    String? alamat,
    bool clearAlamat = false,
    DateTime? createdAt,
  }) {
    return Supplier(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      kontak: clearKontak ? null : (kontak ?? this.kontak),
      alamat: clearAlamat ? null : (alamat ?? this.alamat),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
