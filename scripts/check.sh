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
  ".zprofile"
  ".zshrc"
  ".p10k.zsh"
  ".config/alacritty/alacritty.toml"
  ".gitconfig"
  ".gitconfig-personal"
  ".gitignore_global"
  ".tmux.conf.local"
  ".local/bin/radar"
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
if grep -rIE --exclude-dir=.git --exclude-dir=__pycache__ "$SECRET_PATTERNS" "$REPO_DIR" > /dev/null 2>&1; then
  echo "  [FAIL] Potential exposed secrets detected in repository files!"
  grep -rnIE --exclude-dir=.git --exclude-dir=__pycache__ "$SECRET_PATTERNS" "$REPO_DIR" || true
  ERRORS=$((ERRORS + 1))
else
  echo "  [OK] No leaked credentials detected in tracked files."
fi

echo ""
# 3. Check for hardcoded /Users/ usernames in tracked files (excluding markdown docs)
echo "3. Checking for non-portable hardcoded user home directories..."
if grep -rnI --exclude-dir=.git --exclude-dir=__pycache__ --exclude='*.md' -E '/Users/[a-zA-Z0-9_-]+|/home/[a-zA-Z0-9_-]+' "$REPO_DIR" > /dev/null 2>&1; then
  echo "  [WARN] Found hardcoded user home paths (use \$HOME or ~ instead):"
  grep -rnI --exclude-dir=.git --exclude-dir=__pycache__ --exclude='*.md' -E '/Users/[a-zA-Z0-9_-]+|/home/[a-zA-Z0-9_-]+' "$REPO_DIR" || true
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
# 5. Radar data files & test suite
echo "5. Checking radar..."
if command -v python3 >/dev/null 2>&1; then
  for data in watchlist.json discover.json; do
    if python3 -m json.tool "$REPO_DIR/radar/$data" > /dev/null 2>&1; then
      echo "  [OK] radar/$data is valid JSON"
    else
      echo "  [FAIL] radar/$data is not valid JSON"
      ERRORS=$((ERRORS + 1))
    fi
  done
  if python3 -m unittest discover -s "$REPO_DIR/radar" > /dev/null 2>&1; then
    echo "  [OK] radar tests pass"
  else
    echo "  [FAIL] radar tests fail (run: python3 -m unittest discover -s radar -v)"
    ERRORS=$((ERRORS + 1))
  fi
else
  echo "  [WARN] python3 not in PATH; radar is unavailable"
  WARNINGS=$((WARNINGS + 1))
fi

echo ""
# 6. Check tmux agentic cockpit configuration & tests
echo "6. Checking tmux agentic cockpit..."
if bash "$REPO_DIR/tmux/test_tmux_cockpit.sh" > /dev/null 2>&1; then
  echo "  [OK] tmux agentic cockpit tests pass"
else
  echo "  [FAIL] tmux agentic cockpit tests failed (run: bash tmux/test_tmux_cockpit.sh)"
  ERRORS=$((ERRORS + 1))
fi

echo ""
# 7. Check workstation maintenance & skills orchestration (#2)
echo "7. Checking workstation maintenance targets..."
if bash "$REPO_DIR/scripts/test_maintenance.sh" > /dev/null 2>&1; then
  echo "  [OK] maintenance & skills tests pass"
else
  echo "  [FAIL] maintenance tests failed (run: bash scripts/test_maintenance.sh)"
  ERRORS=$((ERRORS + 1))
fi

echo ""
echo "==> Summary: $ERRORS error(s), $WARNINGS warning(s)"
if [ "$ERRORS" -gt 0 ]; then
  exit 1
fi
