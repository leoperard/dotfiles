# Shell Plugins & Modern Tooling Guide

This document catalogs every active plugin and modern CLI tool configured in `zsh/.zshrc`. It provides a quick explanation of what each tool does and the most useful commands, aliases, and keybindings to use in your daily workflow.

---

## ⚡ Modern Drop-in CLI Tools

These modern Rust and Go utilities replace legacy shell plugins with sub-millisecond execution times and zero startup overhead.

### 1. `zoxide` (Directory Navigation)
* **What it does:** Smarter, faster directory jumper (`cd` replacement) powered by Rust. Learns which directories you visit most frequently and jumps to them matching any keyword substring.
* **How to use it:**
  * `z <dir>`: Jump to the best match (e.g., `z work`, `z dotfiles`).
  * `j <dir>`: Aliased to `z` for muscle-memory compatibility with `autojump` (e.g., `j dotfiles`).
  * `zi` / `ji`: Interactive selection using `fzf` fuzzy finder.

### 2. `direnv` (Per-Directory Environment Loader)
* **What it does:** Automatically loads environment variables when entering a directory with an `.envrc` or `.env` file, and safely unloads them as soon as you `cd ..` or leave the folder.
* **How to use it:**
  * Create an `.envrc` file: `echo 'export MY_VAR="value"' > .envrc`
  * Allow it: `direnv allow` (cryptographic security check).
  * Load standard `.env` files in `.envrc` simply by adding: `dotenv`

### 3. `fnm` (Fast Node Manager)
* **What it does:** Ultra-fast Node.js version manager written in Rust (~100x faster startup than `nvm`). Automatically switches Node versions based on `.nvmrc` or `.node-version`.
* **How to use it:**
  * `fnm install 20`: Install Node.js 20.
  * `fnm use 20`: Switch to Node.js 20 for current session.
  * `fnm default 20`: Set the global default version.
  * `fnm list`: List installed versions.

### 4. `bat` (Syntax-Highlighting File Viewer & Pager)
* **What it does:** Modern `cat` replacement with syntax highlighting, line numbers, and Git modification indicators in the gutter. Also serves as the default `MANPAGER`.
* **How to use it:**
  * `bat file.py`: View a file with syntax colors and git diff indicators.
  * `man zsh`: View man pages with colorized flags and sections.

### 5. `uv` (Ultra-Fast Python Package & Virtualenv Manager)
* **What it does:** Single-binary Python package manager written in Rust, replacing pip, virtualenv, and pip-tools with 10–100x speedups.
* **How to use it:**
  * `uv venv`: Create a virtual environment in `.venv` instantly (<20ms).
  * `uv pip install <pkg>`: Install packages from PyPI with local caching.
  * `uv pip compile requirements.in -o requirements.txt`: Lock dependencies.

### 6. `thefuck` (Lazy-Loaded Typo Corrector)
* **What it does:** Corrects mistyped console commands by suggesting or executing fixes when you type `fuck`.
* **How to use it:**
  * Mistype a command (e.g., `puthon` or forgetting `sudo`).
  * Type `fuck` and hit Enter to confirm the corrected command.
  * *Note: Configured with a lazy-loading stub so it does not slow down shell startup.*

---

## 🧰 Core Productivity & System Utilities

### `sudo`
* **What it does:** Quick shortcut to prepend `sudo` to the current or last command.
* **How to use it:** Press `Esc` twice (`Esc Esc`). If the command line is empty, it recalls the previous command with `sudo `. If text is already entered, it prepends `sudo `.

### `extract`
* **What it does:** Universal archive extractor that detects archive format by file extension and executes the appropriate tool (`tar`, `unzip`, `unrar`, `7z`, etc.).
* **How to use it:**
  * `x archive.tar.gz` or `extract archive.zip`

### `copypath`
* **What it does:** Copies the absolute or relative file/directory path to the macOS clipboard (`pbcopy`).
* **How to use it:**
  * `copypath`: Copies current directory path.
  * `copypath file.txt`: Copies the absolute path of `file.txt`.

### `cp`
* **What it does:** Provides `cpv`, a safe copy wrapper that uses `rsync` with a live visual progress bar.
* **How to use it:**
  * `cpv large-file.iso /Volumes/Backup/`

### `macos`
* **What it does:** Bridges terminal commands with native macOS desktop and Finder features.
* **How to use it:**
  * `trash <file>`: Safely moves a file to the macOS Trash instead of permanently deleting.
  * `cdf`: Changes shell directory to the currently frontmost Finder window.
  * `pfd`: Prints the path of the frontmost Finder window.
  * `pfs`: Prints current selection in Finder.
  * `quick-look <file>` (or `ql`): Launches macOS QuickLook preview from the terminal.

### `brew`
* **What it does:** Useful aliases for Homebrew maintenance and package inspection.
* **How to use it:**
  * `bubu`: `brew update && brew upgrade`
  * `bcl`: `brew cleanup`
  * `bcsc`: `brew cask clean`
  * `bubo`: `brew update && brew outdated`

### `common-aliases`
* **What it does:** Common standard shortcuts for unix commands.
* **How to use it:**
  * `l`: `ls -lFh` (human-readable file listing)
  * `la`: `ls -lAFh` (listing including hidden files)
  * `ll`: `ls -l`
  * `grep`: Aliased with color options (`grep --color=auto`)

---

## 🐙 Git

### `git`
* **What it does:** Comprehensive library of Git aliases for fast version control operations.
* **How to use it (frequent shortcuts):**
  * `gst`: `git status`
  * `ga`: `git add`
  * `gaa`: `git add --all`
  * `gc`: `git commit -v`
  * `gc!`: `git commit -v --amend`
  * `gcm`: `git commit -m`
  * `gco`: `git checkout`
  * `gcb`: `git checkout -b`
  * `gd`: `git diff`
  * `gl`: `git pull`
  * `gp`: `git push`
  * `glog`: Clean colorized commit log graph

### `gitignore`
* **What it does:** Queries the [gitignore.io](https://gitignore.io) API directly from the command line to generate ready-to-use `.gitignore` templates.
* **How to use it:**
  * `gi python,macos,visualstudiocode >> .gitignore`
  * `gi list`: Search available template keywords.

---

## ☁️ Cloud & Containers

### `docker`
* **What it does:** Tab completions and practical aliases for Docker container management.
* **How to use it:**
  * `dps`: `docker ps`
  * `drun`: `docker run`
  * `dexec`: `docker exec -it`
  * `dstop`: `docker stop`
  * `dc`: `docker compose` (configured in `.zshrc`)

### `kubectl`
* **What it does:** Asynchronously cached completions and standard Kubernetes shortcuts.
* **How to use it:**
  * `k`: `kubectl`
  * `kgp`: `kubectl get pods`
  * `kgpa`: `kubectl get pods --all-namespaces`
  * `kdel`: `kubectl delete`
  * `keti`: `kubectl exec -t -i` (drop into pod terminal)
  * `kl`: `kubectl logs`
  * `klf`: `kubectl logs -f` (follow logs)
  * `kaf`: `kubectl apply -f`

### `kubectx`
* **What it does:** Completions and integration for fast switching between Kubernetes clusters and namespaces.
* **How to use it:**
  * `kubectx`: Interactive context switcher (or `kubectx <name>`).
  * `kubens`: Interactive namespace switcher (or `kubens <name>`).

### `terraform`
* **What it does:** Fast shortcuts for Terraform commands.
* **How to use it:**
  * `tf`: `terraform`
  * `tfa`: `terraform apply`
  * `tfp`: `terraform plan`
  * `tfi`: `terraform init`
  * `tfo`: `terraform output`

### `gcloud`
* **What it does:** Automates Google Cloud SDK environment paths and tab-completion loading without redundant startup scans.
* **How to use it:** Use standard `gcloud` commands with full argument completion (e.g., `gcloud compute instances list`).

### `minikube`
* **What it does:** Completions and convenience aliases for local Minikube Kubernetes development.
* **How to use it:**
  * `minikube start`
  * `minikube status`
  * `minikube dashboard`

### `vault`
* **What it does:** Completions and helpers for HashiCorp Vault secrets management.
* **How to use it:** Standard `vault` commands with tab completions for secret paths, auth methods, and engine types.

---

## 🐍 Runtimes & Package Managers

### `virtualenvwrapper`
* **What it does:** Manages isolated Python virtual environments centrally under `~/.virtualenvs`.
* **How to use it:**
  * `mkvirtualenv <envname>`: Create a new virtualenv.
  * `workon <envname>`: Activate an existing virtualenv.
  * `deactivate`: Exit the active virtualenv.
  * `rmvirtualenv <envname>`: Delete a virtualenv.
  * `lsvirtualenv`: List all available virtualenvs.

### `pip`
* **What it does:** Auto-completion for `pip` commands and flags, plus cache shortcuts.
* **How to use it:**
  * `pip install <package>` (with tab-completion for subcommands and options).

### `npm`
* **What it does:** Shortcuts and tab completions for Node's package manager.
* **How to use it:**
  * `npm-i`: `npm install`
  * `npm-exec`: Execute local package binaries.

### `rust`
* **What it does:** Autocompletions for Rust toolchains (`rustc`, `cargo`, and related tooling).
* **How to use it:** Full tab completion when running `cargo build`, `cargo test`, `cargo run`.

---

## 🖥️ Interactive UX & Line Editing

### `history-substring-search`
* **What it does:** Lets you type any part of a past command and press `Up` or `Down` arrow keys to cycle through matching history entries.
* **How to use it:** Type `docker` or `git` and press `Up` arrow to recall past commands matching that prefix.

### `zsh-autosuggestions`
* **What it does:** Fish-style ghost text autosuggestions appearing dynamically as you type, predicted based on your shell history.
* **How to use it:** Press `Right Arrow` (`→`) or `End` to accept the dimmed suggestion.

### `zsh-syntax-highlighting`
* **What it does:** Real-time syntax coloring on the command line buffer while typing.
* **How to use it:** Visual feedback is automatic:
  * Green: Valid command or valid file path.
  * Red: Invalid command, syntax error, or non-existent file.
