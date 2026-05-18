# 📦 Presentasi Project: Stok and Inventory
### Aplikasi Manajemen Stok Gudang Berbasis Flutter & Firebase

---

## 🎯 Slide 1 — Pendahuluan & Latar Belakang

**Nama Aplikasi:** Stok and Inventory  
**Platform:** Flutter (Android, iOS, Web, Windows)  
**Backend:** Firebase (Cloud — tanpa server fisik)

### Masalah yang Diselesaikan
Pengelolaan stok gudang secara manual atau berbasis spreadsheet rentan terhadap:
- Data tidak sinkron antar petugas
- Tidak ada riwayat perubahan stok
- Tidak ada peringatan saat stok menipis
- Tidak ada kontrol akses berdasarkan peran

### Solusi
Aplikasi mobile/desktop yang terhubung ke cloud secara **real-time**, dengan sistem **autentikasi**, **peran user**, dan **pencatatan log otomatis**.

---

## 🏗️ Slide 2 — Arsitektur Sistem

```
┌─────────────────────────────────────────────┐
│               APLIKASI FLUTTER              │
│                                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │  Screen  │  │ Provider │  │  Model   │  │
│  │  (UI)    │◄─│  (State) │◄─│  (Data)  │  │
│  └──────────┘  └────┬─────┘  └──────────┘  │
└───────────────────── │ ──────────────────────┘
                       │ (Firestore SDK)
┌───────────────────── ▼ ──────────────────────┐
│                   FIREBASE                   │
│                                             │
│  ┌─────────────┐  ┌───────────────────────┐ │
│  │ Firebase    │  │    Cloud Firestore     │ │
│  │ Auth        │  │  ┌────────────────┐   │ │
│  │             │  │  │ users          │   │ │
│  │ (Login /    │  │  │ products       │   │ │
│  │  Logout)    │  │  │ transactions   │   │ │
│  └─────────────┘  │  └────────────────┘   │ │
│                   └───────────────────────┘ │
└─────────────────────────────────────────────┘
```

### Pola Arsitektur: **Provider Pattern (MVVM)**
| Lapisan | Komponen | Fungsi |
|---------|----------|--------|
| **View** | `*_screen.dart` | Tampilan UI kepada pengguna |
| **ViewModel** | `*_provider.dart` | Logika bisnis & state management |
| **Model** | `*_model.dart` | Struktur data & serialisasi Firestore |
| **Service** | Firebase SDK | Penyimpanan & autentikasi cloud |

---

## 🔥 Slide 3 — Firebase: Layanan yang Digunakan

### 3 Layanan Firebase Utama

### 1. Firebase Authentication
**File terkait:** `auth_provider.dart`

Digunakan untuk proses **login dan logout** berbasis email & password.

```dart
// Proses login — kirim email & password ke Firebase
final credential = await _auth.signInWithEmailAndPassword(
  email: email.trim(),
  password: password.trim(),
);
```

**Fitur yang dimanfaatkan:**
- Login dengan email & password
- Penanganan error spesifik (email salah, password salah, akun nonaktif, terlalu banyak percobaan)
- Sign out untuk mengakhiri sesi

> **Penting:** Password tidak pernah disimpan di database aplikasi — sepenuhnya dikelola Firebase secara aman.

---

### 2. Cloud Firestore (Database)
**File terkait:** `product_provider.dart`, `transaction_provider.dart`

Database NoSQL berbasis dokumen yang mendukung **sinkronisasi real-time**.

#### Struktur Koleksi Firestore:

```
firestore/
├── users/                    ← Data profil & role pengguna
│   └── {uid}/
│       ├── nama: "Budi Santoso"
│       ├── email: "budi@email.com"
│       └── role: "admin" | "petugas"
│
├── products/                 ← Data barang di gudang
│   └── {productId}/
│       ├── nama: "Laptop ASUS"
│       ├── sku: "ELK-001"
│       ├── kategori: "Elektronik"
│       ├── stok: 15
│       ├── stokMinimum: 5
│       └── rakLokasi: "A-01"
│
└── transactions/             ← Log setiap perubahan stok
    └── {logId}/
        ├── productId: "..."
        ├── productName: "Laptop ASUS"
        ├── userId: "..."
        ├── userName: "Budi Santoso"
        ├── type: "masuk" | "keluar"
        ├── jumlah: 3
        ├── stokSebelum: 12
        ├── stokSesudah: 15
        └── waktu: Timestamp
```

---

### 3. Firebase Options (Konfigurasi Multi-Platform)
**File terkait:** `firebase_options.dart` *(di-generate oleh FlutterFire CLI)*

File ini berisi konfigurasi koneksi untuk **setiap platform** (Android, iOS, Web, Windows) menggunakan Project ID yang sama: **`stok-inventory-ce1bd`**

```dart
// Inisialisasi Firebase di main.dart — wajib dipanggil sebelum runApp()
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform, // otomatis pilih platform
);
```

---

## 👤 Slide 4 — Sistem Autentikasi & Hak Akses (Role-Based)

### Alur Login

```
User input Email & Password
         │
         ▼
  Firebase Authentication
  (verifikasi kredensial)
         │
    ✅ Sukses
         │
         ▼
  Ambil data user dari Firestore
  koleksi 'users' → doc(uid)
         │
         ▼
  Baca field 'role'
    ┌────┴────┐
 "admin"   "petugas"
    │           │
    ▼           ▼
 Dashboard   Dashboard
 (akses      (akses
  penuh)      terbatas)
```

### Perbedaan Hak Akses

| Fitur | Admin | Petugas |
|-------|-------|---------|
| Lihat daftar barang | ✅ | ✅ |
| Tambah barang baru | ✅ | ❌ |
| Edit data barang | ✅ | ❌ |
| Hapus barang | ✅ | ❌ |
| Update stok (masuk/keluar) | ✅ | ✅ |
| Lihat log transaksi | ✅ (semua) | ✅ (miliknya saja) |
| Dashboard ringkasan | ✅ | ✅ |

```dart
// Contoh penerapan di kode — hak akses berdasarkan role
bool get isAdmin => _currentUser?.isAdmin ?? false;

// Di UI: tombol tambah hanya muncul untuk admin
if (auth.isAdmin)
  FloatingActionButton(onPressed: () => /* navigasi ke form tambah barang */)
```

---

## 📊 Slide 5 — Fitur Utama Aplikasi (Per Halaman)

### 1. Login Screen (`login_screen.dart`)
- Form email & password
- Validasi format input sebelum dikirim ke Firebase
- Tampilkan pesan error yang ramah pengguna

### 2. Dashboard Screen (`dashboard_screen.dart`)
- **Salam pembuka** dengan nama user yang sedang login + badge role
- **3 kartu ringkasan:**
  - 📦 Total Barang
  - ⚠️ Jumlah Stok Kritis (di bawah minimum)
  - 🔄 Transaksi Hari Ini
- **Daftar barang kritis** — otomatis diperbarui saat data Firestore berubah

### 3. Product List Screen (`product_list_screen.dart`)
- Daftar semua produk dari Firestore (real-time)
- Fitur pencarian berdasarkan nama, SKU, atau kategori
- Indikator visual merah untuk stok kritis
- Tombol tambah barang (khusus Admin)

### 4. Product Form Screen (`product_form_screen.dart`)
- Formulir tambah / edit barang (Admin only)
- Field: Nama, SKU, Kategori, Stok Awal, Stok Minimum, Lokasi Rak
- Saat menyimpan barang baru dengan stok > 0, otomatis mencatat **log transaksi masuk pertama**

### 5. Stock Update Screen (`stock_update_screen.dart`)
- Update stok barang (masuk / keluar) — bisa dilakukan Admin & Petugas
- Menggunakan **Atomic Transaction Firestore** untuk mencegah konflik data
- Otomatis menolak jika stok keluar melebihi stok tersedia

### 6. Transaction Log Screen (`transaction_log_screen.dart`)
- Riwayat seluruh perubahan stok dengan timestamp
- Admin: melihat log semua pengguna
- Petugas: hanya melihat log dari transaksinya sendiri
- Filter otomatis berdasarkan `userId` di query Firestore

### 7. Profile Screen (`profile_screen.dart`)
- Informasi user yang sedang login (nama, email, role)
- Tombol logout

---

## ⚡ Slide 6 — Fitur Teknis Unggulan

### 1. Real-Time Stream (Sinkronisasi Langsung)
Data produk dan log transaksi **tidak perlu di-refresh manual**. Begitu ada perubahan di Firestore (dari device manapun), UI langsung terupdate.

```dart
// product_provider.dart — mendengarkan perubahan secara real-time
_db
  .collection('products')
  .orderBy('nama')
  .snapshots()          // ← stream, bukan sekali baca
  .listen((snapshot) {
    _products = snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
    notifyListeners();   // ← beritahu UI untuk rebuild
  });
```

### 2. Atomic Transaction (Keamanan Data)
Saat update stok, digunakan **Firestore transaction** untuk memastikan tidak terjadi **race condition** (misalnya dua petugas update stok bersamaan).

```dart
// product_provider.dart — atomic transaction
await _db.runTransaction((transaction) async {
  final snapshot = await transaction.get(productRef);
  final stokSekarang = snapshot['stok'];
  
  // Cek stok cukup (untuk transaksi keluar)
  if (type == TransactionType.keluar && stokSekarang - jumlah < 0) {
    success = false; return; // ← gagal dengan aman
  }
  
  transaction.update(productRef, {'stok': stokBaru}); // ← atomik
});
```

### 3. Log Otomatis
Setiap perubahan stok **otomatis tercatat** ke koleksi `transactions` di Firestore — tidak perlu input manual dari user.

```dart
// Dipanggil otomatis setelah update stok berhasil
await _transactionProvider?.addLog(
  productId: productId,
  productName: currentProduct.nama,
  userId: userId,
  userName: userName,
  type: type,
  jumlah: jumlah,
  stokSebelum: stokSebelum,
  stokSesudah: stokBaru,
);
```

### 4. Deteksi Stok Kritis Otomatis
Setiap produk punya field `stokMinimum`. Sistem otomatis menandai stok kritis tanpa query tambahan ke Firestore.

```dart
// product_model.dart
bool get isStokKritis => stok < stokMinimum;
```

---

## 📦 Slide 7 — Teknologi & Dependensi

| Package | Versi | Kegunaan |
|---------|-------|----------|
| `flutter` | SDK | Framework UI utama |
| `firebase_core` | ^3.8.0 | Inisialisasi Firebase |
| `firebase_auth` | ^5.3.4 | Autentikasi pengguna |
| `cloud_firestore` | ^5.5.0 | Database cloud real-time |
| `provider` | ^6.1.2 | State management (MVVM) |
| `google_fonts` | ^6.2.1 | Tipografi (font Inter) |
| `intl` | ^0.20.2 | Format tanggal bahasa Indonesia |

**Firebase Project ID:** `stok-inventory-ce1bd`  
**Platform yang didukung:** Android, iOS, Web, Windows

---

## 🔄 Slide 8 — Alur Data Lengkap (End-to-End)

```
[Pengguna]
    │
    │  Input email & password
    ▼
[Firebase Auth] ── verifikasi ──► [Firestore: users/{uid}]
    │                                      │
    │                              baca nama & role
    │                                      │
    ▼                                      ▼
[HomeScreen] ◄── notifyListeners() ── [AuthProvider]
    │
    │  startListening()
    ▼
[Firestore: products] ──stream──► [ProductProvider]
[Firestore: transactions] ─stream─► [TransactionProvider]
    │
    ▼
[DashboardScreen / ProductListScreen / TransactionLogScreen]
(UI otomatis update saat data berubah)
    │
    │  User klik "Update Stok"
    ▼
[StockUpdateScreen]
    │
    │  runTransaction()
    ▼
[Firestore: products/{id}] ← update atomik
    │
    │  addLog()
    ▼
[Firestore: transactions] ← catat riwayat otomatis
    │
    ▼
[UI semua screen terupdate secara real-time]
```

---

## ✅ Slide 9 — Keunggulan Sistem

| Aspek | Penjelasan |
|-------|-----------|
| **Real-time** | Data sinkron otomatis tanpa refresh manual |
| **Aman** | Password dikelola Firebase, role-based access control |
| **Skalabel** | Firebase cloud — tidak perlu kelola server |
| **Audit Trail** | Setiap perubahan stok tercatat otomatis dengan waktu & pelaku |
| **Multi-platform** | 1 codebase berjalan di Android, iOS, Web, Windows |
| **Offline Ready** | Firestore mendukung cache lokal saat koneksi putus |

---

## 🎤 Slide 10 — Penutup & Demo

### Yang Akan Didemonstrasikan:
1. Login sebagai **Admin** → akses penuh
2. Login sebagai **Petugas** → akses terbatas
3. Tambah barang baru → log otomatis tercatat
4. Update stok (masuk / keluar) → UI real-time terupdate
5. Lihat log transaksi → filter per user
6. Dashboard → kartu stok kritis otomatis muncul

### Firebase Console (untuk ditunjukkan):
- **Authentication** tab → daftar user terdaftar
- **Firestore Database** → koleksi `users`, `products`, `transactions`
- Data berubah **live** saat demo berjalan

---

> 📌 **Project:** `stok-inventory-ce1bd` (Firebase)  
> 📱 **Teknologi:** Flutter + Firebase Auth + Cloud Firestore  
> 🏛️ **Arsitektur:** MVVM dengan Provider Pattern
