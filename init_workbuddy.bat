@echo off
REM init_workbuddy.bat - Turtle Investment Framework setup for WorkBuddy (Windows)
REM Run this in a Bash terminal (Git Bash) via: bash init_workbuddy.bat
REM Or just run: bash init.sh

echo === Turtle Investment Framework - WorkBuddy Setup ===
echo.
echo Option 1: Run setup via Git Bash
echo   bash init.sh
echo.
echo Option 2: Manual setup steps:
echo   1. Copy .env.sample to .env and fill in your tokens
echo      copy .env.sample .env
echo.
echo   2. Create Python venv and install dependencies
echo      C:\Users\harry\.workbuddy\binaries\python\versions\3.13.12\python.exe -m venv .venv
echo      .venv\Scripts\pip install -r requirements.txt
echo.
echo   3. Verify setup
echo      .venv\Scripts\pytest tests/ -x -q --tb=short
echo.
echo === Prerequisites ===
echo - Tushare Pro Token: https://tushare.pro/register
echo - DeepSeek API Key: https://platform.deepseek.com
