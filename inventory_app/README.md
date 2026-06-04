<h1 align="center">
  <br>
  🏪 Smart Retail Inventory
  <br>
</h1>

<h4 align="center">Aplikasi manajemen stok & kasir minimarket berbasis <a href="https://flutter.dev" target="_blank">Flutter</a> dengan backend <a href="https://supabase.com" target="_blank">Supabase</a>.</h4>

<p align="center">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white">
  <img alt="Dart" src="https://img.shields.io/badge/Dart-3.11-0175C2?style=for-the-badge&logo=dart&logoColor=white">
  <img alt="Supabase" src="https://img.shields.io/badge/Supabase-2.x-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white">
  <img alt="License" src="https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge">
  <img alt="Version" src="https://img.shields.io/badge/Version-1.0.0-blueviolet?style=for-the-badge">
</p>

<p align="center">
  <a href="#-fitur-utama">Fitur</a> •
  <a href="#️-arsitektur--teknologi">Arsitektur</a> •
  <a href="#-struktur-proyek">Struktur</a> •
  <a href="#-instalasi--setup">Instalasi</a> •
  <a href="#-screenshot">Screenshot</a> •
  <a href="#-kontribusi">Kontribusi</a>
</p>

---

## 📋 Deskripsi

**Smart Retail Inventory** adalah aplikasi manajemen toko serba ada (minimarket) yang dibangun dengan Flutter dan Supabase. Dirancang untuk membantu pemilik toko kecil hingga menengah dalam mengelola stok produk, proses transaksi kasir (POS), keuangan, dan laporan bisnis secara real-time — semuanya dalam satu aplikasi mobile.

> Aplikasi ini mendukung **multi-role user** (Admin & Kasir), **dark/light mode**, dan data real-time melalui Supabase.

---

## ✨ Fitur Utama

### 🏠 Dashboard
- **4 KPI Cards Live** — Omset Hari Ini, Jumlah Transaksi, Profit, dan Stok Kritis
- **Bar Chart Interaktif** — Visualisasi omset 7 hari terakhir (powered by `fl_chart`)
- **Top 5 Produk Terlaris** — Dengan podium dan progress bar ranking
- **Alert Stok Kritis** — Notifikasi produk yang stoknya hampir habis
- **Alert Kedaluwarsa** — Peringatan produk yang mendekati tanggal expired

### 🛒 Kasir / POS
- **Pencarian Produk** — Cari berdasarkan nama, SKU, atau barcode
- **Keranjang Belanja** — DraggableScrollableSheet interaktif
- **Kalkulasi Otomatis** — Subtotal, diskon, total, dan kembalian
- **Multi Metode Bayar** — Tunai, transfer, QRIS, dll.
- **Pilih Pelanggan** — Untuk riwayat transaksi per pelanggan
- **Struk Digital** — Dialog sukses dengan ringkasan transaksi

### 📦 Manajemen Produk
- **CRUD Lengkap** — Tambah, edit, hapus produk
- **Upload Gambar** — Dari galeri atau kamera (`image_picker`)
- **Tampilan Gambar Cache** — Performa optimal dengan `cached_network_image`
- **Filter & Pencarian** — Berdasarkan kategori, nama, SKU
- **Update Stok** — Fitur khusus update stok masuk/keluar

### 💰 Buku Kas Toko
- **Saldo Real-time** — Saldo kas terupdate otomatis dari transaksi POS
- **Kas Masuk / Keluar** — Pencatatan manual setoran modal dan tarik kas
- **Ledger History** — Riwayat aliran dana lengkap dengan filter dan pencarian
- **Kategori Transaksi** — Modal, tarik (prive), dan lain-lain

### 💸 Biaya Operasional
- **Catat Pengeluaran** — Biaya listrik, gaji, sewa, dan lainnya
- **Integrasi Laporan** — Biaya operasional masuk ke perhitungan laba bersih

### 📊 Laporan Bisnis (3 Tab)
| Tab | Konten |
|-----|--------|
| **Ringkasan** | KPI omset, profit, jumlah struk, rata-rata per struk |
| **Transaksi** | Riwayat struk expandable dengan detail item |
| **Terlaris** | Top produk dengan podium dan progress bar |
- **Filter Periode** — Hari ini, 7 hari, bulan ini
- **Laporan Laba Rugi Riil** — HPP → Laba Kotor → Biaya Operasional → **Laba Bersih**
- **Breakdown Metode Bayar** — Pie/bar breakdown per metode pembayaran

### 👥 Manajemen Data Master
- **Supplier** — Data pemasok produk
- **Customer / Pelanggan** — Riwayat pembelian per pelanggan
- **Profil Pengguna** — Edit profil, ganti password, dark/light mode toggle

### 🔐 Autentikasi
- Login berbasis Supabase Auth
- Role-based access control (Admin vs Kasir)
- Session management otomatis

---

## 🏗️ Arsitektur & Teknologi

### Tech Stack

| Kategori | Library | Versi |
|----------|---------|-------|
| **Framework** | Flutter | `≥3.x` |
| **Language** | Dart | `^3.11.1` |
| **Backend & Auth** | supabase_flutter | `^2.9.0` |
| **State Management** | provider | `^6.1.2` |
| **UI Font** | google_fonts | `^6.2.1` |
| **Charts** | fl_chart | `^0.69.0` |
| **Image Picker** | image_picker | `^1.1.2` |
| **Image Cache** | cached_network_image | `^3.4.1` |
| **Date Format** | intl | `^0.20.2` |

### Pola Arsitektur

Aplikasi ini menggunakan pola **Provider Pattern** (MVVM-like):

```
┌──────────────────────────────────────────────────┐
│                    UI Layer                       │
│  (Screens & Widgets — lib/screens, lib/widgets)  │
└────────────────────┬─────────────────────────────┘
                     │  Consumer / Provider.of
┌────────────────────▼─────────────────────────────┐
│               State Layer (Providers)             │
│  AuthProvider, ProductProvider, SalesProvider,    │
│  KasProvider, ExpenseProvider, ...                │
└────────────────────┬─────────────────────────────┘
                     │  supabase.from().select()
┌────────────────────▼─────────────────────────────┐
│               Data Layer (Supabase)               │
│  PostgreSQL + Storage + Auth                      │
└──────────────────────────────────────────────────┘
```

---

## 📁 Struktur Proyek

```
inventory_app/
├── lib/
│   ├── main.dart                    # Entry point, MultiProvider setup
│   ├── models/                      # Data models
│   │   ├── product_model.dart
│   │   ├── sales_model.dart
│   │   ├── kas_model.dart
│   │   ├── expense_model.dart
│   │   ├── customer_model.dart
│   │   ├── supplier_model.dart
│   │   └── user_model.dart
│   ├── providers/                   # State management
│   │   ├── auth_provider.dart
│   │   ├── product_provider.dart
│   │   ├── sales_provider.dart
│   │   ├── kas_provider.dart
│   │   ├── expense_provider.dart
│   │   ├── customer_provider.dart
│   │   ├── supplier_provider.dart
│   │   └── transaction_provider.dart
│   ├── screens/                     # Halaman utama
│   │   ├── login_screen.dart
│   │   ├── home_screen.dart         # Scaffold + Drawer navigasi
│   │   ├── dashboard_screen.dart    # KPI + chart + stok kritis
│   │   ├── pos_screen.dart          # Kasir / Point of Sale
│   │   ├── product_list_screen.dart
│   │   ├── product_form_screen.dart
│   │   ├── stock_update_screen.dart
│   │   ├── report_screen.dart       # Laporan 3 tab
│   │   ├── kas_screen.dart          # Buku kas toko
│   │   ├── expense_screen.dart      # Biaya operasional
│   │   ├── contact_screen.dart      # Supplier & Customer
│   │   ├── transaction_log_screen.dart
│   │   └── profile_screen.dart
│   ├── widgets/                     # Reusable components
│   └── theme/
│       └── app_theme.dart           # Light & Dark theme Material 3
├── pubspec.yaml
└── README.md
```

---

## 🚀 Instalasi & Setup

### Prasyarat

Pastikan tools berikut sudah terinstall:

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.x
- [Dart SDK](https://dart.dev/get-dart) ≥ 3.11
- Android Studio / VS Code
- Akun [Supabase](https://supabase.com)

### 1. Clone Repository

```bash
git clone https://github.com/irfanzakariyah-pemula/inventory_app.git
cd inventory_app
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Setup Supabase

Buat proyek baru di [supabase.com](https://supabase.com), lalu jalankan script SQL yang sudah disediakan di file [`supabase_setup.sql`](../supabase_setup.sql) pada **Supabase SQL Editor**.

Script tersebut secara otomatis akan:
- Membuat semua tabel yang dibutuhkan (`suppliers`, `customers`, `sales`, `sales_items`, `kas`, `expenses`)
- Mengaktifkan **Row Level Security (RLS)** pada setiap tabel
- Membuat **Security Policies** agar hanya user yang terautentikasi yang bisa mengakses data
- Membuat **PostgreSQL RPC Function** `checkout_transaction()` untuk transaksi POS yang **atomic & aman** (mencegah race condition dan stok minus)

<details>
<summary>📋 Klik untuk preview skema SQL lengkap</summary>

```sql
-- ==================== [1] SUPPLIER ====================
CREATE TABLE IF NOT EXISTS suppliers (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nama       TEXT NOT NULL,
  kontak     TEXT,
  alamat     TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==================== [2] CUSTOMERS ====================
CREATE TABLE IF NOT EXISTS customers (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nama       TEXT NOT NULL,
  kontak     TEXT,
  tipe       TEXT DEFAULT 'retail', -- 'retail' | 'grosir'
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==================== [3] SALES (HEADER) ====================
CREATE TABLE IF NOT EXISTS sales (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nomor_struk   TEXT UNIQUE,
  customer_id   UUID REFERENCES customers(id) ON DELETE SET NULL,
  customer_name TEXT,
  user_id       UUID NOT NULL,
  user_name     TEXT NOT NULL,
  subtotal      INTEGER NOT NULL,
  diskon        INTEGER DEFAULT 0,
  total         INTEGER NOT NULL,
  bayar         INTEGER NOT NULL,
  kembalian     INTEGER NOT NULL,
  metode_bayar  TEXT DEFAULT 'tunai', -- 'tunai' | 'transfer' | 'qris'
  catatan       TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ==================== [4] SALES ITEMS (DETAIL) ====================
CREATE TABLE IF NOT EXISTS sales_items (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sale_id     UUID NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
  product_id  UUID REFERENCES products(id) ON DELETE SET NULL,
  nama_produk TEXT NOT NULL,
  harga_jual  INTEGER NOT NULL,
  harga_beli  INTEGER NOT NULL,
  jumlah      INTEGER NOT NULL,
  subtotal    INTEGER NOT NULL,
  satuan      TEXT DEFAULT 'pcs'
);

-- ==================== [5] ENABLE RLS ====================
ALTER TABLE suppliers   ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers   ENABLE ROW LEVEL SECURITY;
ALTER TABLE sales       ENABLE ROW LEVEL SECURITY;
ALTER TABLE sales_items ENABLE ROW LEVEL SECURITY;

-- ==================== [6] SECURITY POLICIES ====================
CREATE POLICY "Allow authenticated" ON suppliers
  FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated" ON customers
  FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated" ON sales
  FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated" ON sales_items
  FOR ALL USING (auth.role() = 'authenticated');

-- ==================== [7] RPC: CHECKOUT TRANSACTION ====================
-- Transaksi atomic: simpan struk + detail item + potong stok sekaligus
CREATE OR REPLACE FUNCTION checkout_transaction(
  p_nomor_struk TEXT,
  p_customer_id UUID,
  p_customer_name TEXT,
  p_user_id UUID,
  p_user_name TEXT,
  p_subtotal INTEGER,
  p_diskon INTEGER,
  p_total INTEGER,
  p_bayar INTEGER,
  p_kembalian INTEGER,
  p_metode_bayar TEXT,
  p_catatan TEXT,
  p_items JSONB
) RETURNS VOID AS $$
DECLARE
  v_sale_id UUID;
  v_item RECORD;
BEGIN
  INSERT INTO sales (...) VALUES (...) RETURNING id INTO v_sale_id;
  FOR v_item IN SELECT * FROM jsonb_to_recordset(p_items) AS x(...) LOOP
    INSERT INTO sales_items (...) VALUES (...);
    UPDATE products SET stok = stok - v_item.jumlah WHERE id = v_item.product_id;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

> 📄 Lihat file [`supabase_setup.sql`](../supabase_setup.sql) untuk SQL lengkap yang siap dijalankan.

</details>

### 4. Konfigurasi Supabase di Aplikasi

Edit file `lib/main.dart` dan ganti URL & Anon Key dengan milik Anda:

```dart
await Supabase.initialize(
  url: 'https://YOUR_PROJECT_ID.supabase.co',   // ← Ganti ini
  anonKey: 'YOUR_SUPABASE_ANON_KEY',            // ← Ganti ini
);
```

> ⚠️ **Penting**: Jangan commit API key ke repository publik. Gunakan environment variables untuk produksi.

### 5. Jalankan Aplikasi

```bash
flutter run
```

Untuk build release APK:

```bash
flutter build apk --release
```

---

## 📱 Platform yang Didukung

| Platform | Status |
|----------|--------|
| Android | ✅ Supported |
| iOS | ✅ Supported |
| Web | 🚧 Partial |
| Windows | 🚧 Partial |
| Linux | 🚧 Partial |
| macOS | 🚧 Partial |

---

## 🎨 Tema & Desain

Aplikasi menggunakan **Material Design 3** dengan dukungan **dark mode** penuh:

- **Typography**: Google Fonts — `Inter`
- **Color System**: Curated palette dengan semantic colors (primary, secondary, error, success, warning)
- **Theme Toggle**: Bisa diubah langsung dari halaman Profil
- **Adaptive Colors**: Semua komponen menggunakan `context.color.*` untuk adaptive theming

---

## 🔒 Role & Akses

| Fitur | Admin | Kasir |
|-------|-------|-------|
| Dashboard | ✅ | ✅ |
| Kasir / POS | ✅ | ✅ |
| Manajemen Produk | ✅ | ❌ |
| Laporan | ✅ | ✅ |
| Buku Kas | ✅ | ❌ |
| Biaya Operasional | ✅ | ❌ |
| Data Supplier & Customer | ✅ | ✅ |
| Manajemen Pengguna | ✅ | ❌ |

---

## 🤝 Kontribusi

Kontribusi sangat diterima! Ikuti langkah berikut:

1. **Fork** repository ini
2. Buat branch baru: `git checkout -b feature/nama-fitur`
3. Commit perubahan: `git commit -m 'feat: tambah fitur X'`
4. Push ke branch: `git push origin feature/nama-fitur`
5. Buat **Pull Request**

### Konvensi Commit

Gunakan format [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: tambah fitur baru
fix: perbaikan bug
docs: update dokumentasi
style: perubahan tampilan
refactor: refactor kode
```

---

## 📝 Lisensi

Proyek ini dilisensikan di bawah [MIT License](LICENSE).

---

## 📞 Kontak

Dibuat dengan ❤️ menggunakan Flutter & Supabase.

Jika ada pertanyaan atau bug, silakan buka [Issues](../../issues) di repository ini.

---

<p align="center">
  <strong>Smart Retail Inventory</strong> — Solusi manajemen toko yang cerdas dan efisien
</p>
