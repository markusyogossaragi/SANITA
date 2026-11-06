package repository

import (
	"database/sql"
	"errors"
	"sanita/models"
	"sync"
	"time"
)

type LaporanRepository struct {
	db    *sql.DB
	mu    sync.RWMutex
	items []*models.Laporan
}

func NewLaporanRepository(db *sql.DB) *LaporanRepository {
	return &LaporanRepository{
		db:    db,
		items: make([]*models.Laporan, 0),
	}
}

func (r *LaporanRepository) Create(lap *models.Laporan) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	r.items = append([]*models.Laporan{lap}, r.items...)

	if r.db != nil {
		query := `INSERT INTO laporan (id, user_id, reporter_name, jenis_masalah, lokasi, keterangan, foto_url, foto_thumb, status, integrity_hmac, client_ip_hash, created_at, updated_at)
		          VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)`
		_, _ = r.db.Exec(query, lap.ID, lap.UserID, lap.ReporterName, lap.JenisMasalah, lap.Lokasi, lap.Keterangan, lap.FotoURL, lap.FotoThumb, lap.Status, lap.IntegrityHMAC, lap.ClientIPHash, lap.CreatedAt, lap.UpdatedAt)
	}
	return nil
}

func (r *LaporanRepository) FindAll() []*models.Laporan {
	r.mu.RLock()
	defer r.mu.RUnlock()

	results := make([]*models.Laporan, len(r.items))
	copy(results, r.items)
	return results
}

func (r *LaporanRepository) FindByUserID(userID string) []*models.Laporan {
	r.mu.RLock()
	defer r.mu.RUnlock()

	var results []*models.Laporan
	for _, it := range r.items {
		if it.UserID == userID {
			results = append(results, it)
		}
	}
	return results
}

func (r *LaporanRepository) FindByID(id string) (*models.Laporan, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	for _, it := range r.items {
		if it.ID == id {
			return it, nil
		}
	}
	return nil, errors.New("laporan tidak ditemukan")
}

func (r *LaporanRepository) UpdateStatus(id string, newStatus models.LaporanStatus, catatan string) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	for _, it := range r.items {
		if it.ID == id {
			it.Status = newStatus
			it.PetugasCatatan = catatan
			it.UpdatedAt = time.Now()
			return nil
		}
	}
	return errors.New("laporan tidak ditemukan")
}

func (r *LaporanRepository) Count() int {
	r.mu.RLock()
	defer r.mu.RUnlock()
	return len(r.items)
}