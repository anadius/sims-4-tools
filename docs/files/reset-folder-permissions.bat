<# : batch portion
@echo off & setlocal

pushd "%~dp0"

REM Check if running as admin
REM taken from https://stackoverflow.com/a/21295806/2428152
fsutil dirty query %systemdrive% >nul
if not %errorlevel% == 0 (
  echo You were supposed to start this script as administrator! Right click on it and select "Run as administrator"
  pause
  exit /b
)

set "p1=%~f0"
set p=%p1:^=%
set p=%p:@=%
set p=%p:&=%
if not "%p1%"=="%p%" goto :badpath

set "script_path=%~f0"

echo "Starting the script... %~f0"
powershell -noprofile "$_PSCommandPath = [Environment]::GetEnvironmentVariable('script_path', 'Process'); iex ((Get-Content -LiteralPath $_PSCommandPath) | out-string)"

pause
goto :EOF

:badpath
echo %~dp0
echo Can't run, bad characters in folder path. The problematic characters are: @^&^^
pause
goto :EOF
: end batch / begin powershell #>

$ErrorActionPreference = 'stop'
Set-Location -LiteralPath (Split-Path -parent $_PSCommandPath)
Clear-Host

Function Get-Folder() {
    [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null

    $foldername = New-Object System.Windows.Forms.FolderBrowserDialog
    $foldername.Description = "Select the folder with your game."
    $foldername.rootfolder = "MyComputer"
    $foldername.SelectedPath = ""
    $foldername.ShowNewFolderButton = $FALSE

    If ($foldername.ShowDialog() -eq "OK") {
        Return $foldername.SelectedPath
    }
    Else {
        Return ""
    }
}

Try {
    $path = Get-Folder
} Catch {
    Write-Host "Can't get the path!"
    Exit -1
}

If ($path.length -eq 0) {
    Write-Host "You didn't select any path!"
    Exit -1
}

icacls.exe "$path" /reset /t /c /l
