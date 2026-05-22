import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

// === MAIN APPLICATION CONFIGURATION ===
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catatan Mahasiswa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
      },
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/tambah':
          // Mode Tambah Baru: argumen dikosongkan (null)
            final argumentLama = settings.arguments as Catatan?;
            return MaterialPageRoute(
              builder: (_) => TambahCatatanPage(catatanLama: argumentLama),
            );
          case '/detail':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => DetailCatatanPage(
                catatan: args['catatan'],
                index: args['index'],
              ),
            );
        }
        return null;
      },
    );
  }
}

// === DATA MODEL ===
class Catatan {
  String judul;
  String isi;
  String kategori;
  String email; // Fitur Tugas 3: Tambah field email
  DateTime dibuatPada;

  Catatan({
    required this.judul,
    required this.isi,
    required this.kategori,
    required this.email,
    required this.dibuatPada,
  });
}

// === HOME PAGE (DENGAN FILTER KATEGORI) ===
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // State: Daftar catatan awal
  final List<Catatan> _catatan = [
    Catatan(
      judul: 'Belajar Flutter',
      isi: 'Mempelajari Stateful Widget, Form, dan Navigation.',
      kategori: 'Kuliah',
      email: 'akmal@unpas.ac.id',
      dibuatPada: DateTime.now(),
    ),
  ];

  // Fitur Tugas 2: State untuk menyimpan filter yang dipilih
  String _filterKategori = 'Semua';
  final _filterOpsi = const ['Semua', 'Kuliah', 'Tugas', 'Pribadi', 'Lainnya'];

  // Membuka halaman tambah catatan
  Future<void> _bukaTambahCatatan() async {
    final hasil = await Navigator.pushNamed(context, '/tambah');

    if (hasil is Catatan) {
      setState(() {
        _catatan.add(hasil);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Catatan "${hasil.judul}" ditambahkan')),
      );
    }
  }

  // Fitur Tugas 1: Membuka halaman detail dan menangkap jika ada update data
  Future<void> _bukaDetailCatatan(Catatan catatan, int indexAsli) async {
    final hasil = await Navigator.pushNamed(
      context,
      '/detail',
      arguments: {'catatan': catatan, 'index': indexAsli},
    );

    // Jika membawa data update dari aksi Edit, perbarui list berdasarkan indeks aslinya
    if (hasil is Map<String, dynamic> && hasil['status'] == 'update') {
      setState(() {
        _catatan[indexAsli] = hasil['data'];
      });
    }
  }

  void _hapusCatatan(int indexAsli) {
    setState(() {
      _catatan.removeAt(indexAsli);
    });
  }

  String _formatTanggal(DateTime dt) {
    return "${dt.day}/${dt.month}/${dt.year}";
  }

  @override
  Widget build(BuildContext context) {
    // Proses memfilter data yang akan ditampilkan ke UI
    List<Map<String, dynamic>> catatanTerfilter = [];
    for (int i = 0; i < _catatan.length; i++) {
      if (_filterKategori == 'Semua' || _catatan[i].kategori == _filterKategori) {
        catatanTerfilter.add({'data': _catatan[i], 'indexAsli': i});
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Fitur Tugas 2: Dropdown Filter di AppBar
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: DropdownButton<String>(
              value: _filterKategori,
              icon: const Icon(Icons.filter_list, color: Colors.black),
              underline: const SizedBox(),
              onChanged: (String? newValue) {
                setState(() {
                  _filterKategori = newValue!;
                });
              },
              items: _filterOpsi.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        ],
      ),
      body: catatanTerfilter.isEmpty
          ? const Center(
              child: Text(
                'Tidak ada catatan dalam kategori ini.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: catatanTerfilter.length,
              itemBuilder: (context, i) {
                final c = catatanTerfilter[i]['data'] as Catatan;
                final indexAsli = catatanTerfilter[i]['indexAsli'] as int;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  elevation: 2,
                  child: ListTile(
                    title: Text(c.judul, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${c.kategori} • ${_formatTanggal(c.dibuatPada)}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _hapusCatatan(indexAsli),
                    ),
                    onTap: () => _bukaDetailCatatan(c, indexAsli),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _bukaTambahCatatan,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// === TAMBAH & EDIT CATATAN PAGE (REUSABLE FORM) ===
class TambahCatatanPage extends StatefulWidget {
  final Catatan? catatanLama; // Fitur Tugas 1: Jika tidak null, berarti mode EDIT
  const TambahCatatanPage({super.key, this.catatanLama});

  @override
  State<TambahCatatanPage> createState() => _TambahCatatanPageState();
}

class _TambahCatatanPageState extends State<TambahCatatanPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _judulCtrl;
  late TextEditingController _isiCtrl;
  late TextEditingController _emailCtrl; // Fitur Tugas 3: Controller Email

  String _kategori = 'Kuliah';
  final _kategoriOpsi = const ['Kuliah', 'Tugas', 'Pribadi', 'Lainnya'];

  @override
  void initState() {
    super.initState();
    // Fitur Tugas 1: Jika mode edit, isi controller dengan data lama
    _judulCtrl = TextEditingController(text: widget.catatanLama?.judul ?? '');
    _isiCtrl = TextEditingController(text: widget.catatanLama?.isi ?? '');
    _emailCtrl = TextEditingController(text: widget.catatanLama?.email ?? '');
    _kategori = widget.catatanLama?.kategori ?? 'Kuliah';
  }

  @override
  void dispose() {
    _judulCtrl.dispose();
    _isiCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _simpan() {
    if (!_formKey.currentState!.validate()) return;

    final catatanHasil = Catatan(
      judul: _judulCtrl.text.trim(),
      isi: _isiCtrl.text.trim(),
      kategori: _kategori,
      email: _emailCtrl.text.trim(),
      dibuatPada: widget.catatanLama?.dibuatPada ?? DateTime.now(),
    );

    Navigator.pop(context, catatanHasil);
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.catatanLama != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditMode ? 'Edit Catatan' : 'Tambah Catatan')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _judulCtrl,
              decoration: const InputDecoration(
                labelText: 'Judul',
                prefixIcon: Icon(Icons.title),
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Judul wajib diisi';
                if (v.trim().length < 3) return 'Minimal 3 karakter';
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Fitur Tugas 3: Input Field Email dengan Validasi Regex
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Pengirim',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
                // Regex standar untuk mengecek kevalidan format email
                final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!emailRegex.hasMatch(v.trim())) return 'Format email tidak valid';
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _kategori,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
              items: _kategoriOpsi
                  .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                  .toList(),
              onChanged: (v) => setState(() => _kategori = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _isiCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Isi Catatan',
                prefixIcon: Icon(Icons.notes),
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Isi wajib diisi' : null,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _simpan,
              icon: Icon(isEditMode ? Icons.update : Icons.save),
              label: Text(isEditMode ? 'Perbarui Catatan' : 'Simpan Catatan'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// === DETAIL CATATAN PAGE (DENGAN AKSI EDIT) ===
class DetailCatatanPage extends StatefulWidget {
  final Catatan catatan;
  final int index;
  const DetailCatatanPage({super.key, required this.catatan, required this.index});

  @override
  State<DetailCatatanPage> createState() => _DetailCatatanPageState();
}

class _DetailCatatanPageState extends State<DetailCatatanPage> {
  late Catatan _currentCatatan;

  @override
  void initState() {
    super.initState();
    _currentCatatan = widget.catatan;
  }

  // Fitur Tugas 1: Fungsi memicu halaman edit dari dalam halaman detail
  Future<void> _bukaEditHalaman() async {
    final updateData = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TambahCatatanPage(catatanLama: _currentCatatan),
      ),
    );

    if (updateData is Catatan) {
      setState(() {
        _currentCatatan = updateData; // Update tampilan internal detail page
      });

      if (!mounted) return;
      // Berikan sinyal balik ke HomePage bahwa data telah berubah
      Navigator.pop(context, {'status': 'update', 'data': updateData});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Catatan'),
        actions: [
          // Fitur Tugas 1: Tombol Edit di bagian kanan atas AppBar Detail
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _bukaEditHalaman,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentCatatan.judul,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text(_currentCatatan.kategori),
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                ),
                const SizedBox(width: 8),
                // Menampilkan email pengirim yang diinput
                Expanded(
                  child: Text(
                    'oleh: ${_currentCatatan.email}',
                    style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(height: 32, thickness: 1),
            Text(
              _currentCatatan.isi,
              style: const TextStyle(fontSize: 16, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}