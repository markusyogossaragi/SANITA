package service

import (
	"errors"
	"fmt"
	"sanita/dto"
	"sanita/models"
	"sanita/repository"
	"sanita/utils"
	"strings"
	"time"

	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
)

type AuthService struct {
	UserRepo *repository.UserRepository
}

func NewAuthService(repo *repository.UserRepository) *AuthService {
	return &AuthService{UserRepo: repo}
}

func (s *AuthService) Login(req dto.LoginRequest) (*dto.AuthResponse, error) {
	username := strings.TrimSpace(req.Username)
	if username == "" {
		return nil, errors.New("username tidak boleh kosong")
	}

	user, err := s.UserRepo.FindByUsername(username)
	if err != nil {
		return nil, fmt.Errorf("kesalahan sistem autentikasi: %w", err)
	}
	if user == nil {
		return nil, errors.New("username atau password salah")
	}

	err = bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(req.Password))
	if err != nil {
		return nil, errors.New("username atau password salah")
	}

	token, err := utils.GenerateToken(user.ID, user.Username, string(user.Role))
	if err != nil {
		return nil, fmt.Errorf("gagal membuat token sesi: %w", err)
	}

	return &dto.AuthResponse{
		Token:    token,
		UserID:   user.ID,
		Username: user.Username,
		FullName: user.FullName,
		Role:     string(user.Role),
	}, nil
}

func (s *AuthService) Register(req dto.RegisterRequest) (*dto.AuthResponse, error) {
	cleanUsername := utils.SanitizeString(req.Username)
	cleanFullName := utils.SanitizeString(req.FullName)

	if !utils.ValidateUsername(cleanUsername) {
		return nil, errors.New("username hanya boleh berisi huruf, angka, garis bawah, dan titik (3-30 karakter)")
	}

	existing, _ := s.UserRepo.FindByUsername(cleanUsername)
	if existing != nil {
		return nil, errors.New("username sudah terdaftar")
	}

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		return nil, errors.New("gagal mengamankan password")
	}

	// Field-Level AES-256 Encryption for sensitive PII
	emailEnc, _ := utils.EncryptAES256GCM(req.Email)
	phoneEnc, _ := utils.EncryptAES256GCM(req.Phone)

	role := models.RoleUser
	if req.Role != "" {
		role = models.UserRole(req.Role)
	}

	newUser := &models.User{
		ID:        "usr-" + uuid.New().String()[:8],
		Username:  cleanUsername,
		FullName:  cleanFullName,
		Role:      role,
		Password:  string(hashedPassword),
		EmailEnc:  emailEnc,
		PhoneEnc:  phoneEnc,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	if err := s.UserRepo.Create(newUser); err != nil {
		return nil, err
	}

	token, _ := utils.GenerateToken(newUser.ID, newUser.Username, string(newUser.Role))

	return &dto.AuthResponse{
		Token:    token,
		UserID:   newUser.ID,
		Username: newUser.Username,
		FullName: newUser.FullName,
		Role:     string(newUser.Role),
	}, nil
}

func (s *AuthService) GetProfile(userID string) (*models.User, error) {
	user, err := s.UserRepo.FindByID(userID)
	if err != nil || user == nil {
		return nil, errors.New("pengguna tidak ditemukan")
	}
	return user, nil
}