package service

import (
	"sanita/models"
	"sanita/repository"
)

type EdukasiService struct {
	EdukasiRepo *repository.EdukasiRepository
}

func NewEdukasiService(repo *repository.EdukasiRepository) *EdukasiService {
	return &EdukasiService{EdukasiRepo: repo}
}

func (s *EdukasiService) GetAll() []*models.Edukasi {
	return s.EdukasiRepo.FindAll()
}