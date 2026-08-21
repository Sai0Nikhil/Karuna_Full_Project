@echo off
title Tiny Karuṇā Automatic Launcher
cls
echo ===================================================
echo   🐾 Starting Tiny Karuṇā ML Showcase... 🐾
echo ===================================================
echo.

echo [1/2] Starting FastAPI Backend on http://localhost:8002...
start "Tiny Karuna Backend" cmd /c "cd backend && python -m uvicorn main:app --host 0.0.0.0 --port 8002"

echo.
echo [2/2] Starting Streamlit Web Dashboard on http://localhost:8501...
start "Tiny Karuna Dashboard" cmd /c "cd streamlit_app && streamlit run app.py --server.port 8501"

echo.
echo ===================================================
echo   🎉 Success! Both services have been launched.
echo   - Backend: http://localhost:8002
echo   - Streamlit: http://localhost:8501 (Opening browser...)
echo ===================================================
echo.
pause
