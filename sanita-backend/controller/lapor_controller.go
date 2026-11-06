package controller

import (
	"net/http"
	"sanita/dto"
	"sanita/service"
	"sanita/utils"

	"github.com/gin-gonic/gin"
)

type LaporController struct {
	Service *service.LaporService
}

func NewLaporController(s *service.LaporService) *LaporController {
	return &LaporController{Service: s}
}

func (ctrl *LaporController) SubmitReport(c *gin.Context) {
	var req dto.LaporSubmitRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ValidationError(c, "Form pelaporan tidak valid", err.Error())
		return
	}

	userID := "anonymous"
	if uid, exists := c.Get("user_id"); exists {
		userID = uid.(string)
	}

	clientIP := c.ClientIP()
	report, err := ctrl.Service.SubmitReport(userID, clientIP, req)
	if err != nil {
		utils.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	utils.Success(c, http.StatusCreated, "Laporan berhasil dikirim dan tersimpan aman di sistem", report)
}

func (ctrl *LaporController) GetMyReports(c *gin.Context) {
	userID := "anonymous"
	if uid, exists := c.Get("user_id"); exists {
		userID = uid.(string)
	}

	reports := ctrl.Service.GetUserReports(userID)
	utils.Success(c, http.StatusOK, "Daftar riwayat laporan berhasil dimuat", reports)
}

func (ctrl *LaporController) GetAllReports(c *gin.Context) {
	reports := ctrl.Service.GetAllReports()
	utils.Success(c, http.StatusOK, "Semua laporan lingkungan berhasil dimuat", reports)
}

func (ctrl *LaporController) GetReportDetail(c *gin.Context) {
	id := c.Param("id")
	report, err := ctrl.Service.GetReportByID(id)
	if err != nil {
		utils.Error(c, http.StatusNotFound, err.Error())
		return
	}

	isValid, _ := ctrl.Service.VerifyReportIntegrity(id)
	resp := gin.H{
		"report":           report,
		"integrity_valid": isValid,
	}

	utils.Success(c, http.StatusOK, "Detail laporan berhasil dimuat", resp)
}

func (ctrl *LaporController) UpdateStatus(c *gin.Context) {
	id := c.Param("id")
	var req dto.LaporStatusUpdateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ValidationError(c, "Data status tidak valid", err.Error())
		return
	}

	if err := ctrl.Service.UpdateStatus(id, req.Status, req.PetugasCatatan); err != nil {
		utils.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	utils.Success(c, http.StatusOK, "Status laporan berhasil diperbarui", nil)
}