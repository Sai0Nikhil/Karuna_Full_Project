@echo off
title Karuna - Startup Manager
cls

echo =================================================================
echo                    KARUNA LOCAL DEVELOPMENT STARTER
echo =================================================================
echo.
echo Please select what you want to launch:
echo [1] Java Backend + Citizen Web App    (Recommended)
echo [2] Java Backend + NGO Web App
echo [3] All: Java Backend + Citizen + NGO
echo [4] Java Backend Only
echo [5] Citizen Web App Only
echo [6] NGO Web App Only
echo [7] Exit
echo.
set /p choice="Enter choice (1-7): "

if "%choice%"=="1" goto java_and_citizen
if "%choice%"=="2" goto java_and_ngo
if "%choice%"=="3" goto java_all
if "%choice%"=="4" goto java_only
if "%choice%"=="5" goto citizen_only
if "%choice%"=="6" goto ngo_only
if "%choice%"=="7" goto end
goto invalid

:java_and_citizen
call :find_mvn
if "%MVN_PATH%"=="" ( echo Error: Maven not found. & pause & goto end )
echo Starting Java Backend...
start "Karuna Java Backend" cmd /k "cd karuna-backend && "%MVN_PATH%" spring-boot:run"
timeout /t 6 >nul
echo Starting Citizen Web App...
start "Karuna Citizen App" cmd /k "cd website\citizen && npm.cmd run dev"
goto success

:java_and_ngo
call :find_mvn
if "%MVN_PATH%"=="" ( echo Error: Maven not found. & pause & goto end )
echo Starting Java Backend...
start "Karuna Java Backend" cmd /k "cd karuna-backend && "%MVN_PATH%" spring-boot:run"
timeout /t 6 >nul
echo Starting NGO Web App...
start "Karuna NGO App" cmd /k "cd website\ngo && npm.cmd run dev"
goto success

:java_all
call :find_mvn
if "%MVN_PATH%"=="" ( echo Error: Maven not found. & pause & goto end )
echo Starting Java Backend...
start "Karuna Java Backend" cmd /k "cd karuna-backend && "%MVN_PATH%" spring-boot:run"
timeout /t 6 >nul
echo Starting Citizen Web App...
start "Karuna Citizen App" cmd /k "cd website\citizen && npm.cmd run dev"
echo Starting NGO Web App...
start "Karuna NGO App" cmd /k "cd website\ngo && npm.cmd run dev"
goto success

:java_only
call :find_mvn
if "%MVN_PATH%"=="" ( echo Error: Maven not found. & pause & goto end )
echo Starting Java Backend...
start "Karuna Java Backend" cmd /k "cd karuna-backend && "%MVN_PATH%" spring-boot:run"
goto success

:citizen_only
echo Starting Citizen Web App...
start "Karuna Citizen App" cmd /k "cd website\citizen && npm.cmd run dev"
goto success

:ngo_only
echo Starting NGO Web App...
start "Karuna NGO App" cmd /k "cd website\ngo && npm.cmd run dev"
goto success

:invalid
echo Invalid choice.
pause
goto end

:success
echo.
echo =================================================================
echo Services launched in separate terminal windows!
echo   Citizen app: http://localhost:5173
echo   NGO app:     http://localhost:5174
echo   Backend:     http://localhost:8081
echo =================================================================
timeout /t 3 >nul
goto end

:find_mvn
set MVN_PATH=
where mvn >nul 2>nul
if %errorlevel% equ 0 ( set MVN_PATH=mvn & exit /b 0 )
if exist "C:\Program Files\JetBrains\IntelliJ IDEA Community Edition 2022.2.3\plugins\maven\lib\maven3\bin\mvn.cmd" (
    set MVN_PATH=C:\Program Files\JetBrains\IntelliJ IDEA Community Edition 2022.2.3\plugins\maven\lib\maven3\bin\mvn.cmd
    exit /b 0
)
exit /b 1

:end
