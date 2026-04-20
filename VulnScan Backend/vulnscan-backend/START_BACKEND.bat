@echo off
REM VulnScan Backend Startup Script for Windows
REM This script adds Python to PATH and starts the backend

echo ========================================
echo  VulnScan Backend Startup
echo ========================================
echo.

REM Check if Python exists
if exist "C:\Users\vikas\AppData\Local\Programs\Python\Python313\" (
    echo [OK] Python 3.13 found
) else (
    echo [ERROR] Python 3.13 not found
    pause
    exit /b 1
)

REM Add Python to PATH
set PATH=C:\Users\vikas\AppData\Local\Programs\Python\Python313;C:\Users\vikas\AppData\Local\Programs\Python\Python313\Scripts;%PATH%

echo [OK] Python added to PATH

REM Verify Python works
python --version
if errorlevel 1 (
    echo [ERROR] Python not working
    pause
    exit /b 1
)

REM Change to backend directory
cd /d "C:\final year\VulnScan Backend\vulnscan-backend"
if errorlevel 1 (
    echo [ERROR] Cannot access backend directory
    pause
    exit /b 1
)

echo [OK] Backend directory found

REM Check if requirements are installed
echo.
echo [INFO] Checking dependencies...
pip list | find "fastapi" >nul
if errorlevel 1 (
    echo [INFO] Installing dependencies...
    pip install -r requirements.txt
    if errorlevel 1 (
        echo [ERROR] Failed to install dependencies
        pause
        exit /b 1
    )
)

REM Start the backend
echo.
echo ========================================
echo  Starting Backend Server...
echo ========================================
echo  URL: http://localhost:8000
echo  API Docs: http://localhost:8000/docs
echo ========================================
echo.

python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000

if errorlevel 1 (
    echo [ERROR] Backend failed to start
    pause
    exit /b 1
)

pause
