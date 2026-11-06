package dto

type ChecklistSubmitRequest struct {
	Lokasi            string `json:"lokasi" binding:"required,min=2,max=100"`
	AirBersih         bool   `json:"air_bersih"`
	ToiletBersih      bool   `json:"toilet_bersih"`
	TempatSampah      bool   `json:"tempat_sampah"`
	VentilasiUdara    bool   `json:"ventilasi_udara"`
	BebasGenangan     bool   `json:"bebas_genangan"`
	KebersihanArea    bool   `json:"kebersihan_area"`
}

type ChecklistResultResponse struct {
	ID             string   `json:"id"`
	Lokasi         string   `json:"lokasi"`
	SkorTerpenuhi  int      `json:"skor_terpenuhi"`
	TotalKondisi   int      `json:"total_kondisi"`
	Persentase     float64  `json:"persentase"`
	StatusHasil    string   `json:"status_hasil"`
	SaranTindak    string   `json:"saran_tindak_lanjut"`
	PoinPerbaikan  []string `json:"poin_perbaikan,omitempty"`
	CatatanSimulasi string  `json:"catatan_simulasi"`
	ChecksumSHA256 string   `json:"checksum_sha256"`
}