# Penjelasan Fitur Aplikasi Smart Retail Inventory

Dokumen ini adalah panduan lengkap mengenai fitur-fitur yang ada di dalam aplikasi Smart Retail Inventory. Anda dapat menggunakan panduan ini untuk menjelaskan cara kerja aplikasi serta letak kodenya (script) kepada dosen penguji.

Secara garis besar, aplikasi ini dibangun menggunakan **Flutter** untuk antarmuka (UI) dan **Supabase** (PostgreSQL) sebagai database backend. Arsitektur state management yang digunakan adalah **Provider**.

---

## 1. Fitur Autentikasi & Hak Akses (Role-Based Access)
**Penjelasan:**
Fitur ini mengatur proses login pengguna. Terdapat dua jenis hak akses (role):
*   **Admin:** Memiliki akses ke seluruh menu (Dashboard, Kasir, Manajemen Barang, Laporan, dan Profil).
*   **Petugas:** Memiliki akses terbatas (Dashboard, Kasir, Log Transaksi, dan Profil), dan tidak bisa mengubah daftar master barang.

**Lokasi File Script:**
*   **Tampilan (UI) Login:** `lib/screens/login_screen.dart`
*   **Logika Autentikasi:** `lib/providers/auth_provider.dart`
*   **Struktur Data User:** `lib/models/user_model.dart`

---

## 2. Fitur Dashboard Terpusat
**Penjelasan:**
Halaman pertama setelah login yang merangkum kondisi toko. Di sini pengguna bisa melihat:
*   Total barang yang ada di gudang.
*   **Peringatan Stok Kritis:** Menampilkan barang yang stoknya sudah di bawah batas minimum (Stok Menipis).
*   **Peringatan Kedaluwarsa (Expired):** Menampilkan barang yang akan atau sudah kedaluwarsa.

**Lokasi File Script:**
*   **Tampilan Utama Dashboard:** `lib/screens/dashboard_screen.dart`
*   **Tampilan Detail Daftar Barang Expired:** `lib/screens/expired_list_screen.dart`

---

## 3. Fitur Manajemen Data Barang (Inventory / Master Data)
**Penjelasan:**
Fitur inti untuk mengelola (CRUD: Create, Read, Update, Delete) data barang di dalam toko. Admin bisa mendaftarkan produk baru lengkap dengan detail seperti:
*   Nama Barang, SKU (Kode Internal), Barcode.
*   Harga Beli (Modal) dan Harga Jual.
*   Stok awal, Batas Minimum Stok, dan Tanggal Kedaluwarsa.

**Lokasi File Script:**
*   **Tampilan Daftar Barang:** `lib/screens/product_list_screen.dart`
*   **Tampilan Form Tambah/Edit Barang:** `lib/screens/product_form_screen.dart`
*   **Logika Mengelola Data Barang:** `lib/providers/product_provider.dart`
*   **Struktur Data Produk:** `lib/models/product_model.dart`

---

## 4. Fitur Kasir (Point of Sales / POS)
**Penjelasan:**
Halaman kasir untuk melayani pembeli. Kasir dapat mencari produk, menyesuaikan jumlah pesanan, dan memproses pembayaran (menghitung total harga dan kembalian). Setelah transaksi berhasil, fitur ini akan **otomatis memotong stok barang** di database.

**Lokasi File Script:**
*   **Tampilan Kasir:** `lib/screens/pos_screen.dart`
*   **Logika Transaksi Penjualan:** `lib/providers/sales_provider.dart`
*   **Struktur Data Struk / Penjualan:** `lib/models/sales_model.dart`

---

## 5. Fitur Penyesuaian Stok Manual (Update Stok)
**Penjelasan:**
Fitur ini digunakan oleh Admin maupun Petugas Gudang untuk menambah atau mengurangi stok barang yang sudah ada di sistem tanpa melalui proses kasir. Biasanya digunakan untuk:
*   Mencatat kedatangan barang (Stok Masuk / Restock).
*   Mencatat barang rusak atau hilang (Stok Keluar).
*   Melakukan penyesuaian jumlah (Stock Opname).

**Lokasi File Script:**
*   **Tampilan Update Stok:** `lib/screens/stock_update_screen.dart`
*   *(Tombol fitur ini dapat diakses melalui halaman Log Transaksi dengan menekan tombol melayang (Floating Action Button) di kanan bawah)*

---

## 6. Fitur Log Transaksi Gudang (Riwayat Stok)
**Penjelasan:**
Fitur ini secara otomatis mencatat segala aktivitas yang mengubah jumlah stok barang. Jika ada barang terjual di kasir, atau jika ada barang masuk (restock), semuanya terekam di riwayat log beserta catatan waktu dan siapa user yang memprosesnya.

**Lokasi File Script:**
*   **Tampilan Riwayat Log:** `lib/screens/transaction_log_screen.dart`
*   **Logika Pencatatan Transaksi:** `lib/providers/transaction_provider.dart`
*   *(Note: Model log transaksi digabungkan di bagian bawah file `lib/models/product_model.dart` pada class `TransactionLog`)*

---

## 7. Fitur Laporan & Analitik Penjualan (Report)
**Penjelasan:**
Hanya dapat diakses oleh Admin. Menampilkan ringkasan pendapatan kotor dan keuntungan bersih (profit) berdasarkan perhitungan (Harga Jual - Harga Beli). Juga dilengkapi grafik sederhana untuk melihat tren harian.

**Lokasi File Script:**
*   **Tampilan Laporan & Grafik:** `lib/screens/report_screen.dart`
*   *(Datanya diambil menggunakan fungsi query yang diurus oleh `sales_provider.dart`)*

---

## 8. Fitur Profil & Pengaturan Tema Terintegrasi
**Penjelasan:**
Halaman profil yang menampilkan informasi akun pengguna yang sedang login. Pada halaman ini terdapat tombol Logout serta tombol saklar (toggle) untuk mengubah tema aplikasi antara **Light Mode** (terang) dan **Dark Mode** (gelap).

**Lokasi File Script:**
*   **Tampilan Profil:** `lib/screens/profile_screen.dart`
*   **Logika Pengaturan Tema & Warna App:** `lib/theme/app_theme.dart`

---

## 9. Navigasi & Entry Point Aplikasi
**Penjelasan:**
Struktur kerangka dasar berjalannya aplikasi. Mulai dari mengkoneksikan aplikasi ke Supabase, me-load seluruh file provider, dan menampilkan Bottom Navigation Bar (menu navigasi bawah) yang menu-menunya menyesuaikan apakah yang login itu Admin atau Petugas.

**Lokasi File Script:**
*   **Entry Point & Inisialisasi Database:** `lib/main.dart`
*   **Kerangka Dasar & Menu Navigasi Bawah:** `lib/screens/home_screen.dart`

---

### Tips Menjawab Saat Presentasi ke Dosen:
1. **Jika dosen bertanya "Bagaimana cara stok bisa berkurang otomatis saat terjadi penjualan?"**
   *Jawaban Anda:* "Prosesnya ada di fitur Kasir (`pos_screen.dart`). Ketika kasir menekan tombol bayar, aplikasi akan memanggil `sales_provider.dart` untuk menyimpan data struk. Provider tersebut kemudian memanggil fungsi update stok di database, dan memicu `transaction_provider.dart` untuk mencatat riwayat log barang keluarnya."
2. **Jika dosen bertanya "Di mana pengaturan koneksi databasenya?"**
   *Jawaban Anda:* "Koneksi ke Supabase PostgreSQL disetel pada awal aplikasi saat pertama kali dijalankan, kodenya berada di dalam file `main.dart`."
3. **Jika dosen bertanya "Mengapa tampilan kasir petugas dan admin berbeda / menunya beda?"**
   *Jawaban Anda:* "Hal tersebut diatur pada file `home_screen.dart` di mana menu navigasi bawah (Bottom Navigation) dirender secara dinamis berdasarkan 'role' akun pengguna yang dicek lewat `auth_provider.dart`."
