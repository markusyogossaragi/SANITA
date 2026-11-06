package middleware

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
)

// SecurityHeaders applies enterprise-grade HTTP security headers
func SecurityHeaders() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Anti-MIME Sniffing
		c.Header("X-Content-Type-Options", "nosniff")
		// Anti-Clickjacking
		c.Header("X-Frame-Options", "DENY")
		// XSS Filter
		c.Header("X-XSS-Protection", "1; mode=block")
		// Force HTTPS via HSTS (Strict-Transport-Security)
		c.Header("Strict-Transport-Security", "max-age=31536000; includeSubDomains; preload")
		// Referrer policy
		c.Header("Referrer-Policy", "strict-origin-when-cross-origin")
		// Restrict device permissions
		c.Header("Permissions-Policy", "camera=(self), microphone=(), geolocation=(), payment=()")
		// Content Security Policy
		c.Header("Content-Security-Policy", "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; img-src 'self' data: blob:; frame-ancestors 'none'; object-src 'none'; base-uri 'self';")
		// Strip identifying server headers to prevent reconnaissance
		c.Header("X-Powered-By", "")
		c.Header("Server", "")

		c.Next()
	}
}

// CORS controls cross-origin access with strict origin validation
func CORS() gin.HandlerFunc {
	allowedOrigins := []string{
		"http://localhost:3000",
		"http://localhost:8080",
		"http://localhost:8081",
		"http://127.0.0.1:3000",
		"http://127.0.0.1:8080",
		"http://127.0.0.1:8081",
		"https://sanita.health.app",
	}

	return func(c *gin.Context) {
		origin := c.GetHeader("Origin")

		if origin == "" {
			c.Next()
			return
		}

		allowed := false
		for _, o := range allowedOrigins {
			if strings.EqualFold(o, origin) {
				allowed = true
				break
			}
		}

		if allowed {
			c.Header("Access-Control-Allow-Origin", origin)
			c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
			c.Header("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Requested-With, X-CSRF-Token")
			c.Header("Access-Control-Allow-Credentials", "true")
			c.Header("Access-Control-Max-Age", "86400")
		}

		if c.Request.Method == http.MethodOptions {
			if allowed {
				c.AbortWithStatus(http.StatusNoContent)
			} else {
				c.AbortWithStatus(http.StatusForbidden)
			}
			return
		}

		c.Next()
	}
}

// RequestSizeLimit restricts max request body bytes to prevent DoS
func RequestSizeLimit(maxBytes int64) gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Request.Body = http.MaxBytesReader(c.Writer, c.Request.Body, maxBytes)
		c.Next()
	}
}