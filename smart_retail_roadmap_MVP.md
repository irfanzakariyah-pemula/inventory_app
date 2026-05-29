# 🏪 Smart Retail — Roadmap MVP (Minimum Viable)
### Versi Kompres: Realistis Selesai Sebelum Akhir Semester

> **Versi Dokumen:** 2.0 (MVP Edition) | **Tanggal:** 23 Mei 2026  
> **Target:** Aplikasi berfungsi penuh sebagai Smart Retail dalam **3–4 minggu**

---

## 🎯 Filosofi MVP: Apa yang BENAR-BENAR Mendefinisikan "Smart Retail"?

Dari gambar referensi dan kebutuhan bisnis nyata, sebuah aplikasi disebut **Smart Retail** jika memenuhi 3 syarat utama:

```
1. Bisa MENJUAL      → Ada modul Kasir/POS yang mencatat transaksi penjualan
2. Bisa MEMANTAU     → Dashboard menampilkan KPI bisnis nyata (Omset, Transaksi)  
3. Bisa MENGANALISIS → Ada laporan dasar dan grafik penjualan
```

Semua fitur lain (Absensi, Hutang, Voucher, Cetak Promo, QR Sync) adalah **pelengkap**, bukan syarat minimum.

---

## ✂️ Fitur yang DIPOTONG dari Roadmap Lengkap (dan Alasannya)

| Fitur Dipotong | Alasan Tidak Masuk MVP |
|---|---|
| ~~Absensi Karyawan~~ | Tidak terkait langsung dengan retail, bisa pakai absensi manual |
| ~~Hutang & Piutang~~ | Fitur keuangan lanjutan, bisa dicatat manual sementara |
| ~~Purchase Order~~ | Stok masuk sudah bisa lewat `stock_update_screen.dart` yang ada |
| ~~Voucher / Promo~~ | POS bisa pakai diskon nominal langsung tanpa tabel voucher |
| ~~Cetak Struk PDF~~ | Struk cukup ditampilkan di layar (share screenshot) untuk MVP |
| ~~Responsive Desktop~~ | Fokus mobile dulu; desktop polish bisa belakangan |
| ~~QR Sync / Koneksi Android~~ | Fitur canggih, Supabase cloud sudah cukup untuk sinkronisasi |
| ~~Export Excel/PDF~~ | Screenshot dan data mentah dari Supabase cukup untuk demo |
| ~~Manajemen Kas (full)~~ | Kas otomatis tercatat dari penjualan; UI manual kas bisa belakangan |

**Yang tersisa = inti Smart Retail yang sesungguhnya.**

---

## ✅ Fitur MVP yang WAJIB Ada (Scope Final)

```
┌─────────────────────────────────────────────────────────────────┐
│                    SMART RETAIL MVP                             │
│                                                                 │
│  SUDAH ADA (Pertahankan semua):                                │
│  ✅ Login multi-role (Admin/Petugas)                           │
│  ✅ Master Produk lengkap (CRUD + gambar + barcode + harga)    │
│  ✅ Update Stok (masuk/keluar/penyesuaian)                     │
│  ✅ Log pergerakan stok                                        │
│  ✅ Deteksi stok kritis & expired                              │
│                                                                 │
│  YANG DITAMBAHKAN (MVP baru):                                  │
│  🆕 [1] Kasir / POS  — transaksi penjualan                    │
│  🆕 [2] Data Supplier — CRUD sederhana                        │
│  🆕 [3] Data Pelanggan — CRUD sederhana                       │
│  🆕 [4] Dashboard upgrade — KPI penjualan + grafik            │
│  🆕 [5] Laporan dasar — omset harian/bulanan, top produk      │
│  🆕 [6] Navigasi dikelompokkan sesuai gambar referensi        │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🗄️ Database Minimal yang Perlu Ditambahkan

Hanya **4 tabel baru** (dari 10 tabel di roadmap lengkap):

```sql
-- Jalankan SQL ini di Supabase SQL Editor

-- [1] SUPPLIER
CREATE TABLE suppliers (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nama       TEXT NOT NULL,
  kontak     TEXT,
  alamat     TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- [2] PELANGGAN
CREATE TABLE customers (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nama       TEXT NOT NULL,
  kontak     TEXT,
  tipe       TEXT DEFAULT 'retail',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- [3] HEADER PENJUALAN (satu record = satu struk kasir)
CREATE TABLE sales (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nomor_struk  TEXT,
  customer_id  UUID REFERENCES customers(id),
  user_id      UUID NOT NULL,
  user_name    TEXT NOT NULL,
  subtotal     INTEGER NOT NULL,
  diskon       INTEGER DEFAULT 0,
  total        INTEGER NOT NULL,
  bayar        INTEGER NOT NULL,
  kembalian    INTEGER NOT NULL,
  metode_bayar TEXT DEFAULT 'tunai',
  catatan      TEXT,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- [4] ITEM PENJUALAN (detail produk dalam satu struk)
CREATE TABLE sales_items (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sale_id     UUID NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
  product_id  UUID REFERENCES products(id),
  nama_produk TEXT NOT NULL,
  harga_jual  INTEGER NOT NULL,
  harga_beli  INTEGER NOT NULL,
  jumlah      INTEGER NOT NULL,
  subtotal    INTEGER NOT NULL
);

-- Enable RLS
ALTER TABLE suppliers   ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers   ENABLE ROW LEVEL SECURITY;
ALTER TABLE sales       ENABLE ROW LEVEL SECURITY;
ALTER TABLE sales_items ENABLE ROW LEVEL SECURITY;

-- Policy: izinkan semua operasi untuk user yang sudah login
CREATE POLICY "Allow authenticated" ON suppliers   FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Allow authenticated" ON customers   FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Allow authenticated" ON sales       FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Allow authenticated" ON sales_items FOR ALL USING (auth.role() = 'authenticated');
```

---

## 🗺️ ROADMAP MVP — 2 FASE (Total ±3–4 Minggu)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

 FASE A: FONDASI DATA & KASIR          [Minggu 1–2]
 ─────────────────────────────────────────────────────────
 □ Setup 4 tabel baru di Supabase          (Hari 1)
 □ Model: Supplier, Customer, Sales        (Hari 2)
 □ Provider: Supplier + Customer           (Hari 3)
 □ Screen: Kontak (tab Supplier+Customer)  (Hari 4)
 □ Provider: Sales (PALING PENTING)        (Hari 5–6)
 □ Screen: POS Kasir                       (Hari 6–9)
 □ Upgrade Navigasi (home_screen.dart)     (Hari 9)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

 FASE B: DASHBOARD & LAPORAN           [Minggu 3–4]
 ─────────────────────────────────────────────────────────
 □ Tambah package fl_chart                 (Hari 10)
 □ Upgrade Dashboard — KPI cards           (Hari 10–11)
 □ Chart omset 7 hari + Top Terlaris       (Hari 11–12)
 □ Screen Laporan dasar (3 tab)            (Hari 12–14)
 □ Testing menyeluruh + bug fixing         (Hari 14–15)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 📦 FASE A — Fondasi Data & Kasir

### A.1 — Model Baru (Hari 2)

**`lib/models/supplier_model.dart`**
```dart
class Supplier {
  final String id;
  final String nama;
  final String? kontak;
  final String? alamat;
  final DateTime createdAt;

  const Supplier({required this.id, required this.nama,
      this.kontak, this.alamat, required this.createdAt});

  factory Supplier.fromMap(Map<String, dynamic> data) => Supplier(
    id: data['id'], nama: data['nama'],
    kontak: data['kontak'], alamat: data['alamat'],
    createdAt: DateTime.parse(data['created_at']),
  );

  Map<String, dynamic> toMap() => {
    'nama': nama, 'kontak': kontak, 'alamat': alamat,
  };
}
```

**`lib/models/customer_model.dart`**
```dart
class Customer {
  final String id;
  final String nama;
  final String? kontak;
  final String tipe; // 'retail' | 'grosir'
  final DateTime createdAt;
  // fromMap(), toMap()
}
```

**`lib/models/sales_model.dart`**
```dart
class SalesTransaction {
  final String id;
  final String? nomorStruk;
  final String? customerId;
  final String? customerName;
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
  // fromMap(), toMap()
}

class SalesItem {
  final String? id;
  final String? saleId;
  final String? productId;
  final String namaProduk;
  final int hargaJual;
  final int hargaBeli;
  int jumlah;

  int get subtotal => hargaJual * jumlah;
  int get profit => (hargaJual - hargaBeli) * jumlah;
  // fromMap(), toMap()
}
```

---

### A.2 — Provider Baru (Hari 3 & 5–6)

**`lib/providers/supplier_provider.dart`**
- `fetchSuppliers()`, `addSupplier()`, `updateSupplier()`, `deleteSupplier()`
- `List<Supplier> get allSuppliers`
- `List<Supplier> searchSuppliers(String q)`

**`lib/providers/customer_provider.dart`**
- `fetchCustomers()`, `addCustomer()`, `updateCustomer()`, `deleteCustomer()`
- `List<Customer> get allCustomers`
- `searchCustomers(String q)`

**`lib/providers/sales_provider.dart`** ← *PALING KRITIS*
```dart
class SalesProvider extends ChangeNotifier {
  // ─── Getter KPI untuk Dashboard ───
  int get omsetHariIni      // Total Rp hari ini
  int get jumlahTransaksiHariIni  // Jumlah struk hari ini
  int get profitHariIni     // Total profit hari ini
  int get omsetBulanIni     // Total Rp bulan ini
  
  // ─── Getter Chart ───
  List<Map<String, dynamic>> get omset7Hari     // [{tanggal, total}]
  List<Map<String, dynamic>> get top5Terlaris   // [{nama, jumlahTerjual}]

  // ─── Method Utama ───
  Future<void> fetchSales()
  Future<bool> createSale({
    required List<SalesItem> items,
    required String userId,
    required String userName,
    required int bayar,
    required String metodeBayar,
    String? customerId,
    String? customerName,
    int diskon = 0,
  })
  // Di dalam createSale():
  //  1. Hitung subtotal, total, kembalian
  //  2. Generate nomor struk (STR-YYYYMMDD-NNN)
  //  3. Insert ke tabel 'sales'
  //  4. Insert semua ke tabel 'sales_items'
  //  5. Kurangi stok tiap produk via ProductProvider.updateStock()
  //  6. Refresh data lokal
}
```

---

### A.3 — Screen Kontak (Hari 4)
**`lib/screens/contact_screen.dart`** — Tab Supplier + Pelanggan

```
ContactScreen
├── TabBar: [Supplier] [Pelanggan]
│
├── Tab Supplier:
│   ├── Search bar
│   ├── ListView: Card(nama, kontak, alamat, edit/hapus)
│   └── FAB → BottomSheet form tambah/edit
│
└── Tab Pelanggan:
    ├── Search bar
    ├── ListView: Card(nama, kontak, badge tipe Retail/Grosir, edit/hapus)
    └── FAB → BottomSheet form tambah/edit
```

*Gunakan BottomSheet — tidak perlu screen terpisah untuk hemat waktu.*

---

### A.4 — Screen POS Kasir (Hari 6–9) ← *TERPENTING*
**`lib/screens/pos_screen.dart`**

**Layout (gunakan Stack/Column untuk mobile):**
```
AppBar: "Kasir" | [🗑️ Kosongkan] | [Rp total keranjang]

Body:
├── Search bar + daftar produk (bisa diklik)
└── BottomSheet keranjang (persistentBottomSheet)
    ├── List item keranjang (swipe to remove, +/- qty)
    ├── Divider
    ├── Subtotal / Diskon / TOTAL
    ├── Pilih metode bayar: [Tunai] [Transfer] [QRIS]
    ├── Input nominal bayar → Kembalian otomatis
    └── [Tombol BAYAR SEKARANG]
```

**Setelah BAYAR berhasil:**
```
Dialog Sukses:
  ✅ Transaksi Berhasil!
  Nomor: STR-20260523-001
  Total: Rp 85.000
  Bayar: Rp 100.000
  Kembalian: Rp 15.000
  
  [Transaksi Baru] [Tutup]
```

---

### A.5 — Upgrade Navigasi (Hari 9)
**Modifikasi `home_screen.dart`:**

```
TRANSAKSI
  ├─ 🛒 Kasir / POS        ← BARU (index baru)
  └─ 📦 Update Stok         (existing, pindah ke sini)

DATA
  ├─ 🏪 Master Barang       (existing)
  ├─ 🤝 Kontak              ← BARU (supplier + customer)
  └─ 📜 Log Stok            (existing)

LAPORAN
  └─ 📊 Laporan Penjualan   ← BARU

SYSTEM
  └─ 🚪 Keluar              (existing)
```

---

## 📊 FASE B — Dashboard Upgrade & Laporan

### B.1 — Upgrade Dashboard KPI (Hari 10–11)
**Modifikasi `dashboard_screen.dart`:**

Ganti 4 kartu lama menjadi kartu yang relevan dengan retail:

```
Kartu 1: 💰 Penjualan Hari Ini → SalesProvider.omsetHariIni
Kartu 2: 🧾 Transaksi Hari Ini → SalesProvider.jumlahTransaksiHariIni  
Kartu 3: 📈 Profit Hari Ini    → SalesProvider.profitHariIni
Kartu 4: ⚠️ Stok Limit        → ProductProvider.jumlahStokKritis (existing)
```

### B.2 — Tambah Chart (Hari 11–12)
Setelah 4 kartu KPI, tambahkan 2 widget chart:

**Widget 1: Bar Chart "Omset 7 Hari Terakhir"**
```dart
// fl_chart BarChart
// Data dari: SalesProvider.omset7Hari
// X: nama hari (Sen, Sel, Rab, ...)
// Y: total omset dalam Rp (tampilkan dalam ribuan)
```

**Widget 2: List "Top 5 Produk Terlaris"**
```dart
// Bisa pakai LinearProgressIndicator biasa (tidak perlu chart)
// Data dari: SalesProvider.top5Terlaris
// Tampilkan: ranking, nama produk, jumlah terjual, progress bar
```

### B.3 — Screen Laporan (Hari 12–14)
**`lib/screens/report_screen.dart`** — 3 Tab sederhana:

**Tab 1: Ringkasan**
```
Periode: [Hari Ini] [Minggu Ini] [Bulan Ini]
─────────────────────────────────────────────
Omset:          Rp 1.250.000
Profit Est.:    Rp 312.500  (25%)
Transaksi:      18 struk
Rata-rata/struk: Rp 69.444
```

**Tab 2: Riwayat Penjualan**
```
List card per transaksi:
┌──────────────────────────────────────────┐
│ STR-20260523-001              Rp 85.000  │
│ 3 item • Tunai • 23 Mei 10:23           │
│ Kasir: Admin                            │
└──────────────────────────────────────────┘
← Tap untuk lihat detail item dalam struk
```

**Tab 3: Top Produk**
```
#1  Gudang Garam      terjual: 47 pcs  ████████████
#2  Susu Ultra Milk   terjual: 31 pcs  ████████
#3  Indomie Goreng    terjual: 28 pcs  ███████
...
```

---

## 📁 Ringkasan Perubahan File

### ✅ File BARU (9 file, semua harus dibuat):
```
lib/models/supplier_model.dart
lib/models/customer_model.dart
lib/models/sales_model.dart
lib/providers/supplier_provider.dart
lib/providers/customer_provider.dart
lib/providers/sales_provider.dart      ← PALING KRITIS
lib/screens/pos_screen.dart            ← TERPENTING
lib/screens/contact_screen.dart
lib/screens/report_screen.dart
```

### 🔧 File LAMA yang Dimodifikasi (3 file):
```
lib/main.dart                 ← Daftarkan 3 provider baru
lib/screens/home_screen.dart  ← Kelompokkan menu drawer
lib/screens/dashboard_screen.dart ← Tambah KPI + 2 chart
```

### 🔒 File TIDAK BERUBAH (9 file — aman biarkan):
```
lib/models/product_model.dart
lib/models/user_model.dart
lib/providers/auth_provider.dart
lib/providers/product_provider.dart
lib/providers/transaction_provider.dart
lib/screens/login_screen.dart
lib/screens/product_list_screen.dart
lib/screens/product_form_screen.dart
lib/screens/stock_update_screen.dart
lib/screens/transaction_log_screen.dart
lib/screens/profile_screen.dart
```

---

## 📦 Dependencies — Hanya 1 Tambahan

```yaml
# pubspec.yaml — tambahkan satu baris ini saja:
fl_chart: ^0.69.0    # Bar chart untuk dashboard
```

---

## 📊 Perbandingan Roadmap Lengkap vs MVP

| Aspek | Roadmap Lengkap | **MVP Ini** |
|---|---|---|
| Tabel database baru | 10 tabel | **4 tabel** |
| File baru dibuat | 23 file | **9 file** |
| File lama dimodifikasi | 5 file | **3 file** |
| Package baru | 7 package | **1 package** |
| Estimasi waktu | 10–13 minggu | **3–4 minggu** |
| Kasir / POS | ✅ Lengkap | ✅ Fungsional |
| Dashboard KPI | ✅ Penuh | ✅ Esensial |
| Laporan | ✅ Laba Rugi lengkap | ✅ Ringkasan + riwayat |
| **Disebut Smart Retail?** | ✅ Enterprise-grade | ✅ **Ya, MVP fungsional** |

---

## 🏁 Demo Points — Yang Bisa Ditunjukkan Saat Presentasi

1. **Login** sebagai Admin → akses penuh semua menu
2. **Dashboard** → tampilkan KPI Penjualan Hari Ini, Grafik Omset, Top Terlaris
3. **POS/Kasir** → tambah 3 produk ke keranjang, bayar tunai, lihat kembalian → struk muncul
4. **Verifikasi stok berkurang** → buka Master Barang, stok produk terjual sudah berkurang otomatis
5. **Kontak** → tampilkan daftar supplier dan pelanggan
6. **Laporan** → tampilkan ringkasan omset dan riwayat transaksi hari ini
7. **Log Stok** → perubahan stok dari penjualan POS tercatat otomatis

> **💡 Tips Demo:** Isi dulu minimal 10 produk, 3 supplier, 3 pelanggan sebelum presentasi agar dashboard terlihat hidup dan kaya data.

---

> **Referensi Roadmap Lengkap (untuk pengembangan pasca-semester):**  
> [smart_retail_roadmap.md](file:///C:/Users/WINDOWS%2011/.gemini/antigravity-ide/brain/139837ac-cbce-440c-8177-f865cd896289/smart_retail_roadmap.md)
