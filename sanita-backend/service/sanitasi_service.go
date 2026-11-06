package service

import (
	"errors"
	"fmt"
	"sanita/dto"
	"sanita/models"
	"sanita/repository"
	"sanita/utils"
	"strings"
	"time"

	"github.com/google/uuid"
)

type SanitasiService struct {
	ChecklistRepo *repository.ChecklistRepository
}

func NewSanitasiService(repo *repository.ChecklistRepository) *SanitasiService {
	return &SanitasiService{ChecklistRepo: repo}
}

func (s *SanitasiService) EvaluateChecklist(userID string, req dto.ChecklistSubmitRequest) (*dto.ChecklistResultResponse, error) {
	cleanLokasi := utils.SanitizeString(req.Lokasi)
	if strings.TrimSpace(cleanLokasi) == "" {
		return nil, errors.New("lokasi pemeriksaan wajib diisi")
	}

	score := 0
	var poinPerbaikan []string

	if req.AirBersih {
		score++
	} else {
		poinPerbaikan = append(poinPerbaikan, "Sediakan pasokan air bersih yang higienis dan layak pakai")
	}

	if req.ToiletBersih {
		score++
	} else {
		poinPerbaikan = append(poinPerbaikan, "Lakukan pembersihan toilet berkala dan pastikan suplai air lancar")
	}

	if req.TempatSampah {
		score++
	} else {
		poinPerbaikan = append(poinPerbaikan, "Sediakan tempat sampah tertutup berpedal di dekat workstation")
	}

	if req.VentilasiUdara {
		score++
	} else {
		poinPerbaikan = append(poinPerbaikan, "Perbaiki sirkulasi udara dengan membuka ventilasi atau membersihkan AC")
	}

	if req.BebasGenangan {
		score++
	} else {
		poinPerbaikan = append(poinPerbaikan, "Kuras dan bersihkan genangan air untuk mencegah vektor penyakit")
	}

	if req.KebersihanArea {
		score++
	} else {
		poinPerbaikan = append(poinPerbaikan, "Rapikan dan bersihkan meja kerja serta area lantai bersama")
	}

	total := 6
	persentase := (float64(score) / float64(total)) * 100.0

	var statusHasil string
	var saranTindak string

	if score == 6 {
		statusHasil = "Semua kondisi checklist terpenuhi"
		saranTindak = "Checklist terpenuhi: 6/6. Pertahankan kondisi dan lakukan pemantauan rutin."
	} else if score >= 4 {
		statusHasil = "Kondisi Sanitasi Cukup Memadai"
		saranTindak = fmt.Sprintf("Checklist terpenuhi: %d/6. Segera tindak lanjuti %d butir yang belum terpenuhi demi kesehatan bersama.", score, total-score)
	} else {
		statusHasil = "Kondisi Sanitasi Memerlukan Tindakan Cepat"
		saranTindak = fmt.Sprintf("Checklist terpenuhi: %d/6. Ditemukan %d titik rawan sanitasi. Laporkan segera ke pengelola fasilitas.", score, total-score)
	}

	// Compute tamper-proof SHA-256 Checksum
	rawChecksum := fmt.Sprintf("%s:%s:%d:%d:%d", userID, cleanLokasi, score, total, time.Now().Unix())
	checksum := utils.ComputeSHA256(rawChecksum)

	item := &models.ChecklistItem{
		ID:     "chk-" + uuid.New().String()[:8],
		UserID: userID,
		Lokasi: cleanLokasi,
		Kondisi: models.ChecklistKondisi{
			AirBersih:      req.AirBersih,
			ToiletBersih:   req.ToiletBersih,
			TempatSampah:   req.TempatSampah,
			VentilasiUdara: req.VentilasiUdara,
			BebasGenangan:  req.BebasGenangan,
			KebersihanArea: req.KebersihanArea,
		},
		SkorTerpenuhi:  score,
		TotalKondisi:   total,
		Persentase:     persentase,
		StatusHasil:    statusHasil,
		SaranTindak:    saranTindak,
		IsSimulasi:     true,
		ChecksumSHA256: checksum,
		CreatedAt:      time.Now(),
	}

	_ = s.ChecklistRepo.Save(item)

	return &dto.ChecklistResultResponse{
		ID:              item.ID,
		Lokasi:          item.Lokasi,
		SkorTerpenuhi:   score,
		TotalKondisi:    total,
		Persentase:      persentase,
		StatusHasil:     statusHasil,
		SaranTindak:     saranTindak,
		PoinPerbaikan:   poinPerbaikan,
		CatatanSimulasi: "Catatan: checklist ini untuk simulasi tugas. Hasilnya bukan sertifikasi atau pemeriksaan resmi.",
		ChecksumSHA256:  checksum,
	}, nil
}

func (s *SanitasiService) GetHistory(userID string) []*models.ChecklistItem {
	return s.ChecklistRepo.FindByUserID(userID)
}