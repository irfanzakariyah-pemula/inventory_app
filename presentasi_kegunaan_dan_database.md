# 📦 Presentasi Project: Aplikasi "Stok and Inventory"

---

## 🎯 1. Kegunaan dan Tujuan Aplikasi

**Aplikasi "Stok and Inventory"** adalah solusi digital untuk mempermudah dan mengotomatisasi pengelolaan barang di gudang. Aplikasi ini dirancang untuk mengatasi masalah pencatatan manual yang lambat, rentan kesalahan, dan sulit dilacak.

### Manfaat Utama:
*   **Pencatatan Akurat & Real-time:** Setiap perubahan stok (barang masuk/keluar) langsung tersimpan di *cloud* dan seketika itu juga terupdate di semua perangkat tanpa perlu *refresh*.
*   **Kontrol Keamanan (Role-Based Access):** 
    *   **Admin:** Punya akses penuh untuk menambah, mengedit, menghapus barang, dan melihat *semua* riwayat transaksi.
    *   **Petugas:** Hanya bisa melakukan *update* stok (masuk/keluar) dan hanya bisa melihat riwayat transaksi yang dilakukannya sendiri.
*   **Peringatan Dini:** Sistem otomatis mendeteksi dan memberi tahu jika ada barang yang jumlah stoknya sudah menipis (di bawah batas minimum yang ditentukan), sehingga mencegah kehabisan barang.
*   **Audit Trail (Riwayat Terlacak):** Setiap kali ada stok yang berubah, aplikasi otomatis mencatat **siapa** yang mengubah, **apa** barangnya, **kapan** waktunya, dan **berapa** jumlahnya. Tidak ada perubahan yang luput dari pantauan.

---

## 📱 2. Penjelasan Setiap Halaman (Fitur UI)

Aplikasi ini memiliki antarmuka yang bersih dan mudah digunakan. Berikut adalah fungsi dari masing-masing halaman:

### 1. Halaman Login (`login_screen.dart`)
*   **Fungsi:** Pintu masuk utama aplikasi. Pengguna harus memasukkan email dan password yang terdaftar untuk bisa masuk.
*   **Keunggulan:** Terhubung langsung ke keamanan Firebase. Jika password salah, email tidak terdaftar, atau akun diblokir, sistem akan memberikan pesan *error* yang jelas. Tidak ada opsi "Lupa Password" atau "Daftar Akun" di sini untuk menjaga keamanan (pembuatan akun dikelola oleh Admin).

### 2. Halaman Dashboard (`dashboard_screen.dart`)
*   **Fungsi:** Pusat informasi ringkas kondisi gudang saat ini.
*   **Fitur:**
    *   Sapaan nama pengguna yang sedang *login* beserta perannya (Admin/Petugas).
    *   **3 Kartu Informasi Utama:**
        *   **Total Barang:** Menampilkan berapa banyak jenis barang yang ada di gudang.
        *   **Stok Kritis:** Menampilkan jumlah barang yang stoknya sudah hampir habis.
        *   **Transaksi Hari Ini:** Menampilkan jumlah aktivitas (barang masuk/keluar) yang terjadi hari ini.
    *   **Daftar Peringatan:** Menampilkan daftar spesifik barang-barang yang masuk dalam kategori "Stok Kritis" (ditandai dengan warna merah).

### 3. Halaman Daftar Produk (`product_list_screen.dart`)
*   **Fungsi:** Menampilkan katalog lengkap semua barang yang ada di dalam database.
*   **Fitur:**
    *   **Daftar Real-time:** Jika ada barang baru ditambahkan atau stok berubah di perangkat lain, daftar ini langsung menyesuaikan.
    *   **Pencarian Cepat:** Admin/Petugas bisa mencari barang berdasarkan Nama, SKU (Kode Barang), atau Kategori.
    *   **Indikator Visual:** Barang dengan stok kritis diberi tanda peringatan berwarna merah agar mudah terlihat.
    *   **Hanya untuk Admin:** Terdapat tombol khusus (+) untuk menambah barang baru ke dalam sistem.

### 4. Halaman Form Produk (`product_form_screen.dart`) - *Khusus Admin*
*   **Fungsi:** Formulir untuk mendaftarkan barang baru atau mengedit detail barang yang sudah ada.
*   **Data yang diinput:** Nama Barang, SKU, Kategori, Jumlah Stok Awal, Batas Stok Minimum (untuk alarm stok kritis), dan Lokasi Rak.
*   **Otomatisasi:** Jika Admin menyimpan barang baru dengan stok awal lebih dari 0, sistem *otomatis* membuat catatan "Transaksi Masuk" tanpa perlu diinput manual lagi.

### 5. Halaman Update Stok (`stock_update_screen.dart`)
*   **Fungsi:** Halaman paling krusial untuk kegiatan operasional harian. Digunakan saat ada barang fisik yang masuk ke gudang atau keluar dari gudang.
*   **Fitur:**
    *   Pilih jenis transaksi: **Stok Masuk** (Tambah) atau **Stok Keluar** (Kurangi).
    *   Masukkan jumlah barang.
    *   **Validasi Keamanan:** Jika Petugas mencoba mengeluarkan barang melebihi stok yang ada, sistem akan memblokir dan memberikan pesan *error*.

### 6. Halaman Riwayat Transaksi (`transaction_log_screen.dart`)
*   **Fungsi:** Buku besar (buku log) yang mencatat seluruh riwayat pergerakan stok.
*   **Aturan Akses:**
    *   **Admin:** Dapat melihat riwayat pergerakan stok yang dilakukan oleh *semua* pengguna.
    *   **Petugas:** Hanya dapat melihat daftar riwayat pergerakan stok yang dilakukannya sendiri.
*   **Detail yang dicatat:** Jenis transaksi (Masuk/Keluar), nama barang, jumlah perubahan, nama petugas, dan waktu pastinya (jam & tanggal).

### 7. Halaman Profil (`profile_screen.dart`)
*   **Fungsi:** Menampilkan informasi akun yang sedang *login* (Nama, Email, dan Peran). Di sinilah terdapat tombol untuk keluar (Logout) dari aplikasi.

---

## 🔗 3. Hubungan Aplikasi dengan Database (Firebase)

Aplikasi ini tidak menyimpan data di *handphone* atau *laptop*, melainkan di *cloud server* milik Google, yaitu **Firebase**. Hubungannya dibagi menjadi tiga layanan utama:

### A. Firebase Authentication (Keamanan Login)
*   **Tugas:** Menjaga pintu masuk. Firebase Auth menangani verifikasi email dan password. 
*   **Hubungan:** Saat pengguna menekan tombol "Login", aplikasi mengirim data tersebut ke Firebase Auth. Jika benar, Firebase memberikan semacam "Kunci Digital" (UID) agar aplikasi bisa membuka data di database.

### B. Cloud Firestore (Database Penyimpanan)
Firestore adalah database utamanya. Bentuk penyimpanannya bukan tabel baris/kolom, melainkan "Dokumen" (seperti map folder). Aplikasi ini memiliki 3 Folder (Koleksi) utama di Firestore:

1.  **Koleksi `users` (Data Pengguna):**
    *   Menyimpan profil pengguna (Nama dan Peran). 
    *   *Hubungan:* Setelah *login* berhasil di Firebase Auth, aplikasi akan mencari UID tersebut di koleksi `users` untuk mengetahui apakah dia Admin atau Petugas, sehingga aplikasi bisa menyesuaikan tampilan halamannya.

2.  **Koleksi `products` (Data Barang):**
    *   Menyimpan seluruh data barang (Nama, Stok, SKU, Batas Minimum, dll).
    *   *Hubungan Real-time:* Halaman Daftar Produk terhubung secara "Live Streaming" (Stream) dengan koleksi ini. Artinya, jika koleksi `products` di Firebase berubah, Firebase akan langsung "menelepon" aplikasi untuk merubah tampilannya tanpa perlu *loading*.

3.  **Koleksi `transactions` (Buku Riwayat):**
    *   Menyimpan setiap riwayat pergerakan barang.
    *   *Hubungan Otomatis:* Ketika Admin/Petugas merubah stok di koleksi `products`, aplikasi secara **bersamaan** akan menyisipkan satu catatan baru ke dalam koleksi `transactions`.

### C. Mekanisme Keren: "Atomic Transaction"
Saat melakukan Update Stok, aplikasi menggunakan fitur *Atomic Transaction* dari Firestore.
*   **Contoh Kasus:** Petugas A dan Petugas B mau *Update Stok* barang yang sama (misal sisa 10) di waktu yang sama persis.
*   **Solusi Firebase:** Firebase akan mengunci data tersebut sejenak, memproses Petugas A dulu, baru Petugas B. Sehingga tidak terjadi data yang bertabrakan atau stok minus yang tidak masuk akal. Semua perhitungan stok dijamin akurat 100%.
