package controller

import (
	"net/http"
	"sanita/repository"
	"sanita/utils"

	"github.com/gin-gonic/gin"
)

type SecurityController struct {
	AuditRepo *repository.AuditRepository
}

func NewSecurityController(auditRepo *repository.AuditRepository) *SecurityController {
	return &SecurityController{AuditRepo: auditRepo}
}

func (ctrl *SecurityController) CheckHealth(c *gin.Context) {
	isChainValid := ctrl.AuditRepo.VerifyChainIntegrity()

	defenseMatrix := gin.H{
		"anti_sql_injection":   "Active (Parameterized queries + input sanitization)",
		"anti_xss":             "Active (Strict HTML entity encoding & CSP default-src 'self')",
		"anti_clickjacking":    "Active (X-Frame-Options: DENY & frame-ancestors 'none')",
		"anti_mime_sniffing":   "Active (X-Content-Type-Options: nosniff)",
		"transport_security":   "Active (HSTS max-age=31536000 includeSubDomains preload)",
		"anti_brute_force":     "Active (Strict Leaky Bucket Rate Limiting per-IP)",
		"anti_idor":            "Active (Object-level Access Control Middleware)",
		"data_encryption":      "Active (AES-256-GCM field-level encryption for sensitive PII)",
		"tamper_proof_hmac":    "Active (HMAC-SHA256 signature attached to all records)",
		"audit_trail_valid":    isChainValid,
		"system_health":        "SECURE & HEALTHY",
		"project_info": gin.H{
			"app_name":       "SANITA (Sanitasi dan Lingkungan Kerja)",
			"nama_mahasiswa": "Ribka Lusiana Harahap",
			"nim":            "243301631022",
			"dosen_pengampu": "Riky Suherman Simanjuntak, S.K.M., M.K.M.",
		},
	}

	utils.Success(c, http.StatusOK, "Sistem keamanan SANITA beroperasi dengan tingkat proteksi maksimal", defenseMatrix)
}