package controller

import (
	"net/http"
	"sanita/dto"
	"sanita/service"
	"sanita/utils"

	"github.com/gin-gonic/gin"
)

type AuthController struct {
	Service *service.AuthService
}

func NewAuthController(s *service.AuthService) *AuthController {
	return &AuthController{Service: s}
}

func (ctrl *AuthController) Login(c *gin.Context) {
	var req dto.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ValidationError(c, "Data login tidak valid", err.Error())
		return
	}

	result, err := ctrl.Service.Login(req)
	if err != nil {
		utils.Error(c, http.StatusUnauthorized, err.Error())
		return
	}

	utils.Success(c, http.StatusOK, "Login berhasil. Selamat datang di SANITA!", result)
}

func (ctrl *AuthController) Register(c *gin.Context) {
	var req dto.RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ValidationError(c, "Data pendaftaran tidak valid", err.Error())
		return
	}

	result, err := ctrl.Service.Register(req)
	if err != nil {
		utils.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	utils.Success(c, http.StatusCreated, "Registrasi akun berhasil", result)
}

func (ctrl *AuthController) GetProfile(c *gin.Context) {
	userID, _ := c.Get("user_id")
	user, err := ctrl.Service.GetProfile(userID.(string))
	if err != nil {
		utils.Error(c, http.StatusNotFound, err.Error())
		return
	}

	// Decrypt sensitive contact data on-the-fly for the authorized owner
	email, _ := utils.DecryptAES256GCM(user.EmailEnc)
	phone, _ := utils.DecryptAES256GCM(user.PhoneEnc)

	resp := gin.H{
		"id":         user.ID,
		"username":   user.Username,
		"full_name":  user.FullName,
		"role":       user.Role,
		"email":      email,
		"phone":      phone,
		"created_at": user.CreatedAt,
	}

	utils.Success(c, http.StatusOK, "Profil pengguna berhasil dimuat", resp)
}