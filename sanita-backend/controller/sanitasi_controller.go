package controller

import (
	"net/http"
	"sanita/dto"
	"sanita/service"
	"sanita/utils"

	"github.com/gin-gonic/gin"
)

type SanitasiController struct {
	Service *service.SanitasiService
}

func NewSanitasiController(s *service.SanitasiService) *SanitasiController {
	return &SanitasiController{Service: s}
}

func (ctrl *SanitasiController) SubmitChecklist(c *gin.Context) {
	var req dto.ChecklistSubmitRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ValidationError(c, "Form checklist tidak valid", err.Error())
		return
	}

	userID := "anonymous"
	if uid, exists := c.Get("user_id"); exists {
		userID = uid.(string)
	}

	result, err := ctrl.Service.EvaluateChecklist(userID, req)
	if err != nil {
		utils.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	utils.Success(c, http.StatusOK, "Hasil pemeriksaan sanitasi berhasil dievaluasi", result)
}

func (ctrl *SanitasiController) GetHistory(c *gin.Context) {
	userID := "anonymous"
	if uid, exists := c.Get("user_id"); exists {
		userID = uid.(string)
	}

	history := ctrl.Service.GetHistory(userID)
	utils.Success(c, http.StatusOK, "Riwayat pemeriksaan berhasil dimuat", history)
}