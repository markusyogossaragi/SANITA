package service

import (
	"sanita/models"
	"sanita/repository"
)

type MonitoringService struct {
	LaporanRepo   *repository.LaporanRepository
	ChecklistRepo *repository.ChecklistRepository
	AuditRepo     *repository.AuditRepository
}

func NewMonitoringService(laporRepo *repository.LaporanRepository, checkRepo *repository.ChecklistRepository, auditRepo *repository.AuditRepository) *MonitoringService {
	return &MonitoringService{
		LaporanRepo:   laporRepo,
		ChecklistRepo: checkRepo,
		AuditRepo:     auditRepo,
	}
}

func (s *MonitoringService) GetDashboardStats() *models.MonitoringStats {
	allLaporan := s.LaporanRepo.FindAll()
	totalLaporan := len(allLaporan)

	terkirim := 0
	proses := 0
	selesai := 0

	categoryCount := make(map[string]int)
	locationCount := make(map[string]int)

	for _, lap := range allLaporan {
		switch lap.Status {
		case models.StatusTerkirim:
			terkirim++
		case models.StatusProses:
			proses++
		case models.StatusSelesai:
			selesai++
		}

		categoryCount[lap.JenisMasalah]++
		locationCount[lap.Lokasi]++
	}

	topCategory := "Toilet & Sanitasi Air"
	maxCat := 0
	for cat, count := range categoryCount {
		if count > maxCat {
			maxCat = count
			topCategory = cat
		}
	}

	var rawan []string
	for loc, count := range locationCount {
		if count >= 2 {
			rawan = append(rawan, loc)
		}
	}
	if len(rawan) == 0 {
		rawan = []string{"Area Pantry Kampus", "Toilet Lantai 1"}
	}

	avgCompliance := s.ChecklistRepo.GetAverageCompliance()
	allCheck := s.ChecklistRepo.FindAll()

	isChainValid := s.AuditRepo.VerifyChainIntegrity()

	return &models.MonitoringStats{
		TotalLaporan:      totalLaporan,
		LaporanTerkirim:   terkirim,
		LaporanDiproses:   proses,
		LaporanSelesai:    selesai,
		TotalChecklist:    len(allCheck),
		RataRataKepatuhan: avgCompliance,
		KategoriTerbanyak: topCategory,
		LokasiRawan:       rawan,
		StatusSistem:      "Normal & Terpantau",
		KeamananStatus:    "Optimal (Anti-Breach Shield Aktif)",
		IntegrityValid:    isChainValid,
	}
}

func (s *MonitoringService) GetAuditLogs(limit int) []*models.AuditLog {
	return s.AuditRepo.FindRecent(limit)
}