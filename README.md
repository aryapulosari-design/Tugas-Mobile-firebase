# 📝 Catatan Kuliah Cloud — Flutter & Firebase Cloud Firestore

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com/)
[![Cloud Firestore](https://img.shields.io/badge/Cloud%20Firestore-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com/docs/firestore)
[![Material 3](https://img.shields.io/badge/UI-Material%203-indigo?style=for-the-badge)](https://m3.material.io/)

Aplikasi pencatatan ringkasan kuliah berbasis multi-platform (Android, Web, Windows) yang dibangun menggunakan **Flutter** dan terintegrasi dengan **Firebase Authentication** serta **Cloud Firestore NoSQL Database** secara real-time.

Proyek ini dibuat untuk memenuhi tugas mata kuliah **Pemrograman Perangkat Bergerak (Mobile Programming)** dengan fokus implementasi Cloud Backend, sinkronisasi data real-time, dan pengamanan hak akses data per-pengguna melalui Firestore Security Rules.

---

## ✨ Fitur Utama

- 🔐 **Autentikasi Anonim (Firebase Auth)**  
  Masuk otomatis tanpa registrasi ribet menggunakan akun anonim Firebase (`signInAnonymously`), dengan UID unik untuk setiap sesi pengguna.

- ⚡ **Real-time Synchronized CRUD**  
  - **Create**: Menambah catatan kuliah baru dengan validasi form & server timestamp.
  - **Read**: Menampilkan daftar catatan kuliah secara *live* menggunakan `StreamBuilder` dan Firestore snapshots.
  - **Update**: Memperbarui judul dan isi catatan dengan timestamp perubahan terbaru.
  - **Delete**: Menghapus catatan dengan dialog konfirmasi keamanan.

- 🛡️ **Aturan Keamanan Data (Security Rules)**  
  Akses data dibatasi ketat pada tingkat dokumen (`users/{uid}/catatan/{idCatatan}`). Setiap pengguna hanya berhak membaca dan menulis data miliknya sendiri.

- 🧪 **Dukungan Firebase Local Emulator Suite**  
  Mendukung pengujian lokal tanpa kuota cloud menggunakan Firebase Emulator (Auth, Firestore, dan Emulator UI).

- 📋 **Info Akun & Salin UID**  
  Fitur inspeksi UID akun pengguna dengan satu klik salin ke clipboard untuk pengujian pada Firebase Rules Simulator.

- 🎨 **Tampilan Antarmuka Modern (Material Design 3)**  
  Dilengkapi empty-state informatif, feedback aksi pengguna melalui floating snackbar, indikator loading, dan penanganan error yang andal.

---

## 🗄️ Struktur Database Cloud Firestore

Data catatan disimpan dengan arsitektur subkoleksi berjenjang per-pengguna untuk menjamin isolasi data:

```text
users (Collection)
 └── {uid} (Document ID pengguna dari Firebase Auth)
      └── catatan (Sub-collection)
           └── {idCatatan} (Auto-generated Document ID)
                ├── judul: String (cth: "Pengantar Cloud Computing")
                ├── isi: String (cth: "Ringkasan arsitektur NoSQL...")
                ├── createdAt: Timestamp (serverTimestamp)
                └── updatedAt: Timestamp (serverTimestamp)
```

---

## 🛡️ Firestore Security Rules

Keamanan data diatur langsung di file `firestore.rules`:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid}/catatan/{idCatatan} {
      allow read, write: if request.auth != null
                         && request.auth.uid == uid;
    }
  }
}
```

### Penjelasan Logika Keamanan:
1. `request.auth != null`: Memastikan request datang dari pengguna yang telah diautentikasi (termasuk Anonymous Auth).
2. `request.auth.uid == uid`: Memastikan pengguna hanya dapat membaca, mengubah, dan menghapus catatan di dalam path `users/{uid}` milik dirinya sendiri. Pengguna lain tidak diizinkan mengakses data ini.

---

## 📁 Struktur Direktori Proyek

```text
tugas8_cloud/
├── android/                  # Konfigurasi platform Android
├── ios/                      # Konfigurasi platform iOS
├── web/                      # Konfigurasi platform Web
├── windows/                  # Konfigurasi platform Windows Desktop
├── lib/
│   ├── firebase_options.dart # Konfigurasi platform Firebase
│   └── main.dart             # Kode utama aplikasi (UI, Auth, Firestore CRUD)
├── firebase.json             # Konfigurasi Firebase CLI & Emulator Suite
├── firestore.rules           # Aturan keamanan database Firestore
├── pubspec.yaml              # Dependensi dan metadata proyek Flutter
└── README.md                 # Dokumentasi proyek
```

---

## 🚀 Panduan Memulai & Menjalankan Proyek

### 1. Prasyarat Sistem
- **Flutter SDK** (versi ^3.13.2 atau lebih baru)
- **Dart SDK** (termasuk di dalam Flutter)
- **Node.js & Java (JRE/JDK 11+)** *(opsional, untuk Firebase Emulator)*
- **Firebase CLI** (`npm install -g firebase-tools`)

### 2. Kloning Repositori
```bash
git clone https://github.com/aryapulosari-design/Tugas-Mobile-firebase.git
cd Tugas-Mobile-firebase
```

### 3. Pasang Dependensi
```bash
flutter pub get
```

### 4. Menjalankan Menggunakan Firebase Emulator (Opsional / Lokal)
Jika ingin menjalankan tanpa kuota Firebase cloud:

1. Buka terminal baru dan jalankan emulator:
   ```bash
   firebase emulators:start
   ```
2. Pastikan di `lib/main.dart` variabel:
   ```dart
   const bool useLocalEmulator = true;
   ```
3. Buka UI Emulator di peramban: `http://localhost:4000`

### 5. Menjalankan Aplikasi
Pilih perangkat target dan jalankan:

```bash
# Menjalankan di Chrome (Web)
flutter run -d chrome

# Menjalankan di Android emulator / perangkat fisik
flutter run -d android

# Menjalankan di Windows desktop
flutter run -d windows
```

---

## 📦 Dependensi Utama

| Paket | Versi | Deskripsi |
|---|---|---|
| [`firebase_core`](https://pub.dev/packages/firebase_core) | `^5.1.0` | Inisialisasi koneksi aplikasi ke Firebase |
| [`firebase_auth`](https://pub.dev/packages/firebase_auth) | `^7.0.1` | Autentikasi pengguna anonim |
| [`cloud_firestore`](https://pub.dev/packages/cloud_firestore) | `^7.1.0` | Database dokumen NoSQL real-time cloud |
| [`cupertino_icons`](https://pub.dev/packages/cupertino_icons) | `^1.0.8` | Ikon pelengkap antarmuka |

---

## 👨‍💻 Pengembang

- **Nama**: Arya Kharisudin Irfani
- **Mata Kuliah**: Pemrograman Mobile (Teori - Firebase Cloud Firestore)
- **Program Studi**: Teknik Informatika - UIN S1

---

*Dikembangkan dengan ❤️ menggunakan Flutter & Firebase.*
