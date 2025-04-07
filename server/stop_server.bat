@echo off
echo 正在停止所有服务器进程...
taskkill /f /im moon.exe > nul 2>&1
timeout /t 2 > nul

echo 清理残留进程...
taskkill /f /im cmd.exe > nul 2>&1
timeout /t 1 > nul

echo 所有服务已停止
pause