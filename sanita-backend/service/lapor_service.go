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

type LaporService struct {
	LaporRepo *repository.LaporanRepository
	UserRepo  *repository.UserRepository
}

func NewLaporService(laporRepo *repository.LaporanRepository, userRepo *repository.UserRepository) *LaporService {
	return &LaporService{
		LaporRepo: laporRepo,
		UserRepo:  userRepo,
	}
}

func (s *LaporService) SubmitReport(userID string, clientIP string, req dto.LaporSubmitRequest) (*models.Laporan, error) {
	cleanJenis := utils.SanitizeString(req.JenisMasalah)
	cleanLokasi := utils.SanitizeString(req.Lokasi)
	cleanKeterangan := utils.SanitizeString(req.Keterangan)

	if cleanJenis == "" || cleanJenis == "Pilih masalah" {
		return nil, errors.New("silakan pilih jenis permasalahan")
	}
	if len(cleanLokasi) < 2 {
		return nil, errors.New("lokasi kejadian minimal 2 karakter")
	}
	if len(cleanKeterangan) < 5 {
		return nil, errors.New("keterangan minimal 5 karakter")
	}

	// Validate photo if provided
	photoURL := ""
	if req.FotoBase64 != "" {
		if strings.HasPrefix(req.FotoBase64, "data:image/") {
			// Limit photo size in base64 (approx 7MB raw base64 == 5MB binary)
			if len(req.FotoBase64) > 7*1024*1024 {
				return nil, errors.New("ukuran foto maksimal 5 MB")
			}
			photoURL = req.FotoBase64
		} else {
			return nil, errors.New("format foto tidak valid (harus data image)")
		}
	}

	reporterName := "Sahabat SANITA"
	if user, _ := s.UserRepo.FindByID(userID); user != nil {
		reporterName = user.FullName
	}

	reportID := "lap-" + uuid.New().String()[:8]
	now := time.Now()

	// Compute Cryptographic HMAC Anti-Tamper Signature
	rawPayload := fmt.Sprintf("%s|%s|%s|%s|%s|%d", reportID, userID, cleanJenis, cleanLokasi, cleanKeterangan, now.Unix())
	hmacSignature := utils.ComputeHMAC(rawPayload)

	lap := &models.Laporan{
		ID:            reportID,
		UserID:        userID,
		ReporterName:  reporterName,
		JenisMasalah:  cleanJenis,
		Lokasi:        cleanLokasi,
		Keterangan:    cleanKeterangan,
		FotoURL:       photoURL,
		Status:        models.StatusTerkirim,
		IntegrityHMAC: hmacSignature,
		ClientIPHash:  utils.HashIP(clientIP),
		CreatedAt:     now,
		UpdatedAt:     now,
	}

	if err := s.LaporRepo.Create(lap); err != nil {
		return nil, fmt.Errorf("gagal menyimpan laporan: %w", err)
	}

	return lap, nil
}

func (s *LaporService) GetUserReports(userID string) []*models.Laporan {
	return s.LaporRepo.FindByUserID(userID)
}

func (s *LaporService) GetAllReports() []*models.Laporan {
	return s.LaporRepo.FindAll()
}

func (s *LaporService) GetReportByID(id string) (*models.Laporan, error) {
	return s.LaporRepo.FindByID(id)
}

func (s *LaporService) VerifyReportIntegrity(id string) (bool, error) {
	lap, err := s.LaporRepo.FindByID(id)
	if err != nil {
		return false, err
	}

	rawPayload := fmt.Sprintf("%s|%s|%s|%s|%s|%d", lap.ID, lap.UserID, lap.JenisMasalah, lap.Lokasi, lap.Keterangan, lap.CreatedAt.Unix())
	return utils.VerifyHMAC(rawPayload, lap.IntegrityHMAC), nil
}

func (s *LaporService) UpdateStatus(id string, status string, catatan string) error {
	cleanCatatan := utils.SanitizeString(catatan)
	return s.LaporRepo.UpdateStatus(id, models.LaporanStatus(status), cleanCatatan)
}