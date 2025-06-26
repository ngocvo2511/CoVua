@echo off
title Chess Web Interface
color 0A

echo.
echo ♔♛ Starting Chess Web Interface ♛♔
echo.

REM Check if node_modules exists
if not exist "node_modules" (
    echo Installing dependencies...
    npm install
    if %errorlevel% neq 0 (
        echo ❌ Failed to install dependencies
        echo Try running: npm install
        pause
        exit /b 1
    )
    echo.
)

echo 🚀 Starting server...
echo 🌐 Open your browser to: http://localhost:3000
echo 🛑 Press Ctrl+C to stop the server
echo.

node server.js

if %errorlevel% neq 0 (
    echo.
    echo ❌ Server failed to start!
    echo.
    echo Common solutions:
    echo 1. Install SWI-Prolog from: https://www.swi-prolog.org/download/stable
    echo 2. Make sure SWI-Prolog is added to your system PATH
    echo 3. Run setup-and-start.bat for detailed setup check
    echo.
    pause
)
