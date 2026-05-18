# 🚀 Rencana Pembelajaran Full-Stack Web Development

Dokumen ini berisi peta jalan (*roadmap*) dan kumpulan instruksi (*prompt*) yang dirancang khusus untuk membimbing Anda belajar membangun aplikasi web Full-Stack dari nol. 

**Tujuan:** Menguasai React JS, Node.js, Express JS, MySQL, dan konsep REST API / CRUD untuk memenuhi kualifikasi industri.

**Skenario Project:** Membangun aplikasi **"Task Management System"** (To-Do List).

---

## 🛠️ Persiapan Awal (Prasyarat)
Sebelum memulai percakapan baru dengan AI untuk project ini, pastikan Anda sudah menyiapkan hal-hal berikut:
1.  **Node.js**: [Download & Install](https://nodejs.org/)
2.  **Visual Studio Code (VS Code)**: Code editor.
3.  **XAMPP** atau **MySQL Workbench**: Untuk menjalankan server database MySQL lokal.
4.  **Git**: [Download & Install](https://git-scm.com/)

> [!TIP]
> Buatlah sebuah folder kosong baru di komputer Anda khusus untuk belajar ini (misalnya: `D:\Belajar-Fullstack-TaskApp`) dan buka folder tersebut di VS Code.

---

## 📋 Fase Pembelajaran & Kumpulan Prompt

Gunakan prompt berikut **satu per satu** di sesi percakapan (chat) baru saat Anda siap memulai. Jangan lanjut ke fase berikutnya jika fase saat ini masih error atau belum Anda pahami sepenuhnya.

### Fase 1: Setup Backend Server
**Fokus:** Node.js, Express JS, Routing Dasar.

**Prompt untuk disalin:**
```text
Halo! Saya ingin belajar Full-Stack Web Development sesuai rencana kita sebelumnya. Saya sudah membuat folder kosong dan siap memulai Fase 1. 

Tolong pandu saya langkah demi langkah untuk:
1. Menginisialisasi project Node.js (package.json).
2. Menginstal framework Express JS dan dependensi dasar lainnya (seperti nodemon).
3. Membuat file server dasar (index.js) yang bisa dijalankan dan mengembalikan teks "Hello World".
Tolong berikan penjelasannya dengan bahasa yang mudah dipahami.
```

### Fase 2: Desain Database & Koneksi MySQL
**Fokus:** SQL, MySQL, Koneksi Database di Backend.

**Prompt untuk disalin:**
```text
Server Express JS sudah berhasil berjalan! Sekarang mari masuk ke Fase 2.

1. Tolong berikan saya query SQL untuk membuat database bernama `task_db` dan tabel bernama `tasks` (dengan kolom: id, title, description, is_completed).
2. Pandu saya cara menginstal package mysql2 di Node.js.
3. Berikan contoh kode untuk menghubungkan server Express JS saya ke database MySQL lokal tersebut.
```

### Fase 3: Membangun REST API (CRUD Backend)
**Fokus:** REST API, Operasi CRUD, Endpoint.

**Prompt untuk disalin:**
```text
Koneksi database sudah berhasil! Sekarang kita buat REST API-nya di Fase 3.

Tolong berikan kode lengkap dan penjelasan untuk membuat 4 endpoint CRUD di Express JS:
1. CREATE: Endpoint (POST) untuk menambahkan task baru ke database.
2. READ: Endpoint (GET) untuk mengambil semua daftar task.
3. UPDATE: Endpoint (PUT) untuk mengubah status 'is_completed' atau isi task.
4. DELETE: Endpoint (DELETE) untuk menghapus task dari database.
```

### Fase 4: Inisialisasi Frontend (React JS)
**Fokus:** React JS dasar, Vite, Struktur Folder.

**Prompt untuk disalin:**
```text
Backend REST API saya sudah selesai dan bisa dites. Sekarang kita masuk ke Fase 4.

Tolong pandu saya cara membuat project React JS baru menggunakan Vite di dalam folder terpisah (misalnya folder 'frontend'). Lalu jelaskan struktur folder dasar React tersebut dan bagaimana cara menjalankannya.
```

### Fase 5: Integrasi Frontend ke Backend (Fetch Data)
**Fokus:** Fetch API, State Management di React, React Hooks (useEffect, useState).

**Prompt untuk disalin:**
```text
Frontend React sudah berjalan. Ini adalah Fase 5, fase integrasi.

Tolong ajarkan saya cara menggunakan `useEffect` dan `useState` di React untuk melakukan Fetch (mengambil) data dari REST API Backend saya (endpoint GET). Kemudian, pandu saya cara me-render (menampilkan) data tersebut menjadi sebuah daftar (list) di UI React.
```

### Fase 6: Menyelesaikan CRUD di Frontend
**Fokus:** Handling Form, HTTP Requests, Interaktivitas.

**Prompt untuk disalin:**
```text
Data sudah berhasil tampil! Sekarang mari kita lengkapi fungsinya di Fase 6.

1. Pandu saya membuat Form di React untuk menambahkan task baru (panggil endpoint POST).
2. Tambahkan tombol "Hapus" di setiap item task untuk memanggil endpoint DELETE.
3. Pandu saya menambahkan tombol untuk menandai task "Selesai" (memanggil endpoint PUT).
```

### Fase 7: Styling & UI Polish
**Fokus:** HTML, CSS.

**Prompt untuk disalin:**
```text
Semua fungsi CRUD sekarang sudah bekerja sempurna dari Frontend ke Database!

Untuk Fase 7, mari kita percantik tampilannya. Berikan saya panduan singkat atau contoh kode CSS murni (Vanilla CSS) untuk merapikan list task, memberikan efek hover pada tombol, dan membuat layout-nya berada di tengah halaman (Card design) agar terlihat profesional.
```

### Fase 8: Version Control (Git & GitHub)
**Fokus:** Git, GitHub, Portfolio.

**Prompt untuk disalin:**
```text
Aplikasi saya sudah selesai dan terlihat bagus! Sebagai langkah terakhir (Fase 8), tolong pandu saya cara:
1. Menginisialisasi Git di project saya.
2. Melakukan commit semua file.
3. Membuat repository di GitHub dan nge-push kode saya ke sana agar bisa dijadikan portfolio web.
```

---

> [!IMPORTANT]
> **Aturan Belajar Utama:** 
> Jangan hanya melakukan Copy-Paste (CoPas). Ketik ulang kodenya secara manual, perhatikan pesan error jika ada, dan jangan ragu untuk bertanya kepada AI: *"Apa maksud dari baris kode ini?"* jika ada bagian yang membingungkan.
