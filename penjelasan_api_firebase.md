# 🔌 Penjelasan "API" dalam Project Stok and Inventory

Dalam project ini, konsep "API" (Application Programming Interface) sedikit berbeda dari aplikasi web tradisional (seperti Laravel, Express, atau Spring Boot). 

Aplikasi ini **TIDAK** menggunakan REST API tradisional (seperti `GET /api/products` menggunakan HTTP request), melainkan menggunakan **Firebase SDK (Backend-as-a-Service)**.

Berikut adalah penjelasan bagaimana aplikasi ini berkomunikasi dengan server/database (API Firebase):

---

## 1. Konsep Backend-as-a-Service (BaaS)

Aplikasi ini menggunakan Firebase SDK sebagai jembatan komunikasi (API). Keuntungan menggunakan Firebase SDK dibandingkan REST API biasa adalah:
*   **Koneksi Real-time (WebSockets):** Tidak perlu melakukan *request* berulang kali untuk mengecek data baru. Firebase menggunakan koneksi terbuka, jika ada perubahan di server, server yang akan "mendorong" (push) data baru ke aplikasi.
*   **Offline Support:** Firebase SDK memiliki *cache* internal. Jika tiba-tiba koneksi internet terputus, API tetap bisa membaca/menulis data secara lokal, dan akan otomatis disinkronkan ke server saat internet kembali terhubung.

---

## 2. Letak Panggilan API dalam File Project

Seluruh interaksi API dengan server Firebase dipusatkan di dalam folder `lib/providers/`. File-file di folder ini bertugas sebagai "Service" atau jembatan antara tampilan aplikasi (UI) dengan database di server.

Berikut adalah letak pasti dari setiap pemanggilan API:

### A. API Autentikasi
Terletak di: `lib/providers/auth_provider.dart`
*   **Fungsi `login(email, password)`**: Memanggil API `signInWithEmailAndPassword` dari Firebase Auth.
*   **Fungsi `logout()`**: Memanggil API `signOut` dari Firebase Auth.
*   *Catatan: File ini juga melakukan pemanggilan API ke Firestore (`_db.collection('users').doc(uid).get()`) sesaat setelah login berhasil, gunanya untuk mengambil data profil pengguna (terutama perannya sebagai Admin atau Petugas).*

### B. API Data Barang (Products)
Terletak di: `lib/providers/product_provider.dart`
*   **Fungsi `startListening()`**: Memanggil API Stream `.snapshots().listen()` untuk mengambil seluruh daftar barang secara *real-time*.
*   **Fungsi `addProduct(product)`**: Memanggil API `.add()` untuk menyimpan data barang baru.
*   **Fungsi `updateProduct(product)`**: Memanggil API `.update()` untuk mengubah detail data barang.
*   **Fungsi `deleteProduct(id)`**: Memanggil API `.delete()` untuk menghapus barang.
*   **Fungsi `updateStock(...)`**: Memanggil API khusus `_db.runTransaction(...)` (Atomic Transaction) saat terjadi proses barang masuk atau keluar.

### C. API Log Transaksi
Terletak di: `lib/providers/transaction_provider.dart`
*   **Fungsi `startListening({userId})`**: Memanggil API Stream `.snapshots().listen()` yang dikombinasikan dengan fungsi API pemfilteran (`.where('userId', isEqualTo: userId)`) untuk mengambil riwayat stok secara real-time.
*   **Fungsi `addLog(...)`**: Memanggil API `.add()` ke koleksi `transactions`. *Fungsi ini dipanggil secara otomatis di balik layar, tidak pernah ditekan langsung oleh pengguna.*

---

## 3. Detail Cara Kerja API Autentikasi (Firebase Auth)
Diatur dalam `auth_provider.dart`

Aplikasi memanggil API Firebase Auth untuk memverifikasi identitas pengguna.

*   **Fungsi API:** `signInWithEmailAndPassword(email, password)`
*   **Proses:**
    1. Aplikasi mengirimkan email dan password ke server Firebase Auth.
    2. Jika valid, Firebase mengembalikan objek **UserCredential** yang berisi UID (User ID) dan Token sesi.
    3. Firebase SDK otomatis menyimpan token ini di penyimpanan lokal perangkat, sehingga pengguna tidak perlu login ulang saat aplikasi ditutup dan dibuka kembali.

---

## 3. API Database (Cloud Firestore CRUD)
Diatur dalam `product_provider.dart` dan `transaction_provider.dart`

### A. Read (Membaca Data) - Real-time Stream API
Alih-alih menggunakan metode *Get* sekali jalan, aplikasi menggunakan metode **Stream API** (Snapshot listener).
*   **Fungsi API:** `.collection('products').snapshots().listen(...)`
*   **Cara Kerja:** Membuka saluran komunikasi (stream). Setiap kali ada dokumen di koleksi `products` yang ditambah, diubah, atau dihapus oleh siapapun, API ini akan langsung memicu pembaruan data di dalam aplikasi.

### B. Create (Menambah Data)
*   **Fungsi API:** `.collection('products').add(dataMap)`
*   **Cara Kerja:** Mengirim data Map (JSON) ke koleksi `products`. Firestore secara otomatis akan membuatkan ID Dokumen yang unik secara acak.

### C. Update & Delete (Mengubah & Menghapus Data)
*   **Fungsi API Update:** `.collection('products').doc(productId).update(newData)`
*   **Fungsi API Delete:** `.collection('products').doc(productId).delete()`
*   **Cara Kerja:** Menargetkan spesifik ID Dokumen (`productId`), lalu memperbarui field tertentu atau menghapus seluruh dokumen tersebut.

---

## 4. API Khusus: Atomic Transaction (Keamanan Data)
Digunakan saat melakukan "Update Stok" (Barang Masuk/Keluar).

*   **Fungsi API:** `_db.runTransaction((transaction) async { ... })`
*   **Kenapa ini penting?**
    Jika menggunakan API *Update* biasa, bisa terjadi "Race Condition". Misalnya, sisa stok 10. Petugas A dan B bersamaan menekan tombol "Stok Keluar 8". Jika pakai update biasa, stok bisa menjadi minus 6.
*   **Cara Kerja Atomic Transaction API:**
    1. API membaca stok saat ini di server (mengunci dokumen).
    2. API melakukan kalkulasi (10 - 8 = 2).
    3. Jika valid, API menulis stok baru (2) ke server dan melepas kunci.
    4. Jika Petugas B masuk di waktu bersamaan, ia harus menunggu Petugas A selesai, lalu ia akan membaca stok terbaru (2), dan transaksinya (2 - 8) akan ditolak karena stok tidak cukup.

---

## 5. Hubungan Object-Relational Mapping (ORM) Manual

Karena Firebase Firestore mengembalikan data dalam format Map/JSON (`Map<String, dynamic>`), aplikasi ini menggunakan *Data Models* (`product_model.dart`, `user_model.dart`) untuk mengubah JSON dari API menjadi Objek Dart.

*   `fromFirestore(DocumentSnapshot doc)` : Mengubah respon API (JSON) menjadi Objek Dart yang bisa dibaca aplikasi.
*   `toMap()` : Mengubah Objek Dart kembali menjadi format JSON sebelum dikirim via API ke Firestore.
