@echo off
echo ========================================================
echo  SANITA (Sanitasi dan Lingkungan Kerja) - Build Script
echo  Author: Ribka Lusiana Harahap (NIM: 243301631022)
echo ========================================================

echo.
echo [1/3] Verifying Go Backend Compilation (sanita-backend)...
cd sanita-backend
go build -v ./cmd/sanita-service/main.go
if %errorlevel% neq 0 (
    echo ERROR: Go backend build failed!
    cd ..
    exit /b %errorlevel%
)
if exist main.exe del main.exe
cd ..
echo Go backend verified successfully!

echo.
echo [2/3] Running Mobile Architecture and Logic Tests (sanita_mobile)...
cd sanita_mobile
node.exe test_runner.js
if %errorlevel% neq 0 (
    echo ERROR: Flutter test runner failed!
    cd ..
    exit /b %errorlevel%
)
cd ..

echo.
echo [3/3] Verification completed successfully!
echo.
echo Ready for deployment:
echo   - sanita-backend: Ready for Railway / Render / Docker
echo   - sanita_mobile : Ready for Flutter APK Build
echo ========================================================