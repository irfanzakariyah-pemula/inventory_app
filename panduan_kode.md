# Panduan Penjelasan Sintaks & Kode Aplikasi

Dokumen ini adalah ringkasan dari sintaks (kode) penting yang menggerakkan aplikasi Smart Retail Inventory. Anda dapat menggunakan panduan ini jika dosen meminta Anda menjelaskan arti dari baris kode atau fungsi tertentu.

Karena kode keseluruhan sangat panjang, dokumen ini merangkum **konsep dan fungsi-fungsi inti** yang paling sering ditanyakan oleh dosen penguji.

---

## 1. Konsep Dasar Dart & Flutter yang Sering Ditanya
Sebelum masuk ke file, ini adalah sintaks dasar yang menyebar di seluruh aplikasi:

*   `Future<void>` atau `Future<bool>`: Artinya fungsi ini berjalan secara asinkron (tidak langsung selesai, melainkan menunggu proses lain seperti mengambil data dari internet/database).
*   `async` & `await`: Pasangan wajib dari `Future`. `async` menandakan fungsi tersebut asinkron, dan `await` menyuruh aplikasi untuk *menunggu* baris tersebut selesai sebelum lanjut ke baris bawahnya.
*   `notifyListeners()`: Ini adalah sintaks dari arsitektur **Provider**. Fungsinya untuk memberi tahu halaman UI (layar) bahwa "Hei, ada data yang berubah, tolong *refresh/rebuild* tampilan layarmu!".
*   `setState(() { ... })`: Sintaks untuk me-*refresh* sebagian kecil UI di dalam satu halaman yang sama (StatefulWidget) saat ada variabel yang berubah.

---

## 2. File `lib/main.dart` (Pintu Masuk Aplikasi)
File ini adalah kode pertama yang dijalankan oleh aplikasi.

```dart
void main() async {
  // 1. Memastikan kerangka Flutter sudah siap sebelum kode asinkron dijalankan
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Menghubungkan aplikasi ke Database Supabase
  await Supabase.initialize(
    url: 'https://rpczhekymdntopgzielj.supabase.co',
    anonKey: 'sb_publishable_zpXLr...', // (kunci rahasia API dipotong)
  );

  // 3. Menjalankan tampilan utama aplikasi
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  Widget build(BuildContext context) {
    // 4. MultiProvider digunakan agar semua "State / Logika" (seperti Auth, Produk, Kasir)
    //    bisa diakses dari halaman manapun tanpa harus dikirim manual satu-satu.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
      ],
      child: MaterialApp( ... ),
    );
  }
}
```

---

## 3. File `lib/providers/auth_provider.dart` (Logika Login)
Ini adalah logika di balik layar saat tombol "Masuk" ditekan.

```dart
// Fungsi login menerima email dan password
Future<bool> login(String email, String password) async {
  try {
    // 1. Memanggil fungsi bawaan Supabase untuk login menggunakan email & password
    final response = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user != null) {
      // 2. Jika login Supabase berhasil, ambil data detail 'role' user dari tabel 'users'
      final userData = await supabase
          .from('users') // Mengakses tabel users
          .select() // Mengambil data
          .eq('id', response.user!.id) // Mencari yang id-nya sama dengan user yg login
          .single(); // Ambil 1 baris data saja

      // 3. Menyimpan data tersebut ke variabel _currentUser (Model User)
      _currentUser = UserModel.fromMap(userData);
      
      // 4. Memberitahu UI bahwa proses selesai
      notifyListeners();
      return true; // Berhasil
    }
  } catch (error) {
    // 5. Jika password salah / internet mati, masuk ke sini
    _errorMessage = 'Login gagal: $error';
    notifyListeners();
    return false; // Gagal
  }
}
```

---

## 4. File `lib/providers/product_provider.dart` (Logika Database Barang)
Ini adalah inti dari aplikasi inventaris, yaitu cara mengambil dan mengubah stok.

### A. Sintaks Mengambil Daftar Barang (Read)
```dart
Future<void> fetchProducts() async {
  _isLoading = true; // Set status loading berputar
  notifyListeners(); // Refresh UI agar menampilkan logo loading

  // 1. Meminta data dari tabel 'products' di Supabase, dan diurutkan berdasarkan 'nama'
  final data = await supabase
      .from('products')
      .select()
      .order('nama', ascending: true);

  // 2. Mengubah data mentah (Map/JSON) dari database menjadi bentuk Objek Product (Dart)
  _products = (data as List).map((item) => Product.fromMap(item)).toList();
  
  _isLoading = false; // Matikan loading
  notifyListeners(); // Refresh UI untuk menampilkan daftar barang
}
```

### B. Sintaks Mengubah Stok (Update)
```dart
Future<bool> updateStock({
  required String productId, 
  required int jumlah, 
  required TransactionType type
}) async {
  // 1. Cek stok saat ini langsung ke server untuk menghindari data nyangkut (race condition)
  final current = await supabase.from('products').select('stok').eq('id', productId).single();
  final stokSebelum = current['stok'] as int;
  
  int stokBaru;
  if (type == TransactionType.masuk) {
    stokBaru = stokSebelum + jumlah; // Jika barang masuk, ditambah
  } else {
    stokBaru = stokSebelum - jumlah; // Jika barang keluar, dikurang
  }

  // 2. Mengirim data stok baru ke database
  await supabase
      .from('products')
      .update({'stok': stokBaru}) // Kolom yang diupdate hanya 'stok'
      .eq('id', productId); // Syarat (where): yang ID produknya sesuai

  notifyListeners();
  return true;
}
```

---

## 5. File `lib/screens/dashboard_screen.dart` (Sintaks Antarmuka/UI)
Berikut adalah penjelasan singkat bagaimana tampilan dibuat dengan Flutter.

```dart
// 1. StatelessWidget artinya halaman ini tampilannya statis (tidak berubah dari dalam dirinya sendiri, 
// melainkan berubah jika Provider memberikan sinyal notifyListeners).
class DashboardScreen extends StatelessWidget {
  
  @override
  Widget build(BuildContext context) {
    // 2. Consumer bertugas mendengarkan perubahan pada ProductProvider.
    // Jika data produk berubah, fungsi builder di dalam Consumer ini akan di-render ulang otomatis.
    return Consumer<ProductProvider>(
      builder: (ctx, productProv, _) {
        
        // 3. Mengambil total barang menggunakan logika 'where' (filter)
        final stokKritis = productProv.allProducts.where((p) => p.isStokKritis).length;

        // 4. Scaffold adalah kanvas dasar aplikasi (menyediakan background, AppBar, dll)
        return Scaffold(
          body: Column(
            children: [
              // 5. Menampilkan Teks
              Text('Total Barang Kritis: $stokKritis'),
            ],
          ),
        );
      },
    );
  }
}
```

---

## 6. Penjelasan Singkat Struktur File MVC (Model - View - Controller)
Jika dosen menanyakan "Pola arsitektur apa yang kamu gunakan?", jawablah: **"Mirip dengan MVC (Model-View-Controller) namun menggunakan Provider State Management."**

*   **Model (`lib/models/`):** Blueprint/Cetakan data. (Contoh: `product_model.dart` isinya hanya penamaan kolom seperti id, nama, stok, tanpa ada fungsi database).
*   **View (`lib/screens/` & `lib/widgets/`):** Tampilan murni (UI). Berisi tombol, teks, warna. (Contoh: `dashboard_screen.dart`).
*   **Controller / Provider (`lib/providers/`):** Otak dari aplikasi. Di sinilah proses logika, perhitungan, dan proses kirim/ambil data ke database Supabase dilakukan. (Contoh: `product_provider.dart`).

---

### Tips Penting Saat Dosen Menunjuk Baris Kode:
*   Jika kode diawali `await supabase.from(...)`: Itu adalah fungsi query ke database (CRUD). `select()` untuk Read, `insert()` untuk Create, `update()` untuk Update, dan `delete()` untuk Delete.
*   Jika ada `Navigator.push(...)`: Itu adalah kode untuk pindah (navigasi) ke halaman layar lain.
*   Jika ada `TextEditingController`: Itu adalah variabel yang tugasnya menangkap dan menyimpan ketikan keyboard yang dimasukkan user ke dalam kolom input (form).
