param(
  [switch]$InstallAndroidToolchain,
  [switch]$SkipVSCodeExtensions
)

$ErrorActionPreference = "Stop"

$DartSdkPackageId = "Google.DartSDK"
$FvmVersion = "4.0.5"
$FlutterVersion = "3.41.7"
$PythonVersion = "3.12.9"
$GitHubCliVersion = "2.91.0"

$DartSdkBin = Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Packages\Google.DartSDK_Microsoft.Winget.Source_8wekyb3d8bbwe\dart-sdk\bin"
$PubCacheBin = Join-Path $env:LOCALAPPDATA "Pub\Cache\bin"

function Write-Section {
  param([string]$Message)
  Write-Host ""
  Write-Host "==> $Message" -ForegroundColor Cyan
}

function Test-Command {
  param([string]$Name)
  return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Add-UserPathEntry {
  param([string]$PathEntry)

  if (-not (Test-Path $PathEntry)) {
    return
  }

  $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
  $parts = @()
  if ($userPath) {
    $parts = $userPath -split ";" | Where-Object { $_ }
  }

  if ($parts -notcontains $PathEntry) {
    $parts += $PathEntry
    [System.Environment]::SetEnvironmentVariable("Path", ($parts -join ";"), "User")
  }
}

function Refresh-CurrentPath {
  $machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
  $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
  $env:Path = "$DartSdkBin;$PubCacheBin;$machinePath;$userPath"
}

function Invoke-WingetInstall {
  param(
    [string]$Id,
    [string]$Name
  )

  Write-Section "Installing $Name"
  winget install --id $Id --exact --accept-package-agreements --accept-source-agreements
}

Write-Section "Checking winget"
if (-not (Test-Command "winget")) {
  throw "winget is required. Install App Installer from Microsoft Store, then rerun this script."
}

Write-Section "Installing Dart SDK"
if (-not (Test-Path (Join-Path $DartSdkBin "dart.exe"))) {
  Invoke-WingetInstall -Id $DartSdkPackageId -Name "Dart SDK"
} else {
  Write-Host "Dart SDK already exists at $DartSdkBin"
}

Add-UserPathEntry -PathEntry $DartSdkBin
Add-UserPathEntry -PathEntry $PubCacheBin
Refresh-CurrentPath

Write-Section "Installing FVM"
if (-not (Test-Path (Join-Path $PubCacheBin "fvm.bat"))) {
  & (Join-Path $DartSdkBin "dart.exe") pub global activate fvm $FvmVersion
} else {
  Write-Host "FVM already exists at $PubCacheBin"
}

Refresh-CurrentPath

Write-Section "Installing Flutter $FlutterVersion via FVM"
& (Join-Path $PubCacheBin "fvm.bat") install $FlutterVersion
& (Join-Path $PubCacheBin "fvm.bat") use $FlutterVersion --force --skip-pub-get --skip-setup

Write-Section "Installing GitHub CLI"
if (-not (Test-Command "gh") -and -not (Test-Path "C:\Program Files\GitHub CLI\gh.exe")) {
  winget install --id GitHub.cli --exact --version $GitHubCliVersion --accept-package-agreements --accept-source-agreements
} else {
  Write-Host "GitHub CLI already installed"
}

Write-Section "Installing uv and Python 3.12"
if (-not (Test-Command "uv")) {
  try {
    Invoke-WingetInstall -Id "astral-sh.uv" -Name "uv"
  } catch {
    Write-Warning "Could not install uv via winget. Install uv manually from https://docs.astral.sh/uv/"
  }
}

if (Test-Command "uv") {
  uv python install $PythonVersion
} else {
  Write-Warning "uv is not available, skipping Python 3.12 installation."
}

if (-not $SkipVSCodeExtensions) {
  Write-Section "Installing VS Code extensions"
  if (Test-Command "code") {
    code --install-extension Dart-Code.dart-code --force
    code --install-extension Dart-Code.flutter --force
  } else {
    Write-Warning "VS Code command 'code' was not found. Install VS Code or enable the shell command manually."
  }
}

if ($InstallAndroidToolchain) {
  Write-Section "Installing Android Studio"
  Invoke-WingetInstall -Id "Google.AndroidStudio" -Name "Android Studio"
  Write-Warning "Open Android Studio once after installation to install Android SDK and command-line tools."
}

Write-Section "Flutter doctor"
& (Join-Path $PubCacheBin "fvm.bat") flutter doctor

Write-Host ""
Write-Host "Windows setup complete." -ForegroundColor Green
Write-Host "Open a new PowerShell window so PATH changes are picked up."
Write-Host "Use: fvm flutter doctor"
