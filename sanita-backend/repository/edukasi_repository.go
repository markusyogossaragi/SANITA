package repository

import (
	"sanita/models"
	"sync"
	"time"
)

type EdukasiRepository struct {
	mu    sync.RWMutex
	items []*models.Edukasi
}

func NewEdukasiRepository() *EdukasiRepository {
	repo := &EdukasiRepository{
		items: make([]*models.Edukasi, 0),
	}
	repo.seedMateriEdukasi()
	return repo
}

func (r *EdukasiRepository) seedMateriEdukasi() {
	r.items = []*models.Edukasi{
		{
			ID:        "edu-01",
			Judul:     "Standar Kualitas & Higiene Air Bersih",
			Kategori:  "Air Bersih",
			Ringkasan: "Kriteria fisik, kimiawi, dan mikrobiologis air layak guna di fasilitas tempat kerja.",
			Konten:    "Air bersih di tempat kerja wajib memenuhi syarat Permenkes: tidak berbau, tidak berasa, tidak berwarna, serta bebas dari bakteri patogen seperti E. coli. Sediakan wadah tertutup dan lakukan pembersihan toren secara berkala.",
			Ikon:      "water_drop",
			Urutan:    1,
			Referensi: "Permenkes No. 2 Tahun 2023 tentang Kesehatan Lingkungan",
			CreatedAt: time.Now(),
		},
		{
			ID:        "edu-02",
			Judul:     "Sanitasi Toilet & Fasilitas CTPS",
			Kategori:  "Sanitasi Dasar",
			Ringkasan: "Protokol pembersihan toilet dan pentingnya sarana Cuci Tangan Pakai Sabun.",
			Konten:    "Toilet harus memiliki ventilasi silang, lantai tidak licin, air mengalir kontinu, dan tempat sampah pembalut tertutup. Fasilitas CTPS dengan sabun cair harus tersedia di depan toilet dan area makan untuk memutus transmisi fekal-oral.",
			Ikon:      "wash",
			Urutan:    2,
			Referensi: "Pedoman Sanitasi Tempat Kerja Kemenaker & Kemenkes RI",
			CreatedAt: time.Now(),
		},
		{
			ID:        "edu-03",
			Judul:     "Manajemen Sampah & Prinsip 3R",
			Kategori:  "Pengelolaan Sampah",
			Ringkasan: "Pemilahan sampah organik, anorganik, dan B3 untuk mencegah bau dan sarang penyakit.",
			Konten:    "Tempat sampah wajib memiliki penutup kedap bau dan injakan kaki (pedal). Lakukan pengosongan maksimal setiap 1x24 jam untuk mencegah timbulan belatung dan perkembangbiakan lalat.",
			Ikon:      "delete_outline",
			Urutan:    3,
			Referensi: "UU No. 18 Tahun 2008 tentang Pengelolaan Sampah",
			CreatedAt: time.Now(),
		},
		{
			ID:        "edu-04",
			Judul:     "Ventilasi & Sirkulasi Udara Sehat",
			Kategori:  "Kualitas Udara",
			Ringkasan: "Pencegahan Sick Building Syndrome (SBS) dan penyebaran droplet saluran pernapasan.",
			Konten:    "Ruangan kerja tertutup wajib memiliki pergantian udara minimal 6-12 kali per jam (ACH). Buka jendela di pagi hari, bersihkan filter AC setiap 2-4 minggu, dan pantau kelembapan antara 40-60%.",
			Ikon:      "air",
			Urutan:    4,
			Referensi: "Permenaker No. 5 Tahun 2018 tentang K3 Lingkungan Kerja",
			CreatedAt: time.Now(),
		},
		{
			ID:        "edu-05",
			Judul:     "Pengendalian Vektor & Binatang Pembawa Penyakit",
			Kategori:  "Pengendalian Vektor",
			Ringkasan: "Eliminasi tempat perindukan nyamuk (DBD), kecoa, dan tikus (Leptospirosis).",
			Konten:    "Genangan air di talang, pot bunga, atau lantai kamar mandi harus dikeringkan segera. Terapkan 3M Plus dan pastikan celah dinding tertutup kawat kasa untuk mencegah masuknya hama.",
			Ikon:      "pest_control",
			Urutan:    5,
			Referensi: "Permenkes No. 50 Tahun 2017 tentang Standar Baku Vektor",
			CreatedAt: time.Now(),
		},
		{
			ID:        "edu-06",
			Judul:     "Pencegahan Kecelakaan & Higiene Ruang Kerja",
			Kategori:  "Ergonomi & Kerapian",
			Ringkasan: "Prinsip 5R (Ringkas, Rapi, Resik, Rawat, Rajin) dalam menjaga kebersihan workstation.",
			Konten:    "Meja kerja, keyboard, dan perangkat bersama harus diseka secara rutin. Kabel teratur tanpa menjuntai mencegah bahaya tersandung dan kebakaran listrik.",
			Ikon:      "cleaning_services",
			Urutan:    6,
			Referensi: "Panduan Higiene Industri dan K3 Perkantoran",
			CreatedAt: time.Now(),
		},
	}
}

func (r *EdukasiRepository) FindAll() []*models.Edukasi {
	r.mu.RLock()
	defer r.mu.RUnlock()

	results := make([]*models.Edukasi, len(r.items))
	copy(results, r.items)
	return results
}