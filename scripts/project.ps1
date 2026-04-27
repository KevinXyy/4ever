param(
  [Parameter(Mandatory = $true)]
  [ValidateSet(
    "doctor",
    "get",
    "analyze",
    "test",
    "gen",
    "run-web",
    "clean",
    "server-setup",
    "server-lint",
    "server-typecheck",
    "server-test"
  )]
  [string]$Task
)

$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$AppDir = Join-Path $RepoRoot "app"
$ServerDir = Join-Path $RepoRoot "server"
$PubCacheBin = Join-Path $env:LOCALAPPDATA "Pub\Cache\bin"
$DartSdkBin = Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Packages\Google.DartSDK_Microsoft.Winget.Source_8wekyb3d8bbwe\dart-sdk\bin"

$env:Path = "$DartSdkBin;$PubCacheBin;$env:Path"
$Fvm = Join-Path $PubCacheBin "fvm.bat"

if ($Task -notlike "server-*" -and -not (Test-Path $Fvm)) {
  throw "FVM was not found. Run scripts/setup-windows-dev.ps1 first."
}

if ($Task -like "server-*") {
  Push-Location $ServerDir
  try {
    $env:PYTHONPATH = $ServerDir
    switch ($Task) {
      "server-setup" {
        uv venv --python 3.12.9
        uv pip install --python .\.venv\Scripts\python.exe -r requirements.txt
      }
      "server-lint" { & .\.venv\Scripts\ruff.exe check app tests --no-cache }
      "server-typecheck" { & .\.venv\Scripts\mypy.exe app }
      "server-test" { & .\.venv\Scripts\pytest.exe }
    }
  } finally {
    Pop-Location
  }
} else {
  Push-Location $AppDir
  try {
    switch ($Task) {
      "doctor" { & $Fvm flutter doctor }
      "get" { & $Fvm flutter pub get }
      "analyze" { & $Fvm flutter analyze }
      "test" { & $Fvm flutter test }
      "gen" { & $Fvm dart run build_runner build --delete-conflicting-outputs }
      "run-web" { & $Fvm flutter run -d chrome }
      "clean" { & $Fvm flutter clean }
    }
  } finally {
    Pop-Location
  }
}
