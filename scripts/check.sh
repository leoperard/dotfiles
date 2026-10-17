#!/usr/bin/env bash
# scripts/check.sh - Health check and linting for dotfiles setup
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ERRORS=0
WARNINGS=0

echo "==> Running Dotfiles Health Check"
echo ""

# 1. Check symlink integrity
echo "1. Checking symlinks..."
declare -a TARGETS=(
  ".zshrc"
  ".p10k.zsh"
  ".config/alacritty/alacritty.toml"
  ".gitconfig"
  ".gitconfig-personal"
  ".gitignore_global"
  ".tmux.conf.local"
)

for rel in "${TARGETS[@]}"; do
  file="$HOME/$rel"
  if [ -L "$file" ]; then
    target="$(readlink "$file")"
    if [ -e "$file" ]; then
      echo "  [OK] ~/$rel -> $target"
    else
      echo "  [FAIL] ~/$rel is a broken symlink (points to non-existent $target)"
      ERRORS=$((ERRORS + 1))
    fi
  elif [ -e "$file" ]; then
    echo "  [WARN] ~/$rel exists but is a regular file, not symlinked from dotfiles"
    WARNINGS=$((WARNINGS + 1))
  else
    echo "  [INFO] ~/$rel not yet linked"
  fi
done

echo ""
# 2. Secret audit
echo "2. Auditing repository for leaked tokens & secrets..."
SECRET_PATTERNS='(ghp_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{82}|gho_[A-Za-z0-9]{36}|AKIA[0-9A-Z]{16}|HOMEBREW_GITHUB_API_TOKEN=[a-f0-9]{40})'
if grep -rE --exclude-dir=.git "$SECRET_PATTERNS" "$REPO_DIR" > /dev/null 2>&1; then
  echo "  [FAIL] Potential exposed secrets detected in repository files!"
  grep -rnE --exclude-dir=.git "$SECRET_PATTERNS" "$REPO_DIR" || true
  ERRORS=$((ERRORS + 1))
else
  echo "  [OK] No leaked credentials detected in tracked files."
fi

echo ""
# 3. Check for hardcoded /Users/ usernames in tracked files (excluding markdown docs)
echo "3. Checking for non-portable hardcoded user home directories..."
if grep -rn --exclude-dir=.git --exclude='*.md' -E '/Users/[a-zA-Z0-9_-]+|/home/[a-zA-Z0-9_-]+' "$REPO_DIR" | grep -v 'binary' > /dev/null 2>&1; then
  echo "  [WARN] Found hardcoded user home paths (use \$HOME or ~ instead):"
  grep -rn --exclude-dir=.git --exclude='*.md' -E '/Users/[a-zA-Z0-9_-]+|/home/[a-zA-Z0-9_-]+' "$REPO_DIR" || true
  WARNINGS=$((WARNINGS + 1))
else
  echo "  [OK] No hardcoded user paths found in configuration files. Fully portable."
fi

echo ""
# 4. Check core binary availability
echo "4. Checking core tools..."
for cmd in zsh git tmux nvim alacritty uv; do
  if command -v "$cmd" >/dev/null 2>&1; then
    echo "  [OK] $cmd ($(command -v "$cmd"))"
  else
    echo "  [WARN] $cmd is not currently in PATH"
    WARNINGS=$((WARNINGS + 1))
  fi
done

echo ""
echo "==> Summary: $ERRORS error(s), $WARNINGS warning(s)"
if [ "$ERRORS" -gt 0 ]; then
  exit 1
fi
