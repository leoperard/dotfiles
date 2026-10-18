# Dotfiles

Modern, modular dotfiles and reproducible macOS workspace setup for Leo Perard (`leoperard`).

Supports an agent-friendly workflow with clean separation between personal and work environments.

---

## ⚡ Quick Start (New Machine Setup)

On a fresh macOS machine, clone and run the bootstrap script:

```bash
git clone https://github.com/leoperard/dotfiles.git ~/dotfiles
cd ~/dotfiles
./scripts/bootstrap.sh
```

Or run step-by-step:

```bash
# 1. Install Homebrew and CLI tools / Casks / Fonts
make brew

# 2. Symlink configuration files
make dotfiles

# 3. Setup Oh-My-Zsh plugins and Powerlevel10k theme
make zsh

# 4. Setup gpakosz/.tmux framework
make tmux

# 5. Clone Neovim kickstart configuration
make nvim

# 6. Verify everything is properly configured
make check
```

---

## 📁 Repository Layout

| Directory | Target Location | Description |
| :--- | :--- | :--- |
| **`alacritty/`** | `~/.config/alacritty/alacritty.toml` | Fast, GPU-accelerated terminal emulator |
| **`git/`** | `~/.gitconfig`, `~/.gitconfig-personal`, `~/.gitignore_global` | Global Git config with conditional work/personal identity |
| **`zsh/`** | `~/.zprofile`, `~/.zshrc`, `~/.p10k.zsh` | Oh-My-Zsh, Powerlevel10k, and workspace session launcher |
| **`tmux/`** | `~/.tmux.conf.local` | Customizations for [gpakosz/.tmux](https://github.com/gpakosz/.tmux) |
| **`vim/`** | `~/.vimrc` | Minimal fallback Vim configuration |
| **`radar/`** | `~/.local/bin/radar` | Daily-cached release radar & new tool discovery |
| **`scripts/`** | Helper scripts | `bootstrap.sh`, `link.sh`, and `check.sh` |
| **`Brewfile`** | System packages | CLI tools, fonts (Meslo Nerd Font), and GUI applications |
| **`AGENTS.md`** | Agent Guidelines | Instructions and rules for Antigravity & AI coding agents |

---

## 🔒 Secrets & Local Overrides

Private credentials, company-specific tokens, and machine-local configurations are **never tracked in git**:

* **Shell Secrets**: Placed in `~/.zshrc.local` (automatically sourced by `.zshrc` if present).
* **Work Git Identity**: Placed in `~/.gitconfig-work` (automatically included when working inside `~/workspace/work/`).
* **Work Environment**: Placed in `~/.work_env` (sourced on switching to work tmux session).

---

## 📡 Radar: Release & Tool Discovery

`radar` surfaces workflow-impacting releases of the tools you use (see `radar/watchlist.json`) and suggests curated modern tools (`radar/discover.json`).

* **Zero startup cost**: shells only read a cache file. A detached `radar refresh --if-stale` job updates it at most once every 24h.
* **Noise filter**: patch/bugfix releases are ignored. Only minor (`feature`) and major (`breaking`) bumps, or notes that declare a breaking change, are flagged.
* **Banner**: a one-line notice appears at the first prompt of a `work`/`personal` tmux session, and only when something workflow-impacting is pending.
* **Review**: run `radar` to browse summaries in `fzf` (`i` install/upgrade, `s` dismiss), or use `radar list | show <id> | install <id> | dismiss <id>`.

Set `GITHUB_TOKEN` in `~/.zshrc.local` to raise GitHub API rate limits (optional).

---

## 🛠️ Verification & Maintenance

Run the built-in health check to audit symlinks, check for accidental secret leaks, and verify tool paths:

```bash
make check
```

To see all available targets:
```bash
make help
```
