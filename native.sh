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

ensure_zsh_theme_disabled() {
  local zshrc="$1"

  touch "$zshrc"
  # starship이 프롬프트를 대체하므로 OMZ 테마 비활성화 필수
  if grep -q '^ZSH_THEME=' "$zshrc"; then
    perl -pi -e 's/^ZSH_THEME=.*/ZSH_THEME=""/' "$zshrc"
  else
    printf '\nZSH_THEME=""\n' >> "$zshrc"
  fi
}

ensure_omz_sourced() {
  local zshrc="$1"

  touch "$zshrc"
  # KEEP_ZSHRC=yes 로 설치 시 .zshrc가 없으면 source 라인이 빠질 수 있음
  if ! grep -q 'oh-my-zsh.sh' "$zshrc"; then
    printf '\nexport ZSH="$HOME/.oh-my-zsh"\nsource "$ZSH/oh-my-zsh.sh"\n' >> "$zshrc"
  fi
}

configure_zsh_options() {
  local zshrc="$1"

  grep -q '# BEGIN zsh options' "$zshrc" 2>/dev/null && return

  cat >> "$zshrc" <<'EOF'

# BEGIN zsh options
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY
setopt HIST_VERIFY
setopt AUTO_CD
setopt CORRECT
setopt EXTENDED_GLOB
setopt NO_BEEP
# END zsh options
EOF
}

configure_zsh_aliases() {
  local zshrc="$1"

  grep -q '# BEGIN zsh aliases' "$zshrc" 2>/dev/null && return

  cat >> "$zshrc" <<'EOF'

# BEGIN zsh aliases
alias ls='eza --icons --git --group-directories-first'
alias ll='eza -lah --icons --git --group-directories-first'
alias la='eza -a --icons --git --group-directories-first'
alias lt='eza --tree --icons --git --group-directories-first'
alias grep='grep --color=auto'
alias diff='diff --color=auto'
alias cp='cp -iv'
alias mv='mv -iv'
alias mkdir='mkdir -pv'
alias k='kubectl'
alias kx='kubectx'
alias kn='kubens'
alias g='git'
alias glog='git log --oneline --graph --decorate --all'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias reload='source ~/.zshrc'
alias path='echo $PATH | tr ":" "\n"'
# END zsh aliases
EOF
}

configure_zsh_autosuggestions() {
  local zshrc="$1"

  grep -q '# BEGIN zsh-autosuggestions config' "$zshrc" 2>/dev/null && return

  cat >> "$zshrc" <<'EOF'

# BEGIN zsh-autosuggestions config
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#6b7280'
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=50
bindkey '^ ' autosuggest-accept
# END zsh-autosuggestions config
EOF
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
  [ -f "$starship_file" ] && return

  cat > "$starship_file" <<'EOF'
"$schema" = 'https://starship.rs/config-schema.json'
add_newline = true
command_timeout = 500

format = """
$os\
$directory\
$git_branch\
$git_status\
$git_state\
$kubernetes\
$docker_context\
$python\
$nodejs\
$golang\
$rust\
$cmd_duration\
$line_break\
$character"""

[os]
disabled = false
style = "bold blue"

[os.symbols]
Macos = " "

[directory]
truncation_length = 5
truncate_to_repo = false
style = "bold cyan"
read_only = " 󰌾"
format = "[$path]($style)[$read_only]($read_only_style) "

[git_branch]
symbol = " "
style = "bold purple"
format = "[$symbol$branch(:$remote_branch)]($style) "

[git_status]
format = '([\[$all_status$ahead_behind\]]($style) )'
style = "bold yellow"
ahead = "⇡${count}"
behind = "⇣${count}"
diverged = "⇕⇡${ahead_count}⇣${behind_count}"
untracked = "?${count}"
modified = "!${count}"
staged = "+${count}"
deleted = "✘${count}"
stashed = "≡"

[git_state]
format = '\([$state( $progress_current/$progress_total)]($style)\) '
style = "bold yellow"

[kubernetes]
disabled = false
symbol = "☸ "
style = "bold blue"
format = '[$symbol$context( \($namespace\))]($style) '

[docker_context]
symbol = " "
style = "bold blue"
format = '[$symbol$context]($style) '
only_with_files = true

[python]
symbol = " "
style = "bold yellow"
format = '[$symbol$version( \($virtualenv\))]($style) '

[nodejs]
symbol = " "
style = "bold green"
format = '[$symbol$version]($style) '

[golang]
symbol = " "
style = "bold cyan"
format = '[$symbol$version]($style) '

[rust]
symbol = " "
style = "bold red"
format = '[$symbol$version]($style) '

[cmd_duration]
min_time = 2000
format = "[⏱ $duration]($style) "
style = "bold yellow"

[package]
disabled = true

[character]
success_symbol = "[❯](bold green)"
error_symbol = "[❯](bold red)"
vimcmd_symbol = "[❮](bold green)"
EOF
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

ensure_omz_sourced "$ZSHRC"
ensure_zsh_theme_disabled "$ZSHRC"
ensure_oh_my_zsh_plugin_list "$ZSHRC"
configure_zsh_options "$ZSHRC"
configure_zsh_aliases "$ZSHRC"
configure_zsh_autosuggestions "$ZSHRC"
append_if_missing 'eval "$(starship init zsh)"' "$ZSHRC"
append_if_missing 'fastfetch' "$ZSHRC"

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
