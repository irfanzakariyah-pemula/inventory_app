# Kamus Sintaks Aplikasi Smart Retail Inventory

Dokumen ini berisi daftar sintaks (potongan kode) yang digunakan dalam aplikasi ini, beserta penjelasan singkat untuk masing-masing sintaks. Sangat cocok digunakan untuk menjawab pertanyaan dosen saat sidang/presentasi.

---

## 1. Sintaks Dasar Dart & Flutter

*   `import 'package:...';`
    **Penjelasan:** Mengambil kode atau pustaka (library) dari file lain atau dari internet agar bisa digunakan di file ini.
*   `void main() async { ... }`
    **Penjelasan:** Fungsi utama yang pertama kali dijalankan oleh aplikasi saat baru dibuka.
*   `Future<void>` atau `Future<bool>`
    **Penjelasan:** Menandakan bahwa fungsi tersebut berjalan secara asinkron (membutuhkan waktu proses, misalnya mengambil data dari internet) dan hasilnya akan menyusul di masa depan (*future*).
*   `async`
    **Penjelasan:** Kata kunci untuk menandai bahwa suatu fungsi berjalan secara asinkron.
*   `await`
    **Penjelasan:** Perintah untuk menyuruh sistem menunggu sampai proses asinkron (seperti koneksi ke database) selesai, sebelum melanjutkan membaca baris kode berikutnya.
*   `try { ... } catch (e) { ... }`
    **Penjelasan:** Blok pelindung kode. Kode di dalam `try` akan dijalankan, dan jika terjadi *error* (misal internet putus), aplikasi tidak akan keluar paksa (crash), melainkan *error*-nya akan ditangkap oleh `catch`.
*   `TextEditingController()`
    **Penjelasan:** Variabel khusus untuk menangkap, membaca, atau menghapus teks yang diketikkan pengguna ke dalam form (kolom input text).
*   `dispose()`
    **Penjelasan:** Fungsi untuk membersihkan memori (menghapus variabel yang tidak terpakai) ketika sebuah halaman ditutup, agar aplikasi tidak lambat/berat.

---

## 2. Sintaks State Management (Provider)

*   `ChangeNotifier`
    **Penjelasan:** Kelas bawaan Flutter yang memberikan kemampuan pada suatu kelas (seperti Provider) untuk mengirimkan sinyal perubahan data ke tampilan (UI).
*   `notifyListeners();`
    **Penjelasan:** Perintah untuk mengirim sinyal/teriakan ke halaman tampilan (UI) bahwa "ada data yang berubah, tolong *refresh/rebuild* tampilanmu!".
*   `MultiProvider(providers: [ ... ])`
    **Penjelasan:** Tempat mendaftarkan semua "otak" aplikasi (Provider) pada file `main.dart` agar datanya bisa diakses secara global dari halaman mana pun.
*   `Provider.of<NamaProvider>(context, listen: false)`
    **Penjelasan:** Cara memanggil fungsi (logika) yang ada di dalam sebuah Provider dari halaman tampilan (UI), tanpa mendengarkan perubahan tampilannya secara terus-menerus.
*   `Consumer<NamaProvider>(builder: (context, provider, child) { ... })`
    **Penjelasan:** Widget yang bertugas "mendengarkan" sinyal dari `notifyListeners()`. Jika ada sinyal masuk, bagian di dalam Consumer ini akan di-*refresh* otomatis.

---

## 3. Sintaks Antarmuka / UI (Layar)

*   `StatelessWidget`
    **Penjelasan:** Jenis layar/widget yang tampilannya statis dan tidak bisa berubah dari dalam dirinya sendiri (harus diubah oleh Provider).
*   `StatefulWidget`
    **Penjelasan:** Jenis layar/widget dinamis yang bisa mengubah tampilannya sendiri dari dalam, seperti menyalakan/mematikan animasi atau tombol loading.
*   `setState(() { ... });`
    **Penjelasan:** Perintah khusus di dalam `StatefulWidget` untuk me-*refresh* sebagian layar secara langsung ketika nilai variabel diubah.
*   `Scaffold( ... )`
    **Penjelasan:** Kanvas dasar atau kerangka standar sebuah halaman aplikasi (menyediakan tempat untuk *app bar*, tombol melayang, dan warna latar).
*   `Navigator.push(context, MaterialPageRoute(builder: (_) => LayarBaru()));`
    **Penjelasan:** Perintah untuk pindah atau membuka halaman baru.
*   `Navigator.pop(context);`
    **Penjelasan:** Perintah untuk menutup halaman saat ini dan kembali ke halaman sebelumnya (seperti tombol *Back*).

---

## 4. Sintaks Database Supabase (Logika CRUD)

*   `Supabase.initialize(url: '...', anonKey: '...');`
    **Penjelasan:** Fungsi untuk menyambungkan aplikasi dengan database Supabase PostgreSQL di cloud (dilakukan di awal `main.dart`).
*   `await supabase.auth.signInWithPassword(email: '...', password: '...');`
    **Penjelasan:** Memanggil fitur autentikasi bawaan Supabase untuk memverifikasi email dan kata sandi saat proses Login.
*   `await supabase.from('nama_tabel').select();`
    **Penjelasan:** (Read) Query untuk menarik atau membaca semua data dari tabel yang ada di dalam database.
*   `await supabase.from('nama_tabel').insert({'kolom': nilai});`
    **Penjelasan:** (Create) Query untuk menyimpan atau memasukkan baris data baru ke dalam tabel di database.
*   `await supabase.from('nama_tabel').update({'kolom': nilai_baru}).eq('id', id_target);`
    **Penjelasan:** (Update) Query untuk memperbarui data yang sudah ada. `eq('id', ...)` berarti "ubah yang ID-nya sama dengan target ini".
*   `await supabase.from('nama_tabel').delete().eq('id', id_target);`
    **Penjelasan:** (Delete) Query untuk menghapus sebuah data secara permanen dari database berdasarkan ID tertentu.
*   `Product.fromMap(data)`
    **Penjelasan:** Fungsi penerjemah (Factory) yang bertugas mengubah data mentah berbentuk JSON/Map dari database menjadi bentuk objek (Class) yang dipahami oleh program Dart.
*   `product.toMap()`
    **Penjelasan:** Kebalikan dari fromMap, yaitu fungsi untuk menerjemahkan objek Dart kembali menjadi format Map agar bisa disimpan ke database Supabase.
