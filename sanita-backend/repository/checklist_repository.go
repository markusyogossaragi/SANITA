package repository

import (
	"database/sql"
	"sanita/models"
	"sync"
)

type ChecklistRepository struct {
	db    *sql.DB
	mu    sync.RWMutex
	items []*models.ChecklistItem
}

func NewChecklistRepository(db *sql.DB) *ChecklistRepository {
	return &ChecklistRepository{
		db:    db,
		items: make([]*models.ChecklistItem, 0),
	}
}

func (r *ChecklistRepository) Save(item *models.ChecklistItem) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	r.items = append([]*models.ChecklistItem{item}, r.items...)

	if r.db != nil {
		query := `INSERT INTO checklists (id, user_id, lokasi, air_bersih, toilet_bersih, tempat_sampah, ventilasi_udara, bebas_genangan, kebersihan_area, skor_terpenuhi, total_kondisi, persentase, status_hasil, saran_tindak, checksum_sha256, created_at)
		          VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16)`
		_, _ = r.db.Exec(query, item.ID, item.UserID, item.Lokasi, item.Kondisi.AirBersih, item.Kondisi.ToiletBersih, item.Kondisi.TempatSampah, item.Kondisi.VentilasiUdara, item.Kondisi.BebasGenangan, item.Kondisi.KebersihanArea, item.SkorTerpenuhi, item.TotalKondisi, item.Persentase, item.StatusHasil, item.SaranTindak, item.ChecksumSHA256, item.CreatedAt)
	}
	return nil
}

func (r *ChecklistRepository) FindAll() []*models.ChecklistItem {
	r.mu.RLock()
	defer r.mu.RUnlock()

	results := make([]*models.ChecklistItem, len(r.items))
	copy(results, r.items)
	return results
}

func (r *ChecklistRepository) FindByUserID(userID string) []*models.ChecklistItem {
	r.mu.RLock()
	defer r.mu.RUnlock()

	var results []*models.ChecklistItem
	for _, it := range r.items {
		if it.UserID == userID {
			results = append(results, it)
		}
	}
	return results
}

func (r *ChecklistRepository) GetAverageCompliance() float64 {
	r.mu.RLock()
	defer r.mu.RUnlock()

	if len(r.items) == 0 {
		return 100.0 // Default baseline 100%
	}

	total := 0.0
	for _, it := range r.items {
		total += it.Persentase
	}
	return total / float64(len(r.items))
}