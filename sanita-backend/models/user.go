package models

import "time"

type UserRole string

const (
	RoleUser      UserRole = "user_demo"
	RolePetugas   UserRole = "petugas_kesling"
	RoleAdmin     UserRole = "admin"
)

type User struct {
	ID        string    `json:"id"`
	Username  string    `json:"username"`
	FullName  string    `json:"full_name"`
	Role      UserRole  `json:"role"`
	Password  string    `json:"-"`
	EmailEnc  string    `json:"email_enc,omitempty"` // AES-256 encrypted at rest
	PhoneEnc  string    `json:"phone_enc,omitempty"` // AES-256 encrypted at rest
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}