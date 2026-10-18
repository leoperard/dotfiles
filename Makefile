# Makefile for dotfiles orchestration
SHELL := /bin/bash
REPO_DIR := $(shell pwd)
ZSH_CUSTOM ?= $(HOME)/.oh-my-zsh/custom

.PHONY: help all dotfiles brew alacritty zsh tmux nvim check clean update skills

help:
	@echo "Available targets:"
	@echo "  make dotfiles   - Safely link all config files (Alacritty, Git, Zsh, Tmux)"
	@echo "  make brew       - Install Homebrew (if missing) and bundle Brewfile"
	@echo "  make alacritty  - Install or update Alacritty directly from GitHub releases"
	@echo "  make zsh        - Install Oh-My-Zsh, plugins, and Powerlevel10k idempotently"
	@echo "  make tmux       - Install and configure gpakosz/.tmux framework"
	@echo "  make nvim       - Clone / update kickstart.nvim configuration"
	@echo "  make update     - Update Homebrew, Oh-My-Zsh plugins, tmux, nvim, and run check"
	@echo "  make skills     - Install / update community agent skills via @mattpocock/skills"
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

alacritty:
	@echo "==> Setting up Alacritty terminal..."
	@./scripts/install_alacritty.sh

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

update:
	@echo "==> Updating Homebrew packages and casks..."
	@if command -v brew >/dev/null 2>&1; then \
		brew update && brew upgrade && brew cleanup; \
	fi
	@echo "==> Updating Oh-My-Zsh and custom plugins..."
	@for dir in "$(HOME)/.oh-my-zsh" \
		"$(ZSH_CUSTOM)/plugins/zsh-syntax-highlighting" \
		"$(ZSH_CUSTOM)/plugins/zsh-autosuggestions" \
		"$(ZSH_CUSTOM)/themes/powerlevel10k"; do \
		if [ -d "$$dir" ]; then \
			git -C "$$dir" pull --quiet || echo "  [WARN] Failed to pull $$dir"; \
		fi; \
	done
	@echo "==> Updating gpakosz/.tmux..."
	@if [ -d "$(HOME)/.tmux" ]; then \
		git -C "$(HOME)/.tmux" pull --quiet || echo "  [WARN] Failed to pull ~/.tmux"; \
	fi
	@echo "==> Updating kickstart.nvim..."
	@if [ -d "$(HOME)/.config/nvim" ]; then \
		git -C "$(HOME)/.config/nvim" pull --quiet || echo "  [WARN] Failed to pull ~/.config/nvim"; \
	fi
	@echo "==> Verifying workstation health..."
	@$(MAKE) check

skills:
	@echo "==> Installing / updating community agent skills via @mattpocock/skills..."
	@mkdir -p "$(HOME)/.agents/skills"
	@if command -v npx >/dev/null 2>&1; then \
		npx --yes skills@latest add mattpocock/skills -g -y; \
	else \
		echo "Error: npx is required to install/update agent skills." >&2; \
		exit 1; \
	fi

check:
	@./scripts/check.sh

all: brew alacritty dotfiles zsh tmux nvim check
	@echo "==> All dotfiles and dependencies successfully set up!"
