package models

import "time"

type LaporanStatus string

const (
	StatusTerkirim LaporanStatus = "terkirim"
	StatusProses   LaporanStatus = "diproses"
	StatusSelesai  LaporanStatus = "selesai"
	StatusDitolak  LaporanStatus = "ditolak"
)

type Laporan struct {
	ID             string        `json:"id"`
	UserID         string        `json:"user_id"`
	ReporterName   string        `json:"reporter_name"`
	JenisMasalah   string        `json:"jenis_permasalahan"`
	Lokasi         string        `json:"lokasi_kejadian"`
	Keterangan     string        `json:"keterangan"`
	FotoURL        string        `json:"foto_url,omitempty"`
	FotoThumb      string        `json:"foto_thumb,omitempty"`
	Status         LaporanStatus `json:"status"`
	PetugasCatatan string        `json:"petugas_catatan,omitempty"`
	IntegrityHMAC  string        `json:"integrity_hmac"` // Tamper-proof HMAC signature
	ClientIPHash   string        `json:"client_ip_hash"`  // Anonymized IP hash
	CreatedAt      time.Time     `json:"created_at"`
	UpdatedAt      time.Time     `json:"updated_at"`
}