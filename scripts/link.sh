#!/usr/bin/env bash
# scripts/link.sh - Idempotent, safe symlink manager for dotfiles
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DRY_RUN=false
BACKUP_SUFFIX=".bak.$(date +%Y%m%d%H%M%S)"

for arg in "$@"; do
  case "$arg" in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
  esac
done

# Define source -> destination mappings (relative to REPO_DIR -> relative to HOME)
declare -a MAPPINGS=(
  "zsh/.zprofile:.zprofile"
  "zsh/.zshrc:.zshrc"
  "zsh/.p10k.zsh:.p10k.zsh"
  "alacritty/alacritty.toml:.config/alacritty/alacritty.toml"
  "git/.gitconfig:.gitconfig"
  "git/.gitconfig-personal:.gitconfig-personal"
  "git/.gitignore_global:.gitignore_global"
  "tmux/.tmux.conf.local:.tmux.conf.local"
  "vim/.vimrc:.vimrc"
  "radar/radar.py:.local/bin/radar"
)

echo "==> Linking dotfiles (REPO: $REPO_DIR)"

for mapping in "${MAPPINGS[@]}"; do
  src_rel="${mapping%%:*}"
  dst_rel="${mapping##*:}"

  src="$REPO_DIR/$src_rel"
  dst="$HOME/$dst_rel"

  if [ ! -e "$src" ]; then
    echo "  [WARN] Source file does not exist: $src"
    continue
  fi

  # Ensure destination directory exists
  dst_dir="$(dirname "$dst")"
  if [ ! -d "$dst_dir" ]; then
    if [ "$DRY_RUN" = true ]; then
      echo "  [DRY-RUN] mkdir -p $dst_dir"
    else
      mkdir -p "$dst_dir"
    fi
  fi

  # Check existing destination
  if [ -L "$dst" ]; then
    current_target="$(readlink "$dst")"
    if [ "$current_target" = "$src" ]; then
      echo "  [OK] $dst_rel -> already linked to $src_rel"
      continue
    else
      echo "  [UPDATE] $dst_rel was pointing to $current_target"
    fi
  elif [ -e "$dst" ]; then
    echo "  [BACKUP] $dst exists and is not a symlink. Backing up to ${dst}${BACKUP_SUFFIX}"
    if [ "$DRY_RUN" = false ]; then
      mv "$dst" "${dst}${BACKUP_SUFFIX}"
    fi
  fi

  if [ "$DRY_RUN" = true ]; then
    echo "  [DRY-RUN] ln -sf $src $dst"
  else
    ln -sf "$src" "$dst"
    echo "  [LINKED] $dst_rel -> $src_rel"
  fi
done

echo "==> Dotfile linking complete."
