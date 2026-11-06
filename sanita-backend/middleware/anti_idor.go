package middleware

import (
	"net/http"
	"sanita/models"
	"sanita/repository"
	"sanita/utils"

	"github.com/gin-gonic/gin"
)

// AntiIDORGuard ensures an authenticated user only modifies/reads their own reports
func AntiIDORGuard(laporanRepo *repository.LaporanRepository) gin.HandlerFunc {
	return func(c *gin.Context) {
		tokenUserID, exists := c.Get("user_id")
		if !exists {
			utils.Error(c, http.StatusUnauthorized, "Sesi tidak valid")
			c.Abort()
			return
		}

		userRole, _ := c.Get("role")
		// Officers & Admins have clearance for monitoring/processing
		if userRole == string(models.RoleAdmin) || userRole == string(models.RolePetugas) {
			c.Next()
			return
		}

		reportID := c.Param("id")
		if reportID == "" {
			c.Next()
			return
		}

		report, err := laporanRepo.FindByID(reportID)
		if err != nil || report == nil {
			utils.Error(c, http.StatusNotFound, "Laporan tidak ditemukan")
			c.Abort()
			return
		}

		if report.UserID != tokenUserID.(string) {
			utils.Error(c, http.StatusForbidden, "Akses ditolak: Perlindungan IDOR Aktif. Anda tidak berhak mengakses laporan pengguna lain.")
			c.Abort()
			return
		}

		c.Next()
	}
}