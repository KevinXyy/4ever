# Gemma Local

Privacy-first Flutter app for local wellbeing insights with replaceable on-device
LLM runtimes.

## Windows Setup

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
.\scripts\setup-windows-dev.ps1
```

## Common Commands

```powershell
.\scripts\project.ps1 get
.\scripts\project.ps1 analyze
.\scripts\project.ps1 test
.\scripts\project.ps1 run-web
```

On macOS/Linux with `make`:

```bash
make get
make analyze
make test
make run-web
```

## iOS

iOS builds, signing, HealthKit, Keychain, CocoaPods, and TestFlight require
macOS and Xcode. Windows is used for shared Flutter/Dart, backend, and
documentation work.

## Architecture Notes

- [Agent Skills Architecture](docs/AGENT_SKILLS_ARCHITECTURE.md)
- [Environment Requirements](docs/ENVIRONMENT_REQUIREMENTS.md)
