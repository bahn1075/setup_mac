#!/usr/bin/env bash

set -euo pipefail

log() {
  printf '\n[%s] %s\n' "$(date '+%H:%M:%S')" "$1"
}

append_if_missing() {
  local line="$1"
  local file="$2"

  touch "$file"
  if ! grep -Fqx "$line" "$file"; then
    printf '%s\n' "$line" >> "$file"
  fi
}

ensure_oh_my_zsh_plugin_list() {
  local zshrc="$1"
  local plugin_line='plugins=(git kubectl docker minikube brew macos zsh-syntax-highlighting zsh-autosuggestions)'

  touch "$zshrc"

  if grep -q '^plugins=' "$zshrc"; then
    perl -0pi -e "s/^plugins=\(.*\)\$/${plugin_line//\//\\/}/m" "$zshrc"
  else
    printf '\n%s\n' "$plugin_line" >> "$zshrc"
  fi
}

configure_ghostty() {
  local config_dir="$HOME/.config/ghostty"
  local config_file="$config_dir/config"

  mkdir -p "$config_dir"
  if ! grep -q "# BEGIN setup_macos ghostty config" "$config_file" 2>/dev/null; then
    cat >> "$config_file" <<'EOF'
# BEGIN setup_macos ghostty config
theme = nord
font-family = "MesloLGS Nerd Font Mono"
font-size = 14
copy-on-select = clipboard
shell-integration = zsh
# END setup_macos ghostty config
EOF
  fi
}

configure_starship() {
  local config_dir="$HOME/.config"
  local starship_file="$config_dir/starship.toml"

  mkdir -p "$config_dir"
  if [ ! -f "$starship_file" ]; then
    cat > "$starship_file" <<'EOF'
add_newline = true

[character]
success_symbol = "[>](bold green)"
error_symbol = "[>](bold red)"

[directory]
truncation_length = 5
truncate_to_repo = false

[git_branch]
symbol = "git:"

[package]
disabled = true
EOF
  fi
}

configure_macos_defaults() {
  log "Applying macOS Finder/Dock defaults"
  defaults write com.apple.finder AppleShowAllFiles -bool true
  defaults write NSGlobalDomain AppleShowAllExtensions -bool true
  defaults write com.apple.finder ShowPathbar -bool true
  defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
  defaults write com.apple.dock autohide -bool true
  defaults write com.apple.dock show-recents -bool false
  killall Finder >/dev/null 2>&1 || true
  killall Dock >/dev/null 2>&1 || true
}

log "Checking Xcode Command Line Tools"
if ! xcode-select -p >/dev/null 2>&1; then
  xcode-select --install || true
  cat <<'EOF'

Xcode Command Line Tools 설치 창이 열렸습니다.
설치 완료 후 다시 `./native.sh`를 실행하세요.
EOF
  exit 0
fi

log "Refreshing sudo timestamp"
sudo -v

log "Ensuring Homebrew is installed"
if ! command -v brew >/dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
else
  echo "Homebrew not found after installation."
  exit 1
fi

ZSHRC="$HOME/.zshrc"
append_if_missing 'eval "$($(command -v brew) shellenv)"' "$ZSHRC"

log "Updating Homebrew"
brew update

log "Installing CLI packages"
brew install \
  btop \
  curl \
  eza \
  fastfetch \
  git \
  jq \
  k9s \
  kubectl \
  kubectx \
  minikube \
  node \
  starship \
  superfile \
  wget \
  zsh-autosuggestions \
  zsh-syntax-highlighting

log "Installing GUI apps"
brew install --cask \
  docker \
  font-meslo-lg-nerd-font \
  freelens \
  ghostty \
  stats \
  termius \
  visual-studio-code

log "Installing Oh My Zsh"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

mkdir -p "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"

if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
    "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
fi

if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions.git \
    "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
fi

ensure_oh_my_zsh_plugin_list "$ZSHRC"
append_if_missing 'eval "$(starship init zsh)"' "$ZSHRC"
append_if_missing 'fastfetch' "$ZSHRC"
append_if_missing "alias ls='eza --icons --git --group-directories-first'" "$ZSHRC"

configure_starship
configure_ghostty
configure_macos_defaults

log "Configuring minikube defaults"
minikube config set driver docker >/dev/null 2>&1 || true
minikube config set cpus 4 >/dev/null 2>&1 || true
minikube config set memory 8192 >/dev/null 2>&1 || true

cat <<'EOF'

macOS setup completed.

권장 후속 작업:
1. Docker Desktop을 한 번 실행해서 권한과 백그라운드 구성요소 설치를 완료
2. 새 터미널을 열거나 `source ~/.zshrc` 실행
3. 필요하면 `minikube start` 실행
EOF
