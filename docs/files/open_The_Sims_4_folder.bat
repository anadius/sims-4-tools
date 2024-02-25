@echo off

setlocal ENABLEEXTENSIONS
set "KEY_NAME=HKEY_LOCAL_MACHINE\Software\Maxis\The Sims 4"
set "VALUE_NAME=Install Dir"

for /f "usebackq tokens=1-3*" %%a IN (`^(reg query "%KEY_NAME%" /v "%VALUE_NAME%" ^| find "%VALUE_NAME%"^) 2^>nul`) do (
    set Value=%%d
)

if defined Value (
    call :openFolder "%Value%"
) else (
    echo The Sims 4 not found.
    pause
)

goto :eof

:openFolder
explorer "%~dp1"
