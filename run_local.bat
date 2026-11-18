@echo off
title BillBooks Full Stack Launcher
echo =======================================================
echo   Launching BillBooks Full Stack Services
echo =======================================================
echo.

start "BillBooks Backend API (Port 8000)" cmd /k "cd /d %~dp0 && .venv\Scripts\python.exe -m uvicorn main:app --host 127.0.0.1 --port 8000 --reload"
start "BillBooks Flutter Web (Port 8080)" cmd /k "cd /d %~dp0 && .venv\Scripts\python.exe -m http.server 8080 --directory mobile_app\build\web"
start "BillBooks Admin Dashboard (Port 3000)" cmd /k "cd /d %~dp0 && .venv\Scripts\python.exe -m http.server 3000 --directory frontend\dist"

echo All services launched in separate windows:
echo - Backend API:        http://127.0.0.1:8000
echo - Swagger Docs:       http://127.0.0.1:8000/docs
echo - BillBooks App:      http://127.0.0.1:8080
echo - Admin Dashboard:    http://127.0.0.1:3000
echo.
echo Leave those command windows open while you are testing.
echo Press any key to exit this launcher window.
pause >nul
