package middleware

import (
	"net/http"
	"sanita/utils"
	"strings"

	"github.com/gin-gonic/gin"
)

// RequireAuth validates the JWT Bearer token
func RequireAuth() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			utils.Error(c, http.StatusUnauthorized, "Sesi autentikasi diperlukan (Authorization header missing)")
			c.Abort()
			return
		}

		parts := strings.SplitN(authHeader, " ", 2)
		if len(parts) != 2 || !strings.EqualFold(parts[0], "bearer") {
			utils.Error(c, http.StatusUnauthorized, "Format token harus: Bearer {token}")
			c.Abort()
			return
		}

		claims, err := utils.ValidateToken(parts[1])
		if err != nil {
			utils.Error(c, http.StatusUnauthorized, "Token tidak valid atau telah kedaluwarsa: "+err.Error())
			c.Abort()
			return
		}

		c.Set("user_id", claims.UserID)
		c.Set("username", claims.Username)
		c.Set("role", claims.Role)
		c.Next()
	}
}

// RequireRole checks if the authenticated user has at least one of the specified roles
func RequireRole(allowedRoles ...string) gin.HandlerFunc {
	return func(c *gin.Context) {
		roleVal, exists := c.Get("role")
		if !exists {
			utils.Error(c, http.StatusForbidden, "Akses ditolak: peran pengguna tidak ditemukan")
			c.Abort()
			return
		}

		userRole := roleVal.(string)
		permitted := false
		for _, r := range allowedRoles {
			if strings.EqualFold(r, userRole) {
				permitted = true
				break
			}
		}

		if !permitted {
			utils.Error(c, http.StatusForbidden, "Akses ditolak: Anda tidak memiliki wewenang untuk tindakan ini")
			c.Abort()
			return
		}

		c.Next()
	}
}