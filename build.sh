#!/usr/bin/env bash
set -e

echo "========================================================"
echo " SANITA (Sanitasi dan Lingkungan Kerja) - Linux Build"
echo " Author: Ribka Lusiana Harahap (NIM: 243301631022)"
echo "========================================================"

echo "[1/3] Verifying Go Backend Build..."
cd sanita-backend
go build -v -o /dev/null ./cmd/sanita-service/main.go
echo "Go backend compiled cleanly!"
cd ..

echo "[2/3] Running Mobile Architecture & Logic Tests..."
cd sanita_mobile
node test_runner.js
cd ..

echo "[3/3] Checking Docker Compose files..."
if command -v docker-compose &> /dev/null; then
    docker-compose -f deployment/docker-compose.prod.yml config -q
    echo "Docker Compose config verified valid."
fi

echo "========================================================"
echo " All builds & verifications succeeded!"
echo "========================================================"