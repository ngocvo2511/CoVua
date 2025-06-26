@echo off
title Chess Web Interface - Setup Check
color 0A

echo.
echo ========================================
echo   Chess Web Interface - Setup Check
echo ========================================
echo.

echo [1/4] Checking Node.js installation...
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Node.js is not installed or not in PATH
    echo.
    echo Please install Node.js from: https://nodejs.org/
    echo Choose the LTS version for best compatibility.
    echo.
    pause
    exit /b 1
) else (
    echo ✓ Node.js is installed
    node --version
)

echo.
echo [2/4] Checking SWI-Prolog installation...
swipl --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ SWI-Prolog is not installed or not in PATH
    echo.
    echo To install SWI-Prolog:
    echo 1. Go to: https://www.swi-prolog.org/download/stable
    echo 2. Download the Windows installer
    echo 3. Run the installer and make sure to check "Add to PATH"
    echo 4. Restart your command prompt after installation
    echo.
    echo Alternative: You can also install via Chocolatey:
    echo    choco install swi-prolog
    echo.
    pause
    exit /b 1
) else (
    echo ✓ SWI-Prolog is installed
    swipl --version | findstr "version"
)

echo.
echo [3/4] Checking Prolog chess files...
if exist "..\chess.pl" (
    echo ✓ chess.pl found
) else (
    echo ❌ chess.pl not found in parent directory
    echo Make sure you're running this from the web-interface folder
    echo and that chess.pl exists in the Prolog directory
    pause
    exit /b 1
)

echo.
echo [4/4] Checking Node.js dependencies...
if exist "node_modules" (
    echo ✓ Node.js dependencies installed
) else (
    echo Installing Node.js dependencies...
    npm install
    if %errorlevel% neq 0 (
        echo ❌ Failed to install dependencies
        pause
        exit /b 1
    ) else (
        echo ✓ Dependencies installed successfully
    )
)

echo.
echo ========================================
echo   ✓ All checks passed! Ready to play!
echo ========================================
echo.
echo Starting chess server...
echo Open your browser to: http://localhost:3000
echo Press Ctrl+C to stop the server
echo.

node server.js

if %errorlevel% neq 0 (
    echo.
    echo ❌ Server failed to start. Check the error messages above.
    echo.
    pause
)
