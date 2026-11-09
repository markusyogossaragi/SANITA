package repository

import (
	"database/sql"
	"errors"
	"sanita/models"
	"sync"
	"time"
)

type UserRepository struct {
	db    *sql.DB
	mu    sync.RWMutex
	cache map[string]*models.User
}

func NewUserRepository(db *sql.DB) *UserRepository {
	repo := &UserRepository{
		db:    db,
		cache: make(map[string]*models.User),
	}
	repo.seedInitialUsers()
	return repo
}

func (r *UserRepository) seedInitialUsers() {
	adminUser := &models.User{
		ID:        "usr-admin-ribka-243301631022",
		Username:  "ribka",
		FullName:  "Ribka Lusiana Harahap",
		Role:      models.RoleAdmin,
		Password:  "$2a$12$eAnm6N6cM6X9dF0YVfWfveUqgQx/kZk7B1Bw6gZ5iI6n2zE/fAOWS", // "password123" / "sanita2026"
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}
	r.cache[adminUser.Username] = adminUser
}

func (r *UserRepository) Create(user *models.User) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	if _, exists := r.cache[user.Username]; exists {
		return errors.New("username sudah digunakan")
	}

	r.cache[user.Username] = user

	if r.db != nil {
		query := `INSERT INTO users (id, username, full_name, role, password, email_enc, phone_enc, created_at, updated_at) 
		          VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`
		_, _ = r.db.Exec(query, user.ID, user.Username, user.FullName, user.Role, user.Password, user.EmailEnc, user.PhoneEnc, user.CreatedAt, user.UpdatedAt)
	}
	return nil
}

func (r *UserRepository) FindByUsername(username string) (*models.User, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	user, ok := r.cache[username]
	if !ok {
		return nil, nil
	}
	return user, nil
}

func (r *UserRepository) FindByID(id string) (*models.User, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	for _, u := range r.cache {
		if u.ID == id {
			return u, nil
		}
	}
	return nil, nil
}