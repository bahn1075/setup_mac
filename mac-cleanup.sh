#!/usr/bin/env bash

################################################################################
# System Cleanup Script for macOS
# Description: Clean caches, logs, and development artifacts to free disk space
# Updated: 2026-04-15
################################################################################

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_success() {
  echo -e "${GREEN}✓${NC} $1"
}

print_info() {
  echo -e "${YELLOW}→${NC} $1"
}

print_error() {
  echo -e "${RED}✗${NC} $1"
}

if [ "${EUID}" -ne 0 ]; then
  print_error "This script requires sudo. Run: sudo ./ubuntu-cleanup.sh"
  exit 1
fi

TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME="$(dscl . -read "/Users/${TARGET_USER}" NFSHomeDirectory | awk '{print $2}')"

if [ -z "${TARGET_HOME:-}" ] || [ ! -d "$TARGET_HOME" ]; then
  print_error "Could not determine target home directory for user: $TARGET_USER"
  exit 1
fi

echo "================================"
echo "System Cleanup Script Started"
echo "Target user: $TARGET_USER"
echo "Target home: $TARGET_HOME"
echo "================================"
echo ""

echo "Initial disk usage:"
df -h /
echo ""

print_info "Cleaning Homebrew cache..."
if command -v brew >/dev/null 2>&1; then
  sudo -u "$TARGET_USER" brew cleanup -s || true
  sudo -u "$TARGET_USER" rm -rf "$TARGET_HOME/Library/Caches/Homebrew" 2>/dev/null || true
  print_success "Homebrew cache cleaned"
  echo ""
fi

print_info "Cleaning npm cache..."
if command -v npm >/dev/null 2>&1; then
  sudo -u "$TARGET_USER" npm cache clean --force >/dev/null 2>&1 || true
  rm -rf "$TARGET_HOME/.npm" 2>/dev/null || true
  print_success "npm cache cleaned"
  echo ""
fi

print_info "Cleaning Python and developer caches..."
rm -rf \
  "$TARGET_HOME/.cache/pip" \
  "$TARGET_HOME/.cache/uv" \
  "$TARGET_HOME/.cache/helm" \
  "$TARGET_HOME/.gradle/caches" \
  "$TARGET_HOME/.m2/repository/.cache" \
  "$TARGET_HOME/.yarn/cache" \
  "$TARGET_HOME/.pnpm-store" \
  "$TARGET_HOME/.minikube/cache" \
  "$TARGET_HOME/.cache/pre-commit" \
  2>/dev/null || true
print_success "Developer caches cleaned"
echo ""

print_info "Cleaning macOS user caches..."
rm -rf \
  "$TARGET_HOME/Library/Caches/"* \
  "$TARGET_HOME/Library/Logs/"* \
  "$TARGET_HOME/Library/Developer/Xcode/DerivedData/"* \
  "$TARGET_HOME/Library/Developer/Xcode/Archives/"* \
  "$TARGET_HOME/Library/Developer/CoreSimulator/Caches/"* \
  "$TARGET_HOME/Library/Developer/CoreSimulator/Devices/"*/data/Library/Caches/* \
  2>/dev/null || true
print_success "macOS user caches cleaned"
echo ""

print_info "Cleaning browser and editor caches..."
rm -rf \
  "$TARGET_HOME/Library/Application Support/Code/Cache" \
  "$TARGET_HOME/Library/Application Support/Code/CachedData" \
  "$TARGET_HOME/Library/Application Support/Code/Service Worker/CacheStorage" \
  "$TARGET_HOME/Library/Application Support/Google/Chrome/Default/Code Cache" \
  "$TARGET_HOME/Library/Application Support/Google/Chrome/Default/Cache" \
  "$TARGET_HOME/Library/Application Support/Microsoft Edge/Default/Code Cache" \
  "$TARGET_HOME/Library/Application Support/Microsoft Edge/Default/Cache" \
  "$TARGET_HOME/Library/Application Support/Slack/Cache" \
  "$TARGET_HOME/Library/Application Support/Slack/Code Cache" \
  2>/dev/null || true
print_success "Browser and editor caches cleaned"
echo ""

print_info "Cleaning zsh temporary files..."
rm -f "$TARGET_HOME"/.zcompdump* "$TARGET_HOME"/*.backup 2>/dev/null || true
print_success "zsh temporary files cleaned"
echo ""

print_info "Emptying Trash..."
rm -rf \
  "$TARGET_HOME/.Trash/"* \
  "/private/var/log/asl/"* \
  2>/dev/null || true
print_success "Trash emptied"
echo ""

print_info "Cleaning Docker artifacts..."
if command -v docker >/dev/null 2>&1; then
  sudo -u "$TARGET_USER" docker system prune -af --volumes >/dev/null 2>&1 || true
  print_success "Docker artifacts cleaned"
  echo ""
fi

print_info "Removing stale temporary files..."
find /tmp -type f -mtime +7 -delete 2>/dev/null || true
find /private/var/tmp -type f -mtime +7 -delete 2>/dev/null || true
print_success "Temporary files cleaned"
echo ""

echo "Final disk usage:"
df -h /
echo ""

echo "Major directory usage:"
du -sh \
  "$TARGET_HOME/Library" \
  "$TARGET_HOME/Applications" \
  /Applications \
  /Library \
  /private/var \
  2>/dev/null | sort -h
echo ""

echo "================================"
print_success "System cleanup completed"
echo "================================"
