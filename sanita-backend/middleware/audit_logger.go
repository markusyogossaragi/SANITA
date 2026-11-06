package middleware

import (
	"bytes"
	"io"
	"sanita/models"
	"sanita/repository"
	"strings"

	"github.com/gin-gonic/gin"
)

// SecurityAuditMiddleware logs security actions into the audit repository
func SecurityAuditMiddleware(auditRepo *repository.AuditRepository) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Read body without draining
		var bodyBytes []byte
		if c.Request.Body != nil {
			bodyBytes, _ = io.ReadAll(c.Request.Body)
			c.Request.Body = io.NopCloser(bytes.NewBuffer(bodyBytes))
		}

		c.Next()

		// Only log modifying requests or authentication requests
		path := c.Request.URL.Path
		method := c.Request.Method
		if method == "GET" || method == "OPTIONS" {
			return
		}

		userID, _ := c.Get("user_id")
		uid := "anonymous"
		if userID != nil {
			uid = userID.(string)
		}

		eventType := models.AuditEventType("SYSTEM_ACTION")
		if strings.Contains(path, "/login") {
			if c.Writer.Status() < 400 {
				eventType = models.EventLoginSuccess
			} else {
				eventType = models.EventLoginFailed
			}
		} else if strings.Contains(path, "/register") {
			eventType = models.EventRegister
		} else if strings.Contains(path, "/checklist") {
			eventType = models.EventChecklistSubmit
		} else if strings.Contains(path, "/laporan") {
			eventType = models.EventLaporanSubmit
		}

		status := "SUCCESS"
		if c.Writer.Status() >= 400 {
			status = "FAILED"
		}
		if c.Writer.Status() == 403 {
			status = "BLOCKED"
			eventType = models.EventIDORBlocked
		}
		if c.Writer.Status() == 429 {
			status = "BLOCKED"
			eventType = models.EventRateLimited
		}

		go func() {
			_ = auditRepo.Record(models.AuditLog{
				EventType: eventType,
				UserID:    uid,
				IPAddress: c.ClientIP(),
				UserAgent: c.Request.UserAgent(),
				Resource:  path,
				Action:    method,
				Status:    status,
				Details:   "Status code: " + string(rune(c.Writer.Status())),
			})
		}()
	}
}