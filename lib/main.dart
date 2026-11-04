import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';

// Atur ke true untuk memakai Firebase Local Emulator (UI di http://localhost:4000)
// Atur ke false jika sudah menghubungkan ke Firebase Console cloud asli
const bool useLocalEmulator = true;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase.initializeApp error: $e');
  }

  if (useLocalEmulator) {
    try {
      const host = 'localhost';
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      debugPrint('Connected to Firebase Local Emulator at $host:8080 / $host:9099');
    } catch (e) {
      debugPrint('Gagal connect ke emulator: $e');
    }
  }

  runApp(const AplikasiCatatan());
}

class AplikasiCatatan extends StatelessWidget {
  const AplikasiCatatan({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Catatan Kuliah Cloud',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const GerbangAutentikasi(),
    );
  }
}

class GerbangAutentikasi extends StatefulWidget {
  const GerbangAutentikasi({super.key});

  @override
  State<GerbangAutentikasi> createState() => _GerbangAutentikasiState();
}

class _GerbangAutentikasiState extends State<GerbangAutentikasi> {
  late final Future<User> _prosesMasuk = _masuk();

  Future<User> _masuk() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser != null) return auth.currentUser!;
    final credential = await auth.signInAnonymously();
    return credential.user!;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User>(
      future: _prosesMasuk,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Autentikasi gagal'),
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'Gagal Terhubung ke Firebase',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Periksa koneksi internet dan pastikan fitur Anonymous Auth sudah diaktifkan di Firebase Console.\n\nDetail:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black87),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () {
                        setState(() {});
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Menghubungkan ke Cloud Firestore...'),
                ],
              ),
            ),
          );
        }
        return HalamanCatatan(uid: snapshot.data!.uid);
      },
    );
  }
}

class HalamanCatatan extends StatefulWidget {
  const HalamanCatatan({super.key, required this.uid});

  final String uid;

  @override
  State<HalamanCatatan> createState() => _HalamanCatatanState();
}

class _HalamanCatatanState extends State<HalamanCatatan> {
  CollectionReference<Map<String, dynamic>> get _catatan =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .collection('catatan');

  void _pesan(String teks) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(teks),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year;
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$day/$month/$year $hour:$minute';
    }
    return 'Baru saja';
  }

  void _tampilkanInfoPengguna() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.account_circle, color: Colors.indigo),
            SizedBox(width: 8),
            Text('Info Akun Anonim'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'UID Anda di Firebase:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            SelectableText(
              widget.uid,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Gunakan UID ini untuk menguji Rules Simulator pada Firebase Console (Langkah 11).',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: widget.uid));
              Navigator.of(ctx).pop();
              _pesan('UID disalin ke clipboard');
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Salin UID'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Future<void> _formCatatan({
    QueryDocumentSnapshot<Map<String, dynamic>>? dokumen,
  }) async {
    final data = dokumen?.data();
    var judul = (data?['judul'] as String?) ?? '';
    var isi = (data?['isi'] as String?) ?? '';
    final kunciForm = GlobalKey<FormState>();

    final simpan = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dokumen == null ? 'Tambah Catatan' : 'Ubah Catatan'),
        content: Form(
          key: kunciForm,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: judul,
                  decoration: const InputDecoration(
                    labelText: 'Judul',
                    hintText: 'Contoh: Pengantar Cloud',
                  ),
                  maxLength: 80,
                  validator: (nilai) => (nilai == null || nilai.trim().isEmpty)
                      ? 'Judul wajib diisi'
                      : null,
                  onSaved: (nilai) => judul = nilai!.trim(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: isi,
                  decoration: const InputDecoration(
                    labelText: 'Isi catatan',
                    hintText: 'Tulis ringkasan catatan kuliah...',
                  ),
                  maxLines: 4,
                  maxLength: 500,
                  validator: (nilai) => (nilai == null || nilai.trim().isEmpty)
                      ? 'Isi catatan wajib diisi'
                      : null,
                  onSaved: (nilai) => isi = nilai!.trim(),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (kunciForm.currentState!.validate()) {
                kunciForm.currentState!.save();
                Navigator.of(dialogContext).pop(true);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (!mounted || simpan != true) return;

    try {
      if (dokumen == null) {
        await _catatan.add({
          'judul': judul,
          'isi': isi,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        _pesan('Catatan berhasil ditambahkan');
      } else {
        await dokumen.reference.update({
          'judul': judul,
          'isi': isi,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        _pesan('Catatan berhasil diubah');
      }
    } on FirebaseException catch (e) {
      _pesan('Gagal menyimpan: ${e.message ?? e.code}');
    } catch (e) {
      _pesan('Terjadi kesalahan: $e');
    }
  }

  Future<void> _hapusCatatan(
    QueryDocumentSnapshot<Map<String, dynamic>> dokumen,
  ) async {
    final data = dokumen.data();
    final judul = (data['judul'] as String?) ?? 'catatan';

    final setuju = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Catatan'),
        content: Text('Yakin ingin menghapus catatan "$judul"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (!mounted || setuju != true) return;

    try {
      await dokumen.reference.delete();
      _pesan('Catatan berhasil dihapus');
    } on FirebaseException catch (e) {
      _pesan('Gagal menghapus: ${e.message ?? e.code}');
    } catch (e) {
      _pesan('Terjadi kesalahan: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Catatan Kuliah Cloud',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Cloud Firestore Real-time CRUD',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Info Akun (UID)',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: _tampilkanInfoPengguna,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _catatan.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(
                      'Gagal membaca: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final daftar = snapshot.data?.docs ?? [];
          if (daftar.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.note_alt_outlined,
                      size: 72,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Belum ada catatan.',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tekan tombol Tambah di bawah untuk membuat catatan baru.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black45),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: daftar.length,
            itemBuilder: (context, index) {
              final dokumen = daftar[index];
              final data = dokumen.data();
              final waktuUpdate = _formatTimestamp(data['updatedAt']);

              return Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      (data['judul'] as String?) ?? '(tanpa judul)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text((data['isi'] as String?) ?? ''),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 13,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              waktuUpdate,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: Wrap(
                      spacing: 0,
                      children: [
                        IconButton(
                          tooltip: 'Ubah',
                          icon: const Icon(Icons.edit, color: Colors.indigo),
                          onPressed: () => _formCatatan(dokumen: dokumen),
                        ),
                        IconButton(
                          tooltip: 'Hapus',
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => _hapusCatatan(dokumen),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _formCatatan(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
    );
  }
}
