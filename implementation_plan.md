# Warehouse Management System (WMS) - Flutter Implementation Plan

Membangun sistem WMS lengkap dari nol di dalam project `inventory_app` yang sudah ada. Project saat ini masih berupa template counter default Flutter.

## Proposed Changes

### Struktur Folder Final

```
lib/
├── main.dart                          [MODIFY]
├── models/
│   ├── user_model.dart                [NEW]
│   └── product_model.dart             [NEW]
├── providers/
│   ├── auth_provider.dart             [NEW]
│   ├── product_provider.dart          [NEW]
│   └── transaction_provider.dart      [NEW]
├── screens/
│   ├── login_screen.dart              [NEW]
│   ├── home_screen.dart               [NEW] (shell dengan BottomNavigationBar)
│   ├── dashboard_screen.dart          [NEW]
│   ├── product_list_screen.dart       [NEW]
│   ├── product_form_screen.dart       [NEW] (Tambah & Edit)
│   ├── stock_update_screen.dart       [NEW] (Stok Masuk/Keluar)
│   ├── transaction_log_screen.dart    [NEW]
│   └── profile_screen.dart            [NEW] (placeholder untuk kode user)
└── widgets/
    ├── critical_stock_card.dart        [NEW]
    └── product_card.dart              [NEW]
```

---

### 1. Dependency — `pubspec.yaml`

#### [MODIFY] [pubspec.yaml](file:///d:/project%20inventory%20flutter/inventory_app/pubspec.yaml)

Menambahkan dependency `provider` dan `intl` (format tanggal Indonesia), serta `google_fonts` untuk tipografi profesional.

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  provider: ^6.1.2
  intl: ^0.20.2
  google_fonts: ^6.2.1
```

---

### 2. Models — `lib/models/`

#### [NEW] user_model.dart

- Enum `UserRole { admin, petugas }`
- Class `UserModel`: `id`, `nama`, `email`, `role`, `avatarUrl`
- Dummy data: 2 user (1 admin, 1 petugas)

#### [NEW] product_model.dart

- Class `Product`: `id`, `nama`, `sku`, `kategori`, `stok`, `stokMinimum`, `rakLokasi`
- Method `isStokKritis` → `stok < stokMinimum`
- Class `TransactionLog`: `id`, `productId`, `productName`, `userId`, `userName`, `type` (masuk/keluar), `jumlah`, `stokSebelum`, `stokSesudah`, `waktu`

---

### 3. Providers — `lib/providers/`

#### [NEW] auth_provider.dart

- `currentUser`, `isLoggedIn`, `isAdmin`
- `login(email, password)` — validasi dummy
- `logout()`

#### [NEW] product_provider.dart

- `List<Product> _products` dengan data dummy awal (5-7 barang)
- `addProduct()`, `updateProduct()`, `deleteProduct()`
- `updateStock(productId, jumlah, tipe, userId)` — otomatis membuat log transaksi
- Getter: `totalBarang`, `stokKritis`, `allProducts`

#### [NEW] transaction_provider.dart

- `List<TransactionLog> _logs`
- `addLog()`, getter `allLogs`, filter by product/user

---

### 4. Screens — `lib/screens/`

#### [NEW] login_screen.dart

- Form login dengan email & password
- Validasi input tidak kosong
- Dummy credentials:
  - Admin: `admin@wms.com` / `admin123`
  - Petugas: `petugas@wms.com` / `petugas123`
- Desain premium dengan gradient Navy Blue

#### [NEW] home_screen.dart

- Shell utama dengan `BottomNavigationBar`
- Tab berdasarkan role:
  - **Admin**: Dashboard, Barang, Log Transaksi, Profil
  - **Petugas**: Dashboard, Update Stok, Profil

#### [NEW] dashboard_screen.dart

- Card ringkasan: Total Barang, Stok Kritis, Total Transaksi Hari Ini
- ListView daftar stok kritis dengan `CriticalStockCard`

#### [NEW] product_list_screen.dart (Admin only)

- ListView semua produk dengan search bar
- FAB untuk tambah barang
- Swipe/button untuk edit & hapus
- Dialog konfirmasi hapus

#### [NEW] product_form_screen.dart (Admin only)

- Form input: nama, SKU, kategori, stok, stok minimum, rak lokasi
- Validasi: semua field wajib, stok & stok minimum ≥ 0
- Mode: Tambah baru / Edit existing

#### [NEW] stock_update_screen.dart (Admin & Petugas)

- Pilih produk dari dropdown
- Input jumlah stok (masuk/keluar)
- Validasi: stok tidak boleh negatif setelah pengurangan
- Otomatis buat log transaksi

#### [NEW] transaction_log_screen.dart (Admin only)

- ListView semua log transaksi
- Info: nama barang, tipe (masuk/keluar), jumlah, siapa, kapan
- Warna badge hijau (masuk) / merah (keluar)

#### [NEW] profile_screen.dart

- Placeholder siap tempel kode user
- Menampilkan info user yang login: nama, email, role
- Tombol logout

---

### 5. Widgets — `lib/widgets/`

#### [NEW] critical_stock_card.dart

- Card untuk item stok kritis di dashboard
- Tampilkan nama, stok saat ini, stok minimum, lokasi rak
- Warna merah/oranye untuk warning

#### [NEW] product_card.dart

- Card reusable untuk daftar produk
- Tampilkan nama, SKU, kategori, stok, lokasi
- Indikator warna stok (merah jika kritis)

---

### 6. Main Entry — `lib/main.dart`

#### [MODIFY] [main.dart](file:///d:/project%20inventory%20flutter/inventory_app/lib/main.dart)

- Setup `MultiProvider` dengan 3 provider
- Material 3 theme dengan `ColorScheme` Navy Blue & Grey
- Google Fonts (Inter)
- Route: Login → Home

---

## Desain & Tema

| Elemen | Warna |
|--------|-------|
| Primary | Navy Blue `#1B2A4A` |
| Secondary | Steel Blue `#4A6FA5` |
| Surface | Light Grey `#F5F6FA` |
| Error/Kritis | Coral Red `#E74C3C` |
| Success/Masuk | Emerald Green `#27AE60` |
| Text Primary | Dark `#1A1A2E` |

Material 3 `useMaterial3: true` dengan `ColorScheme.fromSeed` + override manual.

---

## Role-Based Access Summary

| Fitur | Admin | Petugas |
|-------|-------|---------|
| Dashboard | ✅ | ✅ |
| Lihat Daftar Barang | ✅ | ❌ |
| Tambah/Edit/Hapus Barang | ✅ | ❌ |
| Update Stok (Masuk/Keluar) | ✅ | ✅ |
| Lihat Log Transaksi | ✅ | ❌ |
| Profil | ✅ | ✅ |

---

## Open Questions

> [!IMPORTANT]
> **Halaman Profil**: Anda menyebutkan ingin menempelkan kode profil yang sudah dibuat sebelumnya. Saya akan membuat `profile_screen.dart` dengan placeholder yang jelas (`// TODO: TEMPEL KODE PROFIL ANDA DI SINI`) beserta data user yang sudah terkoneksi. Apakah pendekatan ini sesuai?

> [!NOTE]
> **Data Dummy**: Semua data menggunakan dummy (in-memory). Tidak ada database/backend. Data akan hilang saat aplikasi di-restart. Apakah ini sudah sesuai ekspektasi?

---

## Verification Plan

### Automated Tests
```bash
cd d:\project inventory flutter\inventory_app
flutter pub get
flutter analyze
flutter run -d windows
```

### Manual Verification (via Browser/Emulator)
- Login sebagai Admin → pastikan semua 4 tab muncul
- Login sebagai Petugas → pastikan hanya 3 tab muncul
- Tambah barang → pastikan muncul di daftar
- Update stok → pastikan log otomatis tercatat
- Cek dashboard → pastikan stok kritis tampil
- Logout → pastikan kembali ke login
