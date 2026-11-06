package main

import (
	"log"
	"net/http"
	"time"
	_ "time/tzdata"

	"sanita/config"
	"sanita/controller"
	"sanita/repository"
	"sanita/routes"
	"sanita/service"

	"github.com/gin-gonic/gin"
)

func main() {
	loc, err := time.LoadLocation("Asia/Jakarta")
	if err == nil {
		time.Local = loc
	}

	config.LoadEnv()
	db := config.ConnectDB()
	if db != nil {
		defer db.Close()
	}

	log.Println("==================================================")
	log.Println("  SANITA (Sanitasi dan Lingkungan Kerja) Service  ")
	log.Println("  Maximum Anti-Breach & Zero-Trust Defense Core   ")
	log.Println("  Author: Ribka Lusiana Harahap (243301631022)   ")
	log.Println("==================================================")

	// Repositories
	userRepo := repository.NewUserRepository(db)
	checkRepo := repository.NewChecklistRepository(db)
	laporRepo := repository.NewLaporanRepository(db)
	edukasiRepo := repository.NewEdukasiRepository()
	auditRepo := repository.NewAuditRepository()

	// Services
	authService := service.NewAuthService(userRepo)
	sanitasiService := service.NewSanitasiService(checkRepo)
	laporService := service.NewLaporService(laporRepo, userRepo)
	edukasiService := service.NewEdukasiService(edukasiRepo)
	monitoringService := service.NewMonitoringService(laporRepo, checkRepo, auditRepo)

	// Controllers
	authCtrl := controller.NewAuthController(authService)
	sanitasiCtrl := controller.NewSanitasiController(sanitasiService)
	laporCtrl := controller.NewLaporController(laporService)
	edukasiCtrl := controller.NewEdukasiController(edukasiService)
	monitoringCtrl := controller.NewMonitoringController(monitoringService)
	securityCtrl := controller.NewSecurityController(auditRepo)

	// Gin Engine with hardened configurations
	gin.SetMode(gin.ReleaseMode)
	r := gin.New()
	r.Use(gin.Recovery())
	r.Use(gin.Logger())
	_ = r.SetTrustedProxies(nil)

	r.GET("/", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"app":       "SANITA - Sanitasi dan Lingkungan Kerja",
			"author":    "Ribka Lusiana Harahap",
			"nim":       "243301631022",
			"dosen":     "Riky Suherman Simanjuntak, S.K.M., M.K.M.",
			"version":   "1.0.0-enterprise-security",
			"status":    "active",
			"anti_breach": "MAXIMUM_PROTECTION_ENABLED",
		})
	})

	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status": "healthy",
			"time":   time.Now().Format(time.RFC3339),
		})
	})

	routes.SetupSanitaRoutes(r, authCtrl, sanitasiCtrl, laporCtrl, edukasiCtrl, monitoringCtrl, securityCtrl, laporRepo, auditRepo)

	port := config.GetEnv("PORT", "8080")
	srv := &http.Server{
		Addr:         ":" + port,
		Handler:      r,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 30 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	log.Printf("[SANITA-SERVER] Server running securely on port :%s\n", port)
	if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		log.Fatalf("Server startup failed: %v", err)
	}
}