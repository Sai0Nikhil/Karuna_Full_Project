@echo off
title Karuna - Startup Manager
cls

echo =================================================================
echo                    KARUNA LOCAL DEVELOPMENT STARTER
echo =================================================================
echo.
echo Please select what you want to launch:
echo [1] Run Python FastAPI Backend + React Frontend (Recommended)
echo [2] Run Java Spring Boot Backend + React Frontend
echo [3] Run Python Backend Only
echo [4] Run Java Backend Only
echo [5] Run React Frontend Only
echo [6] Exit
echo.
set /p choice="Enter choice (1-6): "

if "%choice%"=="1" goto py_and_react
if "%choice%"=="2" goto java_and_react
if "%choice%"=="3" goto py_only
if "%choice%"=="4" goto java_only
if "%choice%"=="5" goto react_only
if "%choice%"=="6" goto end
goto invalid

:py_and_react
echo Starting Python Backend...
start "Karuna Python Backend" cmd /k "cd Karuna- && python -m uvicorn backend.main:app --host 127.0.0.1 --port 8000"
timeout /t 3 >nul
echo Starting React Frontend...
start "Karuna React Frontend" cmd /k "cd Karuna- && npm.cmd run dev"
goto success

:java_and_react
call :find_mvn
if "%MVN_PATH%"=="" (
    echo Error: Could not locate Maven. Please make sure Maven is installed or IntelliJ is present.
    pause
    goto end
)
echo Starting Java Backend using: "%MVN_PATH%"
start "Karuna Java Backend" cmd /k "cd karuna-backend && ^"%MVN_PATH%^" spring-boot:run"
timeout /t 6 >nul
echo Starting React Frontend...
start "Karuna React Frontend" cmd /k "cd Karuna- && npm.cmd run dev"
goto success

:py_only
echo Starting Python Backend...
start "Karuna Python Backend" cmd /k "cd Karuna- && python -m uvicorn backend.main:app --host 127.0.0.1 --port 8000"
goto success

:java_only
call :find_mvn
if "%MVN_PATH%"=="" (
    echo Error: Could not locate Maven. Please make sure Maven is installed or IntelliJ is present.
    pause
    goto end
)
echo Starting Java Backend using: "%MVN_PATH%"
start "Karuna Java Backend" cmd /k "cd karuna-backend && ^"%MVN_PATH%^" spring-boot:run"
goto success

:react_only
echo Starting React Frontend...
start "Karuna React Frontend" cmd /k "cd Karuna- && npm.cmd run dev"
goto success

:invalid
echo Invalid choice.
pause
goto end

:success
echo.
echo =================================================================
echo Services launched successfully in separate terminal windows!
echo =================================================================
timeout /t 3 >nul
goto end

:find_mvn
set MVN_PATH=
where mvn >nul 2>nul
if %errorlevel% equ 0 (
    set MVN_PATH=mvn
    exit /b 0
)
if exist "C:\Program Files\JetBrains\IntelliJ IDEA Community Edition 2022.2.3\plugins\maven\lib\maven3\bin\mvn.cmd" (
    set MVN_PATH=C:\Program Files\JetBrains\IntelliJ IDEA Community Edition 2022.2.3\plugins\maven\lib\maven3\bin\mvn.cmd
    exit /b 0
)
exit /b 1

:end
