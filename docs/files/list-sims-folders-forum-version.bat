<# : batch portion
@echo off & setlocal

pushd "%~dp0"

set "p1=%~f0"
set p=%p1:^=%
set p=%p:@=%
set p=%p:&=%
if not "%p1%"=="%p%" goto :badpath

set "script_path=%~f0"

echo "Starting the script... %~f0"
powershell -noprofile "$_PSCommandPath = [Environment]::GetEnvironmentVariable('script_path', 'Process'); iex ((Get-Content -LiteralPath $_PSCommandPath) | out-string)"
if %ERRORLEVEL% EQU 0 goto :EOF

pause
goto :EOF

:badpath
echo %~dp0
echo Can't run, bad characters in folder path. The problematic characters are: @^&^^
pause
goto :EOF
: end batch / begin powershell #>

$start_text = "[code]"
$end_text = "[/code]"

$ErrorActionPreference = 'stop'
Set-Location -LiteralPath (Split-Path -parent $_PSCommandPath)
Clear-Host

$outputFile = "paths.txt"
Try {
    $_ = New-Item $outputFile -ItemType "file"
} Catch {
    $outputFile = [Environment]::GetFolderPath("Desktop") + "\" + $outputFile
}

function FixPath($path) {
    Return ($path -Replace "/","\").TrimEnd("\")
}

function GetInt32($bytes, $offset, $littleEndian = $False) {
    $slice = $bytes[$offset..($offset+3)]
    If ([System.BitConverter]::IsLittleEndian -xor $littleEndian) {
        [array]::Reverse($slice)
    }
    Return [System.BitConverter]::ToInt32($slice, 0)
}

function IsGameFolder($path) {
    If ([System.IO.File]::Exists($path + "\Data\Client\ClientDeltaBuild0.package")) { Return $True }
    If ([System.IO.File]::Exists($path + "\Data\Client\ClientDeltaBuild8.package")) { Return $True }
    If ([System.IO.File]::Exists($path + "\Data\Client\ClientFullBuild0.package")) { Return $True }
    If ([System.IO.File]::Exists($path + "\Data\Client\ClientFullBuild8.package")) { Return $True }
    If ([System.IO.File]::Exists($path + "\Data\Simulation\SimulationDeltaBuild0.package")) { Return $True }
    If ([System.IO.File]::Exists($path + "\Data\Simulation\SimulationFullBuild0.package")) { Return $True }
    Return $False
}

function IsDataFolder($path) {
    If ([System.IO.File]::Exists($path + "\Mods\Resource.cfg")) { Return $True }
    If ([System.IO.File]::Exists($path + "\Config.log")) { Return $True }
    If ([System.IO.File]::Exists($path + "\Events.ini")) { Return $True }
    If ([System.IO.File]::Exists($path + "\GameVersion.txt")) { Return $True }
    If ([System.IO.File]::Exists($path + "\Options.ini")) { Return $True }
    If ([System.IO.File]::Exists($path + "\UserSetting.ini")) { Return $True }
    Return $False
}

function IsRepackFolder($path) {
    If ((Get-ChildItem -LiteralPath $path | ? { $_.Name -imatch "\.xbin$" }).Count -gt 0) { Return $True }
    Return $False
}

function CheckLinks($path) {
    $file = Get-Item -LiteralPath $path -Force -ea SilentlyContinue
    While ($file -Ne $null) {
        $name = $file.FullName
        If ($symlinks.ContainsKey($name)) {
            Return
        }
        If ([bool]($file.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            $global:symlinks[$name] = $file.Target
        }
        $file = $file.Parent
    }
}

$folderContents = @{}

function CheckFolderContents($path) {
    If ($folderContents.ContainsKey($path)) {
        Return $folderContents[$path]
    }
    Write-Host $path

    $content = [System.Collections.ArrayList]@()
    $contentText = ""

    If ([System.IO.Directory]::Exists($path)) {
        CheckLinks($path)
        Try {
            $item = Get-ChildItem -LiteralPath $path
        }
        Catch {
            Return "[missing target?]"
        }
        If (($item | Measure-Object).Count -eq 0) {
            $content.Add("empty") > $null
        } Else {
            Try { If (IsGameFolder($path)) { $content.Add("game") > $null } } Catch {}
            Try { If (IsDataFolder($path)) { $content.Add("data") > $null } } Catch {}
            Try { If (IsRepackFolder($path)) { $content.Add("repack") > $null } } Catch {}
        }
    } Else {
        $content.Add("missing") > $null
    }
    If ($content.Count -gt 0) {
        $contentText = ("[" + ($content -Join ";") + "] ")
    }
    $global:folderContents[$path] = $contentText
    Return $contentText
}

function HandlePath($path) {
    $paths[$path] = $True
    $content = CheckFolderContents ($path)
    Add-Content $outputFile "$content$path" -Force -Encoding utf8
}

function GetFromConfigs() {
    Try {
        [string[]] $configs = Get-ChildItem -Path ($env:ProgramData + "\Origin\LocalContent\The Sims 4\*.dat")
    } Catch {
        $configs = @()
    }

    $paths = @{}

    ForEach ($config in $configs) {
        Try {
            $offset = 4
            $bytes = [System.IO.File]::ReadAllBytes($config)
            $len = GetInt32 $bytes $offset
            $offset += $len + 4
            $len = GetInt32 $bytes $offset
            $offset += $len + 4
            $len = GetInt32 $bytes $offset
            $offset += 4
            $path = FixPath ([Text.Encoding]::BigEndianUnicode.GetString($bytes[$offset..($offset+$len-1)]))
            $paths[$path] = $True
        } Catch {}
    }

    Return $paths
}

function GetFromReg($regPath, $name, $text) {
    Try {
        $path = FixPath (Get-ItemProperty -Path "Registry::$regPath" -Name $name)."$name"
    } Catch {
        Return
    }

    Add-Content $outputFile $text -Force -Encoding utf8
    HandlePath($path)
}

function GetFromUpdater() {
    Try {
        $path = (Get-Content ([Environment]::GetEnvironmentVariable("LocalAppData", "Process") + "\anadius\game_paths.cache") | ConvertFrom-Json)."The Sims 4"
    } Catch {
        Return
    }

    
    If ($path.Length -gt 0) {
        Add-Content $outputFile "Updater config:" -Force -Encoding utf8
        HandlePath($path)
    }
}

function GetFromCommonFolders_($path) {
    Write-Host "--- $path"
    Try {
        # exclude folders that have 2 or more characters between "sims" and "4"
        $dirs = Get-ChildItem -Attributes Directory+!System -Path $path |
            ? { $_.PsIsContainer -and $_.Name -imatch 'sims.?4' }
    } Catch {
        Try {
            $dirs = Get-ChildItem -Path $path -ErrorAction SilentlyContinue |
                ? { $_.PsIsContainer -and $_.Name -imatch 'sims.?4' }
        } Catch {
            Return
        }
    }

    ForEach ($dir in $dirs) {
        $path = FixPath ($dir.FullName)
        If ($paths.ContainsKey($path)) {
            Continue
        }

        $paths[$path] = $True
        $global:otherPaths.Add($path) > $null
    }
}

function GetFromCommonFolders($root) {
    GetFromCommonFolders_ ($root + "*Sims*4*\")
    GetFromCommonFolders_ ($root + "*\*Sims*4*\")
    GetFromCommonFolders_ ($root + "*\*\*Sims*4*\")
}

function Get-Client-Path-From-Registry {
    param (
        [string]$RegistryPath
    )

    $path = (Get-ItemProperty -Path ('Registry::HKEY_LOCAL_MACHINE\SOFTWARE\' + $RegistryPath) -Name ClientPath).ClientPath
    Return (Join-Path $path '..\version.dll')
}

function Check-Task {
    $old_preference = $ErrorActionPreference
    $ErrorActionPreference = 'continue'
    & schtasks /Query /TN copy_dlc_unlocker 2>&1>$null
    $ErrorActionPreference = $old_preference
    If ($LASTEXITCODE -Eq 0) {
        Return $True
    }
    Return $False
}

Write-Host "Don't close this window! It will close automatically when it's done."

Try {
    Clear-Content $outputFile -Force
} Catch {}

Add-Content $outputFile $start_text -Force -Encoding utf8

$programdata = [Environment]::GetEnvironmentVariable("ProgramData", "Process")
If (Test-Path -Literal (Join-Path $programdata 'EA Desktop\InstallData\The Sims 4')) {
    Add-Content $outputFile "EA app folder found" -Force -Encoding utf8
}
If (Test-Path -Literal (Join-Path $programdata 'Origin\LocalContent\The Sims 4')) {
    Add-Content $outputFile "Origin folder found" -Force -Encoding utf8
}

$client = 'ea_desktop'
$client_name = 'EA app'
Try {
    $dll_path = Get-Client-Path-From-Registry 'Electronic Arts\EA Desktop'
}
Catch {
    $client = 'origin'
    $client_name = 'Origin'
    Try {
        $dll_path = Get-Client-Path-From-Registry 'WOW6432Node\Origin'
    }
    Catch {
        Try {
            $dll_path = Get-Client-Path-From-Registry 'Origin'
        }
        Catch {
            $client = 'none'
        }
    }
}

If ($client -Ne 'none') {
    If (Test-Path -Literal $dll_path) {
        Add-Content $outputFile "DLC Unlocker for $client_name installed" -Force -Encoding utf8
        $unlocker_path = Join-Path $env:AppData "\anadius\EA DLC Unlocker v2"
        If (!(Test-Path -Literal (Join-Path $unlocker_path "config.ini"))) {
            Add-Content $outputFile "Main config missing" -Force -Encoding utf8
        }
        If (!(Test-Path -Literal (Join-Path $unlocker_path "g_The Sims 4.ini"))) {
            Add-Content $outputFile "TS4 config missing" -Force -Encoding utf8
        }
        If (($client -Eq 'ea_desktop') -And !(Check-Task)) {
            Add-Content $outputFile "Copy task missing" -Force -Encoding utf8
        }
    }
    Else {
        Add-Content $outputFile "DLC Unlocker for $client_name not installed" -Force -Encoding utf8
    }
}

Write-Host "Checking Origin config files"
$symlinks = @{}
$paths = @{}
$paths2 = GetFromConfigs
If ($paths2.Count -gt 0) {
    Add-Content $outputFile "Origin config:" -Force -Encoding utf8
    ForEach ($path in $paths2.GetEnumerator()) {
        HandlePath($path.Key)
    }
}

Write-Host "Checking registry"
GetFromReg "HKLM\SOFTWARE\Maxis\The Sims 4" "Install Dir" "Normal version:"
GetFromReg "HKLM\SOFTWARE\WOW6432Node\Maxis\The Sims 4" "Install Dir" "32-bit version:"
GetFromReg "HKLM\SOFTWARE\Maxis\The Sims 4" "Alternative Install Dir" "Alternative version:"

Write-Host "Checking Updater config"
GetFromUpdater

$otherPaths = [System.Collections.ArrayList]@()

Write-Host "Checking common paths"
ForEach ($drive in Get-PSDrive) {
    If (-NOT ($drive.Name -match '^[a-z]$')) {
        Continue
    }

    GetFromCommonFolders ($drive.Root)
}

Try {
    $shell = New-Object -ComObject Shell.Application
    GetFromCommonFolders ($shell.NameSpace('shell:Downloads').Self.Path + "\")
    GetFromCommonFolders ($shell.NameSpace('shell:Desktop').Self.Path + "\")
    GetFromCommonFolders ($shell.NameSpace('shell:Personal').Self.Path + "\")
} Catch {}

$otherPaths = $otherPaths | Sort

If ($otherPaths.Count -gt 0) {
    Add-Content $outputFile "Other paths:" -Force -Encoding utf8
    ForEach ($path in $otherPaths) {
        HandlePath($path)
    }
}

If ($symlinks.Count -gt 0) {
    Add-Content $outputFile "Links:" -Force -Encoding utf8
    ForEach ($pair in $symlinks.GetEnumerator()) {
        Add-Content $outputFile "$($pair.Name) ==> $($pair.Value)" -Force -Encoding utf8
    }
}

Add-Content $outputFile $end_text -Force -Encoding utf8

Invoke-Item $outputFile
