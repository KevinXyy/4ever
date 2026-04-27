# Development Environment Requirements

This project prioritizes iOS first, but Windows can still be used for Flutter,
Dart, backend, documentation, and shared application logic.

## Windows Development Machine

Windows is suitable for:

- Flutter/Dart business logic and UI development.
- Domain, application, data, privacy, prompt, and safety modules.
- Pigeon API definitions.
- FastAPI backend development.
- Flutter web preview.
- Git and GitHub collaboration.

Windows cannot independently perform:

- iOS Simulator runs.
- iPhone device debugging.
- `flutter build ios`.
- Xcode archive/signing.
- CocoaPods iOS native build verification.
- TestFlight or App Store upload.

## Required Windows Tools

Minimum:

- Windows 11.
- Git.
- VS Code.
- Dart SDK.
- FVM 4.0.5.
- Flutter 3.41.7 via FVM.
- GitHub CLI 2.91.0.
- uv.
- Python 3.12.9 for backend work.
- Chrome for Flutter web preview.

Already expected by `scripts/setup-windows-dev.ps1`:

- `winget` from Microsoft App Installer.
- VS Code `code` command, if installing extensions automatically.

Optional:

- Android Studio and Android SDK, only if Android testing is needed on Windows.

## iOS Development Machine

iOS development must be handled on macOS.

Required:

- Apple Silicon Mac recommended.
- macOS version compatible with the target Xcode release.
- Xcode.
- Xcode command-line tools.
- iOS platform support.
- CocoaPods.
- Apple Developer account for signing, TestFlight, and App Store distribution.

Recommended Mac hardware:

- Minimum: 16 GB RAM, 512 GB SSD.
- Better: 24 GB or 32 GB RAM, 1 TB SSD.

The iOS owner should verify:

```bash
flutter doctor -v
flutter pub get
cd ios
pod install
cd ..
flutter run -d "iPhone Simulator"
```

## Install On Windows

From the repository root:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
.\scripts\setup-windows-dev.ps1
```

To also install Android Studio:

```powershell
.\scripts\setup-windows-dev.ps1 -InstallAndroidToolchain
```

After the script finishes, open a new PowerShell window and verify:

```powershell
dart --version
fvm --version
fvm flutter doctor
```

Expected Windows-only `flutter doctor` status:

- Flutter: pass.
- Windows version: pass.
- Chrome: pass.
- Android toolchain: may fail unless Android Studio/SDK is installed.
- iOS toolchain: not available on Windows by design.

## Repository Version Pinning

The repository uses FVM:

```json
{
  "flutter": "3.41.7"
}
```

Do not casually upgrade Flutter SDK or major package versions. SDK and major
dependency upgrades should be separate changes with analysis, tests, platform
build results, and rollback notes.

VS Code is configured to use the project FVM SDK:

```json
{
  "dart.flutterSdkPath": ".fvm/flutter_sdk",
  "dart.sdkPath": ".fvm/flutter_sdk/bin/cache/dart-sdk"
}
```

## Common Commands

Use FVM for Flutter commands:

```powershell
fvm flutter doctor
fvm flutter pub get
fvm flutter test
fvm flutter analyze
fvm flutter run -d chrome
```

Backend commands should use uv:

```powershell
uv python install 3.12.9
uv venv --python 3.12.9
uv pip install --python .venv\Scripts\python.exe -r requirements.txt
```

If the backend uses `pyproject.toml`, prefer:

```powershell
uv sync
```
