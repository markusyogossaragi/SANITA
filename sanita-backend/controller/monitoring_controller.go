package controller

import (
	"net/http"
	"sanita/service"
	"sanita/utils"

	"github.com/gin-gonic/gin"
)

type MonitoringController struct {
	Service *service.MonitoringService
}

func NewMonitoringController(s *service.MonitoringService) *MonitoringController {
	return &MonitoringController{Service: s}
}

func (ctrl *MonitoringController) GetStats(c *gin.Context) {
	stats := ctrl.Service.GetDashboardStats()
	utils.Success(c, http.StatusOK, "Statistik monitoring sanitasi berhasil dimuat", stats)
}

func (ctrl *MonitoringController) GetAuditLogs(c *gin.Context) {
	logs := ctrl.Service.GetAuditLogs(50)
	utils.Success(c, http.StatusOK, "Security Audit Trail berhasil dimuat", logs)
}