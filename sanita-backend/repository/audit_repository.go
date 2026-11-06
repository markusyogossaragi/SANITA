package repository

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"sanita/models"
	"sync"
	"time"
)

type AuditRepository struct {
	mu       sync.RWMutex
	logs     []*models.AuditLog
	lastHash string
}

func NewAuditRepository() *AuditRepository {
	return &AuditRepository{
		logs:     make([]*models.AuditLog, 0),
		lastHash: "0000000000000000000000000000000000000000000000000000000000000000",
	}
}

func (r *AuditRepository) Record(entry models.AuditLog) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	entry.CreatedAt = time.Now()
	entry.PrevHash = r.lastHash

	// Cryptographic chaining: SHA256(prevHash + eventType + userID + action + timestamp)
	raw := fmt.Sprintf("%s:%s:%s:%s:%s:%s", entry.PrevHash, entry.EventType, entry.UserID, entry.Action, entry.Status, entry.CreatedAt.Format(time.RFC3339Nano))
	h := sha256.Sum256([]byte(raw))
	entry.CurrHash = hex.EncodeToString(h[:])

	r.lastHash = entry.CurrHash
	r.logs = append(r.logs, &entry)
	return nil
}

func (r *AuditRepository) FindRecent(limit int) []*models.AuditLog {
	r.mu.RLock()
	defer r.mu.RUnlock()

	n := len(r.logs)
	if n == 0 {
		return []*models.AuditLog{}
	}

	start := n - limit
	if start < 0 {
		start = 0
	}

	results := make([]*models.AuditLog, 0, n-start)
	for i := n - 1; i >= start; i-- {
		results = append(results, r.logs[i])
	}
	return results
}

// VerifyChainIntegrity validates that no past logs have been modified
func (r *AuditRepository) VerifyChainIntegrity() bool {
	r.mu.RLock()
	defer r.mu.RUnlock()

	expectedPrev := "0000000000000000000000000000000000000000000000000000000000000000"
	for _, log := range r.logs {
		if log.PrevHash != expectedPrev {
			return false
		}
		raw := fmt.Sprintf("%s:%s:%s:%s:%s:%s", log.PrevHash, log.EventType, log.UserID, log.Action, log.Status, log.CreatedAt.Format(time.RFC3339Nano))
		h := sha256.Sum256([]byte(raw))
		calcHash := hex.EncodeToString(h[:])
		if calcHash != log.CurrHash {
			return false
		}
		expectedPrev = log.CurrHash
	}
	return true
}