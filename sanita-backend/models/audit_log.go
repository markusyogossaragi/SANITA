package models

import "time"

type AuditEventType string

const (
	EventLoginSuccess    AuditEventType = "AUTH_LOGIN_SUCCESS"
	EventLoginFailed     AuditEventType = "AUTH_LOGIN_FAILED"
	EventRegister        AuditEventType = "AUTH_REGISTER"
	EventChecklistSubmit AuditEventType = "CHECKLIST_SUBMIT"
	EventLaporanSubmit   AuditEventType = "LAPORAN_SUBMIT"
	EventIDORBlocked     AuditEventType = "SECURITY_IDOR_BLOCKED"
	EventRateLimited     AuditEventType = "SECURITY_RATE_LIMITED"
	EventMalwareBlocked  AuditEventType = "SECURITY_MALWARE_BLOCKED"
	EventCSRFBlocked     AuditEventType = "SECURITY_CSRF_BLOCKED"
)

type AuditLog struct {
	ID           string         `json:"id"`
	EventType    AuditEventType `json:"event_type"`
	UserID       string         `json:"user_id"`
	IPAddress    string         `json:"ip_address"`
	UserAgent    string         `json:"user_agent"`
	Resource     string         `json:"resource"`
	Action       string         `json:"action"`
	Status       string         `json:"status"` // SUCCESS, BLOCKED, FAILED
	Details      string         `json:"details"`
	PrevHash     string         `json:"prev_hash"`     // Blockchain-like linked hash chain
	CurrHash     string         `json:"curr_hash"`     // SHA-256 (prev_hash + details + timestamp)
	CreatedAt    time.Time      `json:"created_at"`
}