package models

import "time"

type Edukasi struct {
	ID          string    `json:"id"`
	Judul       string    `json:"judul"`
	Kategori    string    `json:"kategori"`
	Ringkasan   string    `json:"ringkasan"`
	Konten      string    `json:"konten"`
	Ikon        string    `json:"ikon"`
	Urutan      int       `json:"urutan"`
	Referensi   string    `json:"referensi"`
	CreatedAt   time.Time `json:"created_at"`
}

type MonitoringStats struct {
	TotalLaporan       int                `json:"total_laporan"`
	LaporanTerkirim    int                `json:"laporan_terkirim"`
	LaporanDiproses    int                `json:"laporan_diproses"`
	LaporanSelesai     int                `json:"laporan_selesai"`
	TotalChecklist     int                `json:"total_checklist"`
	RataRataKepatuhan  float64            `json:"rata_rata_kepatuhan_persen"`
	KategoriTerbanyak  string             `json:"kategori_terbanyak"`
	LokasiRawan        []string           `json:"lokasi_rawan"`
	StatusSistem       string             `json:"status_sistem"`
	KeamananStatus     string             `json:"keamanan_status"`
	IntegrityValid     bool               `json:"integrity_valid"`
}