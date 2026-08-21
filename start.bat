@echo off
title Karuna - Startup Manager

if "%1"=="run_backend" goto run_backend
if "%1"=="run_citizen" goto run_citizen
if "%1"=="run_ngo" goto run_ngo

cls

echo =================================================================
echo                    KARUNA LOCAL DEVELOPMENT STARTER
echo =================================================================
echo.
echo Please select what you want to launch:
echo [1] Start Full Backend Stack via Docker Compose (Recommended)
echo     - (Starts Postgres + MongoDB + Spring Boot + Python AI Service in Docker)
echo.
echo [2] Start Databases Only via Docker Compose
echo     - (Starts Postgres + MongoDB, then you run Spring Boot locally in IDE/CLI)
echo.
echo [3] Java Backend Only (Local via Maven)
echo [4] Citizen Web App Only (Local)
echo [5] NGO Web App Only (Local)
echo.
echo [6] Java Backend + Citizen Web App (Local)
echo [7] Java Backend + NGO Web App (Local)
echo [8] All: Java Backend + Citizen + NGO (Local)
echo [9] Exit
echo.
set /p choice="Enter choice (1-9): "

if "%choice%"=="1" goto docker_all
if "%choice%"=="2" goto docker_db
if "%choice%"=="3" goto java_only
if "%choice%"=="4" goto citizen_only
if "%choice%"=="5" goto ngo_only
if "%choice%"=="6" goto java_and_citizen
if "%choice%"=="7" goto java_and_ngo
if "%choice%"=="8" goto java_all
if "%choice%"=="9" goto end
goto invalid

:docker_all
echo Starting all backend services via Docker Compose...
docker-compose up --build
goto end

:docker_db
echo Starting Postgres and MongoDB containers...
docker-compose up -d postgres mongodb
echo.
echo Databases are running in the background!
echo You can now run Spring Boot in your IDE or using option 3.
echo.
pause
goto end

:java_and_citizen
call :find_mvn
if "%MVN_PATH%"=="" ( echo Error: Maven not found. & pause & goto end )
echo Starting Java Backend...
start "Karuna Java Backend" cmd /k call "%~f0" run_backend
timeout /t 6 >nul
echo Starting Citizen Web App...
start "Karuna Citizen App" cmd /k call "%~f0" run_citizen
goto success

:java_and_ngo
call :find_mvn
if "%MVN_PATH%"=="" ( echo Error: Maven not found. & pause & goto end )
echo Starting Java Backend...
start "Karuna Java Backend" cmd /k call "%~f0" run_backend
timeout /t 6 >nul
echo Starting NGO Web App...
start "Karuna NGO App" cmd /k call "%~f0" run_ngo
goto success

:java_all
call :find_mvn
if "%MVN_PATH%"=="" ( echo Error: Maven not found. & pause & goto end )
echo Starting Java Backend...
start "Karuna Java Backend" cmd /k call "%~f0" run_backend
timeout /t 6 >nul
echo Starting Citizen Web App...
start "Karuna Citizen App" cmd /k call "%~f0" run_citizen
echo Starting NGO Web App...
start "Karuna NGO App" cmd /k call "%~f0" run_ngo
goto success

:java_only
call :find_mvn
if "%MVN_PATH%"=="" ( echo Error: Maven not found. & pause & goto end )
echo Starting Java Backend...
start "Karuna Java Backend" cmd /k call "%~f0" run_backend
goto success

:citizen_only
echo Starting Citizen Web App...
start "Karuna Citizen App" cmd /k call "%~f0" run_citizen
goto success

:ngo_only
echo Starting NGO Web App...
start "Karuna NGO App" cmd /k call "%~f0" run_ngo
goto success

:invalid
echo Invalid choice.
pause
goto end

:success
echo.
echo =================================================================
echo Services launched in separate terminal windows!
echo   Citizen app: http://localhost:3001
echo   NGO app:     http://localhost:3002
echo   Backend:     http://localhost:8081
echo =================================================================
timeout /t 3 >nul
goto end

:find_mvn
set "MVN_PATH="
where mvn >nul 2>nul
if %errorlevel% equ 0 ( set "MVN_PATH=mvn" & exit /b 0 )
for /d %%D in ("%USERPROFILE%\.maven\maven-*") do (
    if exist "%%~fD\bin\mvn.cmd" (
        set "MVN_PATH=%%~fD\bin\mvn.cmd"
        exit /b 0
    )
)
for /d %%D in ("%USERPROFILE%\.m2\wrapper\dists\apache-maven*") do (
    for /d %%E in ("%%~fD\*") do (
        if exist "%%~fE\bin\mvn.cmd" (
            set "MVN_PATH=%%~fE\bin\mvn.cmd"
            exit /b 0
        )
        for /d %%F in ("%%~fE\apache-maven-*") do (
            if exist "%%~fF\bin\mvn.cmd" (
                set "MVN_PATH=%%~fF\bin\mvn.cmd"
                exit /b 0
            )
        )
    )
)
if exist "C:\Program Files\JetBrains\IntelliJ IDEA Community Edition 2022.2.3\plugins\maven\lib\maven3\bin\mvn.cmd" (
    set "MVN_PATH=C:\Program Files\JetBrains\IntelliJ IDEA Community Edition 2022.2.3\plugins\maven\lib\maven3\bin\mvn.cmd"
    exit /b 0
)
exit /b 1

:run_backend
if "%MVN_PATH%"=="" call :find_mvn
if "%MVN_PATH%"=="" ( echo Error: Maven not found. & exit /b 1 )
cd /d "%~dp0backend\springboot"
call "%MVN_PATH%" spring-boot:run
exit /b

:run_citizen
cd /d "%~dp0frontend\website\citizen"
npm.cmd run dev
exit /b

:run_ngo
cd /d "%~dp0frontend\website\ngo"
npm.cmd run dev
exit /b

:end
