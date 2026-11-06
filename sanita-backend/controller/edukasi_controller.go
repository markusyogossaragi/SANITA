package controller

import (
	"net/http"
	"sanita/service"
	"sanita/utils"

	"github.com/gin-gonic/gin"
)

type EdukasiController struct {
	Service *service.EdukasiService
}

func NewEdukasiController(s *service.EdukasiService) *EdukasiController {
	return &EdukasiController{Service: s}
}

func (ctrl *EdukasiController) GetAll(c *gin.Context) {
	materi := ctrl.Service.GetAll()
	utils.Success(c, http.StatusOK, "Materi edukasi kesehatan lingkungan kerja berhasil dimuat", materi)
}