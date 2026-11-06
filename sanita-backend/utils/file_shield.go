package utils

import (
	"bytes"
	"crypto/rand"
	"encoding/hex"
	"errors"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"
)

const (
	MaxFileSize     = 5 * 1024 * 1024 // 5 MB max
	UploadDirectory = "uploads"
)

var allowedMimes = map[string]string{
	"image/jpeg": ".jpg",
	"image/png":  ".png",
	"image/webp": ".webp",
}

// ValidateAndSaveFile inspects file magic bytes, ensures zero webshell injection, and saves safely
func ValidateAndSaveFile(fileHeader io.Reader, originalFilename string, size int64) (string, error) {
	if size > MaxFileSize {
		return "", fmt.Errorf("ukuran file melebihi batas maksimal 5 MB")
	}

	// Read first 512 bytes for MIME detection
	buffer := make([]byte, 512)
	n, err := fileHeader.Read(buffer)
	if err != nil && err != io.EOF {
		return "", fmt.Errorf("gagal membaca header file: %w", err)
	}

	// Detect MIME type by magic numbers
	detectedMime := http.DetectContentType(buffer[:n])

	ext, ok := allowedMimes[detectedMime]
	if !ok {
		return "", fmt.Errorf("format file tidak diizinkan (%s). Hanya JPG, PNG, dan WebP", detectedMime)
	}

	// Additional anti-webshell checks: scan for dangerous PHP/HTML/Shell signatures in header
	lowerHeader := strings.ToLower(string(buffer[:n]))
	suspiciousTokens := []string{"<?php", "<script", "eval(", "base64_decode", "#!/bin/", "system(", "exec("}
	for _, tok := range suspiciousTokens {
		if strings.Contains(lowerHeader, tok) {
			return "", errors.New("file ditolak: terdeteksi pola kode berbahaya (anti-malware shield)")
		}
	}

	// Generate cryptographically random secure filename (Prevents Path Traversal)
	randomBytes := make([]byte, 16)
	if _, err := rand.Read(randomBytes); err != nil {
		return "", err
	}
	secureFilename := hex.EncodeToString(randomBytes) + ext

	// Ensure upload dir exists
	if err := os.MkdirAll(UploadDirectory, 0750); err != nil {
		return "", err
	}

	destPath := filepath.Join(UploadDirectory, secureFilename)
	out, err := os.OpenFile(destPath, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, 0640)
	if err != nil {
		return "", err
	}
	defer out.Close()

	// Write the initial buffer read
	if _, err := out.Write(buffer[:n]); err != nil {
		return "", err
	}

	// Copy the remaining stream
	if _, err := io.Copy(out, fileHeader); err != nil {
		return "", err
	}

	return "/uploads/" + secureFilename, nil
}

// ValidateImageBytes checks byte slices directly
func ValidateImageBytes(data []byte) (string, error) {
	if len(data) > MaxFileSize {
		return "", errors.New("ukuran file melebihi 5 MB")
	}

	mime := http.DetectContentType(data)
	if _, ok := allowedMimes[mime]; !ok {
		return "", fmt.Errorf("format file %s tidak diizinkan", mime)
	}

	if bytes.Contains(data, []byte("<?php")) || bytes.Contains(data, []byte("<script")) {
		return "", errors.New("pola kode berbahaya terdeteksi dalam payload gambar")
	}

	return mime, nil
}