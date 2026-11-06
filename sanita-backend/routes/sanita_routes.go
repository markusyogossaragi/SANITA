package routes

import (
	"sanita/controller"
	"sanita/middleware"
	"sanita/repository"

	"github.com/gin-gonic/gin"
)

func SetupSanitaRoutes(
	r *gin.Engine,
	authCtrl *controller.AuthController,
	sanitasiCtrl *controller.SanitasiController,
	laporCtrl *controller.LaporController,
	edukasiCtrl *controller.EdukasiController,
	monitoringCtrl *controller.MonitoringController,
	securityCtrl *controller.SecurityController,
	laporRepo *repository.LaporanRepository,
	auditRepo *repository.AuditRepository,
) {
	// Global Security Defenses
	r.Use(middleware.SecurityHeaders())
	r.Use(middleware.CORS())
	r.Use(middleware.RequestSizeLimit(8 * 1024 * 1024)) // 8 MB max
	r.Use(middleware.RateLimit())
	r.Use(middleware.SecurityAuditMiddleware(auditRepo))

	// Static route for uploaded proofs
	r.Static("/uploads", "./uploads")

	api := r.Group("/api/v1")

	// Public / General Endpoints
	api.GET("/security/status", securityCtrl.CheckHealth)
	api.GET("/edukasi", edukasiCtrl.GetAll)
	api.GET("/monitoring/stats", monitoringCtrl.GetStats)

	// Auth routes (Protected with Anti-Brute Force Strict Rate Limiter)
	auth := api.Group("/auth")
	{
		auth.POST("/login", middleware.StrictRateLimit(), authCtrl.Login)
		auth.POST("/register", middleware.StrictRateLimit(), authCtrl.Register)
		auth.GET("/profile", middleware.RequireAuth(), authCtrl.GetProfile)
	}

	// Cek Sanitasi routes
	sanitasi := api.Group("/sanitasi")
	{
		sanitasi.POST("/checklist", sanitasiCtrl.SubmitChecklist)
		sanitasi.GET("/history", sanitasiCtrl.GetHistory)
	}

	// Lapor Lingkungan routes (Protected with Anti-Spam Strict Rate Limiter & Anti-IDOR)
	lapor := api.Group("/laporan")
	{
		lapor.POST("", middleware.StrictRateLimit(), laporCtrl.SubmitReport)
		lapor.GET("", laporCtrl.GetMyReports)
		lapor.GET("/all", middleware.RequireAuth(), middleware.RequireRole("admin", "petugas_kesling"), laporCtrl.GetAllReports)
		lapor.GET("/:id", middleware.RequireAuth(), middleware.AntiIDORGuard(laporRepo), laporCtrl.GetReportDetail)
		lapor.PUT("/:id/status", middleware.RequireAuth(), middleware.RequireRole("admin", "petugas_kesling"), laporCtrl.UpdateStatus)
	}

	// Monitoring & Audit routes
	admin := api.Group("/admin")
	admin.Use(middleware.RequireAuth(), middleware.RequireRole("admin"))
	{
		admin.GET("/audit-logs", monitoringCtrl.GetAuditLogs)
	}
}