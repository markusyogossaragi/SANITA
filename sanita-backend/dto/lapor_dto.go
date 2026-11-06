package dto

type LaporSubmitRequest struct {
	JenisMasalah string `json:"jenis_permasalahan" form:"jenis_permasalahan" binding:"required"`
	Lokasi       string `json:"lokasi_kejadian" form:"lokasi_kejadian" binding:"required,min=2,max=100"`
	Keterangan   string `json:"keterangan" form:"keterangan" binding:"required,min=5,max=1000"`
	FotoBase64   string `json:"foto_base64,omitempty"`
}

type LaporStatusUpdateRequest struct {
	Status         string `json:"status" binding:"required,oneof=pending diproses selesai ditolak"`
	PetugasCatatan string `json:"petugas_catatan" binding:"max=500"`
}