#!/usr/bin/env bash
# scripts/bootstrap.sh - Entrypoint to setup a new workspace / machine
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_DIR"

show_help() {
  cat << EOF
Usage: ./scripts/bootstrap.sh [OPTIONS]

Options:
  --all        Full bootstrap (brew + dotfiles + zsh + tmux + nvim) (default)
  --brew       Install Homebrew (if missing) and bundle Brewfile packages
  --dotfiles   Link all configuration files into place
  --zsh        Install Oh-My-Zsh & plugins
  --tmux       Install gpakosz/.tmux framework
  --nvim       Install / clone Neovim kickstart configuration
  --check      Run health check and validation
  --help       Show this help message
EOF
}

TARGET="${1:---all}"

case "$TARGET" in
  --all)
    echo "==> Running full workspace bootstrap..."
    make all
    ;;
  --brew)
    make brew
    ;;
  --dotfiles)
    make dotfiles
    ;;
  --zsh)
    make zsh
    ;;
  --tmux)
    make tmux
    ;;
  --nvim)
    make nvim
    ;;
  --check)
    make check
    ;;
  --help|-h)
    show_help
    exit 0
    ;;
  *)
    echo "Unknown option: $TARGET"
    show_help
    exit 1
    ;;
esac
