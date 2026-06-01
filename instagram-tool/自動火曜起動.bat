@echo off
chcp 932 > nul
rem === Tuesday auto-launcher: Only fires on Tuesdays. Otherwise exits silently. ===

rem Get day of week (0=Sun, 1=Mon, 2=Tue, ...) using PowerShell
for /f %%D in ('powershell -NoProfile -Command "(Get-Date).DayOfWeek.value__"') do set DOW=%%D

if not "%DOW%"=="2" (
    rem Not Tuesday - exit silently
    exit /b 0
)

rem Wait 60 seconds after PC startup so network/drives have time to mount
timeout /t 60 /nobreak > nul

rem Launch the main tool in a visible window
start "松岡製作所インスタツール" cmd /c "%~dp0起動.bat"
