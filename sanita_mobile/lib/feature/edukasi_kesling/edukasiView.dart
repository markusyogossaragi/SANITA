import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';
import '../../core/datasources/apiDataSource.dart';
import '../../core/models/models.dart';

class EdukasiView extends StatefulWidget {
  final VoidCallback onBackToHome;

  const EdukasiView({super.key, required this.onBackToHome});

  @override
  State<EdukasiView> createState() => _EdukasiViewState();
}

class _EdukasiViewState extends State<EdukasiView> {
  List<EdukasiModel> _materi = [];
  bool _isLoading = true;
  String _selectedCategory = 'Semua';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadMateri();
  }

  void _loadMateri() async {
    try {
      final res = await ApiDataSource().get('/edukasi');
      final list = (res['data'] as List).map((e) => EdukasiModel.fromJson(e)).toList();
      setState(() {
        _materi = list;
        _isLoading = false;
      });
    } catch (_) {
      // 6 Comprehensive Educational Modules (Page 6 of SANITA.pdf)
      setState(() {
        _materi = [
          EdukasiModel(
            id: '1',
            judul: 'Standar Kualitas & Higiene Air Bersih',
            kategori: 'Air Bersih',
            ringkasan: 'Kriteria fisik, kimiawi, dan mikrobiologis air layak guna di tempat kerja.',
            konten:
                'Air bersih untuk keperluan higiene sanitasi wajib memenuhi parameter fisik (tidak berbau, tidak berasa, tidak berwarna, dan jernih), parameter kimia (pH normal 6.5 - 8.5), serta bebas dari bakteri E. coli atau coliform. Tandon penampung air wajib dibersihkan dan dikuras minimal 1 bulan sekali.',
            ikon: 'water_drop',
            urutan: 1,
            referensi: 'Permenkes No. 2 Tahun 2023',
          ),
          EdukasiModel(
            id: '2',
            judul: 'Sanitasi Toilet & Fasilitas CTPS',
            kategori: 'Sanitasi Dasar',
            ringkasan: 'Protokol kebersihan toilet dan cuci tangan pakai sabun.',
            konten:
                'Setiap tempat kerja wajib menyediakan toilet bersih yang terpisah antara pria dan wanita dengan rasio memadai. Fasilitas Cuci Tangan Pakai Sabun (CTPS) wajib dilengkapi air mengalir, sabun cair antiseptik, serta pengering tangan atau tisu sekali pakai untuk memutus rantai transmisi kuman.',
            ikon: 'wash',
            urutan: 2,
            referensi: 'Permenaker No. 5 Tahun 2018',
          ),
          EdukasiModel(
            id: '3',
            judul: 'Manajemen Sampah & Prinsip 3R',
            kategori: 'Pengelolaan Sampah',
            ringkasan: 'Pemilahan sampah organik, anorganik, dan limbah B3 di lingkungan kerja.',
            konten:
                'Tempat sampah harus kedap air, bertutup injak (pedal), dilapisi kantong plastik, dan terpilah: Organik (hijau), Anorganik/Kering (kuning), dan B3/Elektronik (merah). Sampah wajib dikosongkan secara berkala minimal sekali setiap 24 jam untuk mencegah bau dan penumpukan hama.',
            ikon: 'delete',
            urutan: 3,
            referensi: 'UU No. 18 Tahun 2008 & Permen LHK',
          ),
          EdukasiModel(
            id: '4',
            judul: 'Ventilasi & Kualitas Udara Ruang Kerja',
            kategori: 'Kualitas Udara',
            ringkasan: 'Standar pertukaran udara, suhu optimal, dan kelembapan ruangan.',
            konten:
                'Ruang kerja tertutup membutuhkan ventilasi alami minimal 10% dari luas lantai atau sistem pendingin dengan filter udara bersih. Suhu nyaman ruang kerja berada di rentang 23°C - 26°C dengan kelembapan 40% - 60%. Exhaust fan dan kisi AC wajib diservis berkala guna mencegah Sick Building Syndrome (SBS).',
            ikon: 'air',
            urutan: 4,
            referensi: 'Permenkes No. 48 Tahun 2016',
          ),
          EdukasiModel(
            id: '5',
            judul: 'Pengendalian Vektor & Pencegahan Genangan',
            kategori: 'Pengendalian Vektor',
            ringkasan: 'Eliminasi sarang nyamuk, lalat, dan kecoa di lingkungan kantor/kampus.',
            konten:
                'Genangan air pada talang, pot bunga, tatakan dispenser, atau saluran drainase yang tersumbat menjadi habitat jentik nyamuk Aedes aegypti. Lakukan inspeksi PSN (Pemberantasan Sarang Nyamuk) 3M Plus secara rutin: Menguras, Menutup tempat air, dan Mendaur ulang barang bekas.',
            ikon: 'pest_control',
            urutan: 5,
            referensi: 'Permenkes No. 50 Tahun 2017',
          ),
          EdukasiModel(
            id: '6',
            judul: 'Higiene Personal & Ergonomi Ruang Kerja',
            kategori: 'Higiene & K3',
            ringkasan: 'Praktek kebersihan individu karyawan dan penataan area kerja bersih.',
            konten:
                'Setiap pekerja diharapkan menjaga kebersihan meja kerja masing-masing (clean desk policy), membersihkan keyboard dan permukaan telepon dengan cairan desinfektan, membuang sisa makanan segera ke tempat sampah organik, serta mematuhi etika batuk/bersin yang benar di ruang publik.',
            ikon: 'clean_hands',
            urutan: 6,
            referensi: 'Pedoman K3 Sanitasi Tempat Kerja',
          ),
        ];
        _isLoading = false;
      });
    }
  }

  List<EdukasiModel> get _filteredMateri {
    return _materi.where((item) {
      final matchesSearch = _searchQuery.isEmpty ||
          item.judul.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.konten.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.kategori.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'Semua' || item.kategori.toLowerCase() == _selectedCategory.toLowerCase();
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredMateri;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? SanitaColors.darkBackground : SanitaColors.background,
      appBar: AppBar(
        title: const Text('Edukasi Kesling', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: isDark ? SanitaColors.darkSurface : SanitaColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBackToHome,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: SanitaColors.primary))
          : Column(
              children: [
                // Top Education Header Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                  decoration: BoxDecoration(
                    color: isDark ? SanitaColors.darkSurface : SanitaColors.primarySurface,
                    border: Border(bottom: BorderSide(color: isDark ? SanitaColors.darkBorder : const Color(0xFFD1FAE5))),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Modul Sanitasi & Kesehatan Lingkungan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isDark ? SanitaColors.primaryLight : SanitaColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Pelajari panduan baku sanitasi sesuai Permenkes & regulasi K3 nasional.',
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : SanitaColors.textDark),
                      ),
                      const SizedBox(height: 12),

                      // Search input
                      TextField(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        style: TextStyle(color: isDark ? Colors.white : SanitaColors.textDark, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Cari modul, topik, atau kata kunci...',
                          hintStyle: TextStyle(fontSize: 13, color: isDark ? SanitaColors.darkTextMuted : Colors.grey.shade400),
                          prefixIcon: const Icon(Icons.search, size: 18, color: SanitaColors.textMuted),
                          filled: true,
                          fillColor: isDark ? SanitaColors.darkCard : Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? SanitaColors.darkBorder : SanitaColors.border)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? SanitaColors.darkBorder : SanitaColors.border)),
                        ),
                      ),
                    ],
                  ),
                ),

                // List of modules
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await Future.delayed(const Duration(milliseconds: 500));
                      _loadMateri();
                    },
                    color: SanitaColors.primary,
                    child: filtered.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 60),
                              Center(
                                child: Text('Tidak ada modul yang sesuai.', style: TextStyle(color: SanitaColors.textMuted)),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final item = filtered[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Card(
                                  color: isDark ? SanitaColors.darkCard : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: BorderSide(color: isDark ? SanitaColors.darkBorder : SanitaColors.border),
                                  ),
                                  child: ExpansionTile(
                                    leading: CircleAvatar(
                                      backgroundColor: isDark ? SanitaColors.primaryDark : SanitaColors.primarySurface,
                                      child: Text(
                                        '${item.urutan}',
                                        style: TextStyle(
                                          color: isDark ? Colors.white : SanitaColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      item.judul,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: isDark ? Colors.white : SanitaColors.textDark,
                                      ),
                                    ),
                                    subtitle: Text(
                                      item.kategori,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? SanitaColors.primaryLight : SanitaColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: isDark ? SanitaColors.darkSurface : const Color(0xFFF8FAFC),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: isDark ? SanitaColors.darkBorder : SanitaColors.border),
                                              ),
                                              child: Text(
                                                item.ringkasan,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDark ? Colors.white70 : SanitaColors.textDark,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              item.konten,
                                              style: TextStyle(
                                                fontSize: 13,
                                                height: 1.5,
                                                color: isDark ? SanitaColors.darkText : SanitaColors.textDark,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                const Icon(Icons.menu_book, size: 14, color: SanitaColors.textMuted),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Dasar Regulasi: ${item.referensi}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontStyle: FontStyle.italic,
                                                    color: isDark ? SanitaColors.darkTextMuted : SanitaColors.textMuted,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}