# AGENTS.md - Antigravity & Agent Guidelines for Dotfiles

This repository manages personal dotfiles, terminal configuration, and reproducible workstation bootstrap for Leo Perard (`leoperard`).

---

## 1. Architecture & Mappings

Dotfile configurations live in dedicated subdirectories and are symlinked into the user's home directory by `scripts/link.sh` (or `make dotfiles`):

| Source in Repo | Target in `$HOME` | Purpose |
| :--- | :--- | :--- |
| `alacritty/alacritty.toml` | `~/.config/alacritty/alacritty.toml` | Alacritty terminal emulator settings |
| `git/.gitconfig` | `~/.gitconfig` | Global Git configuration (conditional includes) |
| `git/.gitconfig-personal` | `~/.gitconfig-personal` | Personal Git name/email identity |
| `git/.gitignore_global` | `~/.gitignore_global` | Global file ignore patterns |
| `tmux/.tmux.conf.local` | `~/.tmux.conf.local` | Customization for `gpakosz/.tmux` |
| `zsh/.zshrc` | `~/.zshrc` | Interactive Zsh configuration & dual workflow |
| `zsh/.p10k.zsh` | `~/.p10k.zsh` | Powerlevel10k theme configuration |
| `vim/.vimrc` | `~/.vimrc` | Minimal fallback Vim configuration |

### Dependencies & External Components
* **Neovim**: Neovim configuration is tracked in a dedicated repository (`leoperard/kickstart.nvim`) and managed via `make nvim` into `~/.config/nvim`.
* **Homebrew**: Declarative packages and GUI apps are managed via `Brewfile` (`make brew`).
* **Tmux Framework**: Uses `gpakosz/.tmux` cloned to `~/.tmux` (`make tmux`).

---

## 2. Dual Workflow & Agent Guardrails

The workspace separates **Work** and **Personal** environments:
* **Personal (`~/workspace/personal`)**: Uses Antigravity (`agy`), personal GitHub identity, and personal API tokens.
* **Work (`~/workspace/work`)**: Uses Claude Code, enterprise GitLab, and work credentials (`~/.work_env`, `~/.gitconfig-work`).

### Critical Safety Invariants
1. **Never commit secrets**:
   * Do not place tokens (GitHub PATs, AWS keys, etc.) in `zsh/.zshrc` or any tracked file.
   * Machine-local tokens and secrets must go into `~/.zshrc.local` (sourced automatically by `.zshrc`).
   * Work credentials belong in `~/.work_env` or `~/.gitconfig-work`.
2. **Portable Paths**:
   * Never hardcode `/Users/lperard` or `/Users/<username>`. Always use `$HOME` or `~`.
3. **Non-Interactive & Agent Compatibility**:
   * The interactive session picker in `.zshrc` MUST remain guarded by:
     `[[ -o interactive ]] && [[ -t 0 ]] && [[ -z "$TMUX" ]] && [[ -z "$ANTIGRAVITY_SHELL" ]] && [[ -z "$VSCODE_INJECTION" ]] && [[ -z "$CI" ]]`
   * Never introduce blocking prompts (`read`, interactive confirmations) that execute in background subshells or agent sessions.
4. **Idempotence**:
   * Any new setup command or target in `Makefile` must be safely re-runnable without failing if the directory or link already exists.

---

## 3. How to Make and Verify Changes

### Testing Changes
Whenever you modify files in this repository, run:
```bash
make check
```
This script audits:
* Symlink health (checks for dead or broken links)
* Secret scanning (ensures no tokens were accidentally added)
* Portability (checks for hardcoded user paths)
* Availability of core CLI tools

### Applying Dotfiles
To test symlinking non-destructively:
```bash
./scripts/link.sh --dry-run
```
To apply symlinks:
```bash
make dotfiles
```

### Adding a New Configuration
1. Place the config file in a descriptive folder (e.g., `tool/config.file`).
2. Add the mapping to `scripts/link.sh` in the `MAPPINGS` array (`"tool/config.file:.config/tool/config.file"`).
3. If the tool requires a brew package, add it to `Brewfile`.
4. Run `make dotfiles` and `make check`.
