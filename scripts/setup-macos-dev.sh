#!/usr/bin/env bash
set -euo pipefail

INSTALL_ANDROID_TOOLCHAIN=0
SKIP_VSCODE_EXTENSIONS=0
SKIP_PUB_GET=0
SKIP_SERVER_SYNC=0

FVM_VERSION="4.0.5"
FLUTTER_VERSION="3.41.7"
PYTHON_VERSION="3.12.9"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_DIR="$REPO_ROOT/app"
SERVER_DIR="$REPO_ROOT/server"

usage() {
  cat <<'USAGE'
Usage: scripts/setup-macos-dev.sh [options]

Options:
  --install-android-toolchain  Install Android Studio, Android SDK helpers, and OpenJDK.
  --skip-vscode-extensions    Do not install recommended VS Code extensions.
  --skip-pub-get              Do not run Flutter pub get after installing Flutter.
  --skip-server-sync          Do not create/sync the server uv environment.
  -h, --help                  Show this help.

This script intentionally skips Xcode installation. It configures the shared
project toolchain required by this repo: Homebrew prerequisites, FVM, Flutter,
uv, Python 3.12.9, CocoaPods, Flutter packages, and backend dependencies.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --install-android-toolchain)
      INSTALL_ANDROID_TOOLCHAIN=1
      shift
      ;;
    --skip-vscode-extensions)
      SKIP_VSCODE_EXTENSIONS=1
      shift
      ;;
    --skip-pub-get)
      SKIP_PUB_GET=1
      shift
      ;;
    --skip-server-sync)
      SKIP_SERVER_SYNC=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 2
      ;;
  esac
done

section() {
  printf '\n==> %s\n' "$1"
}

has_command() {
  command -v "$1" >/dev/null 2>&1
}

ensure_homebrew() {
  section "Checking Homebrew"
  if has_command brew; then
    return
  fi

  echo "Homebrew is required. Install it first:"
  echo '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  exit 1
}

fix_homebrew_permissions() {
  local brew_prefix
  brew_prefix="$(brew --prefix)"

  local paths=(
    "$HOME/Library/Caches/Homebrew"
    "$HOME/Library/Logs/Homebrew"
    "$brew_prefix/Cellar"
    "$brew_prefix/Frameworks"
    "$brew_prefix/Homebrew"
    "$brew_prefix/bin"
    "$brew_prefix/etc"
    "$brew_prefix/include"
    "$brew_prefix/lib"
    "$brew_prefix/opt"
    "$brew_prefix/sbin"
    "$brew_prefix/share"
    "$brew_prefix/var/homebrew/linked"
    "$brew_prefix/var/homebrew/locks"
    "$brew_prefix/var/log"
  )

  local needs_fix=0
  for path in "${paths[@]}"; do
    if [[ -e "$path" && ! -w "$path" ]]; then
      needs_fix=1
      break
    fi
  done

  if [[ "$needs_fix" -eq 0 ]]; then
    return
  fi

  section "Fixing Homebrew permissions"
  echo "sudo is required once so Homebrew can install project tools."
  sudo -v

  local existing_paths=()
  for path in "${paths[@]}"; do
    if [[ -e "$path" ]]; then
      existing_paths+=("$path")
    fi
  done

  if [[ "${#existing_paths[@]}" -gt 0 ]]; then
    sudo chown -R "$(id -un)" "${existing_paths[@]}"
    chmod -R u+w "${existing_paths[@]}"
  fi
}

install_brew_formula() {
  local formula="$1"
  if brew list --formula "$formula" >/dev/null 2>&1; then
    echo "$formula already installed"
    return
  fi

  brew install "$formula"
}

install_brew_cask() {
  local cask="$1"
  if brew list --cask "$cask" >/dev/null 2>&1; then
    echo "$cask already installed"
    return
  fi

  brew install --cask "$cask"
}

ensure_pub_cache_path_hint() {
  local shell_profile="$HOME/.zshrc"
  local pub_cache_bin="$HOME/.pub-cache/bin"
  local fvm_flutter_bin="$APP_DIR/.fvm/flutter_sdk/bin"
  local android_sdk_root
  android_sdk_root="$(brew --prefix)/share/android-commandlinetools"

  touch "$shell_profile"

  if ! grep -Fq "$pub_cache_bin" "$shell_profile"; then
    {
      echo ""
      echo "# Gemma Local Flutter tooling"
      echo "export PATH=\"\$PATH:$pub_cache_bin\""
    } >> "$shell_profile"
  fi

  if ! grep -Fq "$fvm_flutter_bin" "$shell_profile"; then
    {
      echo "export PATH=\"\$PATH:$fvm_flutter_bin\""
    } >> "$shell_profile"
  fi

  if [[ "$INSTALL_ANDROID_TOOLCHAIN" -eq 1 ]] &&
    ! grep -Fq "$android_sdk_root" "$shell_profile"; then
    {
      echo ""
      echo "# Gemma Local Android tooling"
      echo "export ANDROID_HOME=\"$android_sdk_root\""
      echo "export ANDROID_SDK_ROOT=\"$android_sdk_root\""
      echo "export PATH=\"\$PATH:$android_sdk_root/cmdline-tools/latest/bin:$android_sdk_root/platform-tools\""
    } >> "$shell_profile"
  fi

  export PATH="$PATH:$pub_cache_bin:$fvm_flutter_bin"
}

section "Repository"
echo "$REPO_ROOT"

ensure_homebrew
fix_homebrew_permissions

section "Installing core tools"
brew update
install_brew_formula fvm
install_brew_formula uv
install_brew_formula cocoapods

if [[ "$INSTALL_ANDROID_TOOLCHAIN" -eq 1 ]]; then
  section "Installing optional Android toolchain"
  install_brew_formula openjdk
  install_brew_cask android-commandlinetools
  install_brew_cask android-studio

  ANDROID_HOME="$(brew --prefix)/share/android-commandlinetools"
  ANDROID_SDK_ROOT="$ANDROID_HOME"
  export ANDROID_HOME ANDROID_SDK_ROOT
  export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"

  yes | sdkmanager --licenses >/dev/null || true
  sdkmanager \
    "platform-tools" \
    "platforms;android-36" \
    "build-tools;36.0.0"

  echo "Android SDK root: $ANDROID_HOME"
fi

ensure_pub_cache_path_hint

section "Installing Flutter $FLUTTER_VERSION via FVM"
cd "$APP_DIR"
fvm install "$FLUTTER_VERSION"
fvm use "$FLUTTER_VERSION" --force --skip-pub-get --skip-setup

if [[ "$SKIP_PUB_GET" -eq 0 ]]; then
  section "Installing Flutter packages"
  fvm flutter pub get
fi

section "Installing Python $PYTHON_VERSION via uv"
uv python install "$PYTHON_VERSION"

if [[ "$SKIP_SERVER_SYNC" -eq 0 ]]; then
  section "Syncing backend environment"
  cd "$SERVER_DIR"
  uv sync
fi

if [[ "$SKIP_VSCODE_EXTENSIONS" -eq 0 ]] && has_command code; then
  section "Installing VS Code extensions"
  code --install-extension Dart-Code.dart-code --force
  code --install-extension Dart-Code.flutter --force
  code --install-extension ms-python.python --force
  code --install-extension charliermarsh.ruff --force
elif [[ "$SKIP_VSCODE_EXTENSIONS" -eq 0 ]]; then
  echo "VS Code 'code' command not found; skipping extensions."
fi

section "Verification"
cd "$APP_DIR"
fvm --version
fvm flutter --version
uv --version
uv python list | grep "$PYTHON_VERSION" || true

echo ""
echo "macOS setup complete."
echo "Open a new terminal, then run:"
echo "  cd $APP_DIR && fvm flutter doctor"
echo "  cd $SERVER_DIR && uv run pytest"
