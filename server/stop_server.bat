@echo off
taskkill /f /im moon.exe > nul 2>&1
timeout /t 2 > nul

taskkill /f /im cmd.exe > nul 2>&1
timeout /t 1 > nul

pause