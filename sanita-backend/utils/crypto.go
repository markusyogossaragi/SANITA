package utils

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"errors"
	"fmt"
	"io"
)

var (
	EncryptionKey = []byte(getEnvOrDefault("SANITA_AES_KEY", "sanita-enterprise-aes-32byte-key!"))
	HMACSecret    = []byte(getEnvOrDefault("SANITA_HMAC_SECRET", "sanita-tamper-proof-hmac-key-2026"))
)

// EncryptAES256GCM encrypts plain string into Base64 encoded ciphertext with authenticated tag
func EncryptAES256GCM(plainText string) (string, error) {
	if plainText == "" {
		return "", nil
	}

	block, err := aes.NewCipher(EncryptionKey)
	if err != nil {
		return "", err
	}

	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", err
	}

	nonce := make([]byte, gcm.NonceSize())
	if _, err := io.ReadFull(rand.Reader, nonce); err != nil {
		return "", err
	}

	cipherText := gcm.Seal(nonce, nonce, []byte(plainText), nil)
	return base64.StdEncoding.EncodeToString(cipherText), nil
}

// DecryptAES256GCM decrypts Base64 ciphertext with nonce and verification
func DecryptAES256GCM(cipherTextB64 string) (string, error) {
	if cipherTextB64 == "" {
		return "", nil
	}

	data, err := base64.StdEncoding.DecodeString(cipherTextB64)
	if err != nil {
		return "", err
	}

	block, err := aes.NewCipher(EncryptionKey)
	if err != nil {
		return "", err
	}

	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", err
	}

	nonceSize := gcm.NonceSize()
	if len(data) < nonceSize {
		return "", errors.New("ciphertext too short")
	}

	nonce, actualCipher := data[:nonceSize], data[nonceSize:]
	plainBytes, err := gcm.Open(nil, nonce, actualCipher, nil)
	if err != nil {
		return "", fmt.Errorf("decryption/integrity check failed: %w", err)
	}

	return string(plainBytes), nil
}

// ComputeHMAC generates a tamper-proof SHA-256 HMAC for record verification
func ComputeHMAC(data string) string {
	h := hmac.New(sha256.New, HMACSecret)
	h.Write([]byte(data))
	return hex.EncodeToString(h.Sum(nil))
}

// VerifyHMAC validates that data matches the HMAC signature
func VerifyHMAC(data string, signature string) bool {
	expected := ComputeHMAC(data)
	return hmac.Equal([]byte(expected), []byte(signature))
}

// ComputeSHA256 generates a hex SHA-256 hash
func ComputeSHA256(data string) string {
	sum := sha256.Sum256([]byte(data))
	return hex.EncodeToString(sum[:])
}

// HashIP creates an irreversible pseudonymized hash of client IP for privacy preservation
func HashIP(ip string) string {
	h := sha256.Sum256([]byte(ip + "-sanita-salt-2026"))
	return hex.EncodeToString(h[:16])
}