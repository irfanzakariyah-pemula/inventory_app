# WMS Inventory App — Walkthrough

## Ringkasan
Sistem Warehouse Management System (WMS) lengkap berhasil dibangun dari nol di project Flutter `inventory_app`. Semua fitur yang diminta sudah terimplementasi.

## Struktur Final

```
lib/
├── main.dart                           ← Entry point + MultiProvider + Tema
├── models/
│   ├── user_model.dart                 ← UserModel + UserRole enum + dummy users
│   └── product_model.dart              ← Product + TransactionLog models
├── providers/
│   ├── auth_provider.dart              ← Login/logout + role checking
│   ├── product_provider.dart           ← CRUD + stok + search + auto-logging
│   └── transaction_provider.dart       ← Log transaksi + filter
├── screens/
│   ├── login_screen.dart               ← Form login + gradient Navy Blue
│   ├── home_screen.dart                ← Shell + BottomNavBar (role-based)
│   ├── dashboard_screen.dart           ← Summary cards + stok kritis list
│   ├── product_list_screen.dart        ← Daftar barang + search + delete
│   ├── product_form_screen.dart        ← Tambah/edit + validasi lengkap
│   ├── stock_update_screen.dart        ← Stok masuk/keluar + auto-log
│   ├── transaction_log_screen.dart     ← Riwayat semua transaksi
│   └── profile_screen.dart             ← Info user + placeholder + logout
└── widgets/
    ├── critical_stock_card.dart         ← Card peringatan stok rendah
    └── product_card.dart               ← Card produk reusable
```

## Fitur yang Diimplementasi

### 1. Autentikasi & Role
| Akun | Email | Password | Role |
|------|-------|----------|------|
| Admin | `admin@wms.com` | `admin123` | Administrator (akses penuh) |
| Petugas | `petugas@wms.com` | `petugas123` | Petugas Gudang (stok only) |

### 2. Navigasi Role-Based
- **Admin**: Dashboard → Barang → Log Transaksi → Profil (4 tab)
- **Petugas**: Dashboard → Update Stok → Profil (3 tab)

### 3. Dashboard
- 3 kartu ringkasan: Total Barang, Stok Kritis, Transaksi Hari Ini
- Daftar barang dengan stok kritis (progress bar visual)

### 4. CRUD Barang (Admin only)
- Tambah barang baru dengan form lengkap
- Edit barang existing
- Hapus barang dengan konfirmasi dialog
- Search berdasarkan nama, SKU, atau kategori
- Validasi: field wajib, stok ≥ 0

### 5. Update Stok (Admin & Petugas)
- Toggle Stok Masuk / Stok Keluar
- Dropdown pilih barang (menampilkan stok saat ini)
- Validasi: stok tidak boleh negatif setelah pengurangan
- Otomatis mencatat log transaksi

### 6. Log Transaksi (Admin only)
- Riwayat lengkap semua perubahan stok
- Badge warna: hijau (masuk), merah (keluar)
- Info: siapa, kapan, berapa, stok sebelum → sesudah

### 7. Profil
- Avatar inisial nama
- Info akun lengkap (ID, nama, email, role)
- Placeholder `TODO` untuk kode profil kustom
- Tombol logout dengan konfirmasi

### 8. Desain & Tema
- Material 3 dengan Navy Blue (#1B2A4A) & Grey palette
- Google Fonts Inter
- Gradient, shadow, rounded corners
- Animasi fade-in di login

## Dependencies Ditambahkan
- `provider: ^6.1.2` — State management
- `intl: ^0.20.2` — Format tanggal
- `google_fonts: ^6.2.1` — Tipografi premium

## Verifikasi
- ✅ `flutter pub get` — 33 dependencies berhasil diinstal
- ✅ `flutter analyze` — **No issues found!** (0 error, 0 warning)

## Cara Menjalankan
```bash
cd "d:\project inventory flutter\inventory_app"
flutter run -d windows
```

## Catatan untuk Halaman Profil
Di file `profile_screen.dart`, cari bagian komentar:
```dart
// TODO: TEMPEL KODE PROFIL KUSTOM ANDA DI SINI
```
Anda bisa menambahkan widget kustom di bawah komentar tersebut. Data user tersedia melalui variabel `user` (dari `AuthProvider`).
