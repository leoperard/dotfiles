# Makefile for dotfiles orchestration
SHELL := /bin/bash
REPO_DIR := $(shell pwd)
ZSH_CUSTOM ?= $(HOME)/.oh-my-zsh/custom

.PHONY: help all dotfiles brew zsh tmux nvim check clean

help:
	@echo "Available targets:"
	@echo "  make dotfiles   - Safely link all config files (Alacritty, Git, Zsh, Tmux)"
	@echo "  make brew       - Install Homebrew (if missing) and bundle Brewfile"
	@echo "  make zsh        - Install Oh-My-Zsh, plugins, and Powerlevel10k idempotently"
	@echo "  make tmux       - Install and configure gpakosz/.tmux framework"
	@echo "  make nvim       - Clone / update kickstart.nvim configuration"
	@echo "  make check      - Run health checks, symlink audits, and secret scanning"
	@echo "  make all        - Run complete workspace setup in sequence"

dotfiles:
	@./scripts/link.sh

brew:
	@echo "==> Setting up Homebrew packages..."
	@if ! command -v brew >/dev/null 2>&1; then \
		echo "Installing Homebrew..."; \
		NONINTERACTIVE=1 /bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
		if [ -d "/opt/homebrew/bin" ]; then eval "$$(/opt/homebrew/bin/brew shellenv)"; fi; \
	fi
	@brew bundle --file="$(REPO_DIR)/Brewfile"

zsh: dotfiles
	@echo "==> Setting up Zsh environment..."
	@if [ ! -d "$(HOME)/.oh-my-zsh" ]; then \
		echo "Installing Oh-My-Zsh..."; \
		RUNZSH=no CHSH=no sh -c "$$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; \
	else \
		echo "Oh-My-Zsh already installed."; \
	fi
	@mkdir -p "$(ZSH_CUSTOM)/plugins" "$(ZSH_CUSTOM)/themes"
	@if [ ! -d "$(ZSH_CUSTOM)/plugins/zsh-syntax-highlighting" ]; then \
		git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$(ZSH_CUSTOM)/plugins/zsh-syntax-highlighting"; \
	else \
		git -C "$(ZSH_CUSTOM)/plugins/zsh-syntax-highlighting" pull --quiet || true; \
	fi
	@if [ ! -d "$(ZSH_CUSTOM)/plugins/zsh-autosuggestions" ]; then \
		git clone https://github.com/zsh-users/zsh-autosuggestions "$(ZSH_CUSTOM)/plugins/zsh-autosuggestions"; \
	else \
		git -C "$(ZSH_CUSTOM)/plugins/zsh-autosuggestions" pull --quiet || true; \
	fi
	@if [ ! -d "$(ZSH_CUSTOM)/themes/powerlevel10k" ]; then \
		git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$(ZSH_CUSTOM)/themes/powerlevel10k"; \
	else \
		git -C "$(ZSH_CUSTOM)/themes/powerlevel10k" pull --quiet || true; \
	fi

tmux: dotfiles
	@echo "==> Setting up Tmux environment..."
	@if [ ! -d "$(HOME)/.tmux" ]; then \
		git clone https://github.com/gpakosz/.tmux.git "$(HOME)/.tmux"; \
	else \
		git -C "$(HOME)/.tmux" pull --quiet || true; \
	fi
	@ln -sf "$(HOME)/.tmux/.tmux.conf" "$(HOME)/.tmux.conf"

nvim:
	@echo "==> Setting up Neovim configuration..."
	@if [ ! -d "$(HOME)/.config/nvim" ]; then \
		git clone https://github.com/leoperard/kickstart.nvim.git "$(HOME)/.config/nvim"; \
	else \
		echo "Updating kickstart.nvim..."; \
		git -C "$(HOME)/.config/nvim" pull --quiet || true; \
	fi

check:
	@./scripts/check.sh

all: brew dotfiles zsh tmux nvim check
	@echo "==> All dotfiles and dependencies successfully set up!"
