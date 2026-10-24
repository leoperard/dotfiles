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

## 🎨 Unified Desert Theme

The workstation is uniformly styled with Hans Fugal's classic Vim **Desert** color palette, providing an earth-toned, cohesive, and distraction-free visual experience across all terminal tooling:

* **Alacritty**: Charcoal background (`#333333`), crisp white text (`#ffffff`), Khaki cursor (`#f0e68c`), OliveDrab selection (`#6b8e23`), and Peru search matches (`#cd853f`).
* **Neovim / Vim**: Native `colorscheme desert` with transparent background (`guibg=NONE`) for zero visual boundary between editor and terminal.
* **Tmux & Cockpit**: Charcoal status line (`#333333`), Khaki pane accents (`#f0e68c`), earth-tone battery gradient (PaleGreen → Khaki → IndianRed), and rounded Desert-themed floating agent popup (`prefix + a`).
* **Zsh & Powerlevel10k**: Desert SkyBlue (`117`) and Tan (`144`) directory paths, PaleGreen (`120`) clean prompt & git indicators, and Khaki (`186`) modified status.
* **CLI Tools (`bat` & `fzf`)**: `bat` configured with `BAT_THEME="ansi"` to inherit Desert syntax highlighting; `fzf` configured with charcoal backgrounds and khaki/salmon highlights.

---

## 🐚 Shell Plugins & Modern Tooling

The Zsh configuration in `zsh/.zshrc` is optimized for instantaneous launch speeds (~45ms) and includes curated plugins and modern CLI tools:

* **Directory Navigation**: `zoxide` (`z <dir>` / `zi`, with `j` alias for autojump compatibility)
* **Environment Automation**: `direnv` (`.envrc` / `.env` loaded on entry, unloaded on `cd ..`)
* **Node Version Management**: `fnm` (Fast Node Manager in Rust, sub-millisecond `.nvmrc` auto-switch)
* **Python Environments**: `uv` and `virtualenvwrapper` (`workon`, `mkvirtualenv`)
* **File Viewer & Pager**: `bat` (syntax-highlighted cat and colorized man pager)
* **Git & Cloud**: `git`, `gitignore`, `docker` (`dc`), `kubectl` (`k`), `kubectx`, `terraform` (`tf`), `gcloud`, `minikube`, `vault`
* **Interactive UX**: `history-substring-search` (Up/Down prefix matching), `zsh-autosuggestions`, `zsh-syntax-highlighting`, `sudo` (double-Esc)

📖 See **[docs/SHELL_PLUGINS.md](docs/SHELL_PLUGINS.md)** for a complete reference of every active plugin, alias, and command.

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

Keep your entire workstation up-to-date and clean:
```bash
make update   # Updates Homebrew, Oh-My-Zsh plugins, tmux, kickstart.nvim, and runs make check
make skills   # Installs / updates community agent skills in ~/.agents/skills via @mattpocock/skills
```

Run the built-in health check to audit symlinks, check for accidental secret leaks, and verify tool paths:

```bash
make check
```

To see all available targets:
```bash
make help
```
