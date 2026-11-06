package models

import "time"

type ChecklistKondisi struct {
	AirBersih         bool `json:"air_bersih"`
	ToiletBersih      bool `json:"toilet_bersih"`
	TempatSampah      bool `json:"tempat_sampah"`
	VentilasiUdara    bool `json:"ventilasi_udara"`
	BebasGenangan     bool `json:"bebas_genangan"`
	KebersihanArea    bool `json:"kebersihan_area"`
}

type ChecklistItem struct {
	ID             string           `json:"id"`
	UserID         string           `json:"user_id"`
	Lokasi         string           `json:"lokasi"`
	Kondisi        ChecklistKondisi `json:"kondisi"`
	SkorTerpenuhi  int              `json:"skor_terpenuhi"` // e.g. 6
	TotalKondisi   int              `json:"total_kondisi"`  // 6
	Persentase     float64          `json:"persentase"`     // 100.0%
	StatusHasil    string           `json:"status_hasil"`   // "Sangat Baik", "Perlu Perbaikan", dll.
	SaranTindak    string           `json:"saran_tindak_lanjut"`
	IsSimulasi     bool             `json:"is_simulasi"`
	ChecksumSHA256 string           `json:"checksum_sha256"` // Anti-Tamper signature
	CreatedAt      time.Time        `json:"created_at"`
}