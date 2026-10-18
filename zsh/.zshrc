# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.

# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block, everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block, everything else may go below.
# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="powerlevel10k/powerlevel10k"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
HIST_STAMPS="dd/mm/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
ZSH_CUSTOM=~/.oh-my-zsh-custom

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
    # Essential Utilities & Productivity
    brew
    common-aliases
    copypath
    cp
    extract
    macos
    sudo

    # Git
    git
    gitignore

    # Cloud & Containers
    docker
    kubectl
    kubectx
    terraform
    gcloud
    minikube
    vault

    # Languages & Runtimes
    npm
    rust
    pip
    virtualenvwrapper

    # Interactive UX & Line Editing
    history-substring-search
    zsh-autosuggestions
    zsh-syntax-highlighting
)

# User configuration
export PATH="/opt/homebrew/bin:$PATH"
export PATH="$PATH:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/X11/bin"
# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
alias vi="nvim"
alias vim="nvim"
export EDITOR='vim'
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/dsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

ENABLE_CORRECTION=true
ZSH_DISABLE_COMPFIX=true

# Tmux configuration (handled by custom workspace session launcher)
ZSH_TMUX_AUTOSTART=false
ZSH_TMUX_AUTOSTART_ONCE=false
ZSH_TMUX_AUTOCONNECT=false
ZSH_TMUX_AUTOQUIT=false

# Machine-specific tokens (e.g. HOMEBREW_GITHUB_API_TOKEN) belong in ~/.zshrc.local

# virtualenvwrapper configuration (must be exported before oh-my-zsh loads plugin)
export WORKON_HOME=$HOME/.virtualenvs

source $ZSH/oh-my-zsh.sh

# Modern CLI Tools & Replacements
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
  alias j=z
  alias ji=zi
fi

if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi

if command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env --use-on-cd)"
fi

if command -v bat >/dev/null 2>&1; then
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
fi

if command -v thefuck >/dev/null 2>&1; then
  fuck() {
    unfunction fuck
    eval $(thefuck --alias)
    fuck "$@"
  }
fi

alias dc="docker compose"

# Docker configuration
export PATH=$PATH:$HOME/.local/bin
# export DOCKER_HOST=tcp://localhost:2375

# Custom installation configuration
export PATH=$PATH:$HOME/install/bin
export TERM=tmux-256color

# Kubernetes Conf
export KUBEHOME=$HOME/.kube
export KUBECONFIG=$KUBEHOME/config:$(find $KUBEHOME -name "*.yaml" | tr '\n' ':')

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="$HOME/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
export PATH="/opt/homebrew/opt/ruby/bin:$PATH"

if command -v terraform >/dev/null 2>&1; then
  autoload -U +X bashcompinit && bashcompinit
  complete -o nospace -C "$(command -v terraform)" terraform
fi
[ -f ~/.tecton-complete.zsh ] && . ~/.tecton-complete.zsh
export CHALK_INSTALL="$HOME/.chalk"
export PATH="$CHALK_INSTALL/bin:$PATH"
command -v uv >/dev/null 2>&1 && eval "$(uv generate-shell-completion zsh)"

# Added by Antigravity CLI installer
export PATH="$HOME/.local/bin:$PATH"

# Added by Antigravity IDE
export PATH="$HOME/.antigravity-ide/antigravity-ide/bin:$PATH"

# Machine-specific / local overrides and secrets
if [ -f "$HOME/.zshrc.local" ]; then
  source "$HOME/.zshrc.local"
fi

# ==============================================================================
# Workspace & Agent Dual Workflow Configuration
# ==============================================================================

# 1. Automatic Session & Directory-Based Environment Loading
_load_work_env_if_applicable() {
  if [ -n "$TMUX" ]; then
    local _s=$(tmux display-message -p -t "$TMUX_PANE" '#S' 2>/dev/null)
    if [[ "$_s" == "work"* ]]; then
      [ -f "$HOME/.work_env" ] && source "$HOME/.work_env"
      return
    fi
  fi
  if [[ "$PWD" == *"/workspace/work"* ]]; then
    [ -f "$HOME/.work_env" ] && source "$HOME/.work_env"
  elif [[ "$PWD" == *"/workspace/personal"* ]]; then
    unset JIRA_PERSONAL_TOKEN CONFLUENCE_PERSONAL_TOKEN
  fi
}

autoload -Uz add-zsh-hook
add-zsh-hook chpwd _load_work_env_if_applicable
_load_work_env_if_applicable

# 2. Work / Personal Session Launchers
work() {
  [ -f "$HOME/.work_env" ] && source "$HOME/.work_env"
  if [ -n "$TMUX" ]; then
    tmux switch-client -t work 2>/dev/null || (tmux new-session -d -s work -c "$HOME/workspace/work" && tmux switch-client -t work)
  else
    tmux new-session -A -s work -c "$HOME/workspace/work"
  fi
}

personal() {
  if [ -n "$TMUX" ]; then
    tmux switch-client -t personal 2>/dev/null || (tmux new-session -d -s personal -c "$HOME/workspace/personal" && tmux switch-client -t personal)
  else
    tmux new-session -A -s personal -c "$HOME/workspace/personal"
  fi
}

# 2. Claude Code Safety Guardrail
claude() {
  if [[ "$PWD" == *"/workspace/personal"* ]]; then
    if [[ "$1" == "--force" ]]; then
      shift
      command claude "$@"
    else
      print -P "%F{red}⛔ Claude Code is restricted to work projects.%f"
      print -P "%F{yellow}Current directory:%f $PWD"
      print -P "%F{cyan}Use Antigravity ('agy') for personal projects, or pass '--force' / use '\\claude' to bypass.%f"
      return 1
    fi
  else
    command claude "$@"
  fi
}

# 3. Radar: daily-cached feature & new tool discovery (radar/radar.py, run `radar` to review)
#    Never touches the network on startup: it only reads a cache file, and a detached
#    background job refreshes that cache when it is older than 24h.
_radar_notify() {
  add-zsh-hook -d precmd _radar_notify  # once, at the first prompt (keeps p10k instant prompt quiet)
  local cache="${RADAR_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/radar}"
  local -a fresh=("$cache"/last_refresh(N.mh-24))
  if (( ! ${#fresh} )); then
    radar refresh --if-stale &>/dev/null &!
  fi
  [[ -s "$cache/banner.txt" ]] || return 0
  local banner="$(<"$cache/banner.txt")"
  local session="$(tmux display-message -p -t "$TMUX_PANE" '#S' 2>/dev/null)"
  if [[ "$session" == work* || "$session" == personal* ]]; then
    # Show each distinct banner once per tmux session rather than in every new pane
    [[ "$(tmux show-environment -t "$session" RADAR_SEEN 2>/dev/null)" == "RADAR_SEEN=$banner" ]] && return 0
    tmux set-environment -t "$session" RADAR_SEEN "$banner"
  elif [[ "$PWD" == *"/workspace/work"* || "$PWD" == *"/workspace/personal"* ]]; then
    [[ "$RADAR_SEEN" == "$banner" ]] && return 0
    export RADAR_SEEN="$banner"
  else
    return 0
  fi
  print -r -- "$banner"
}
if [[ -o interactive ]] && [[ -t 1 ]] && [[ -z "$ANTIGRAVITY_SHELL" ]] && [[ -z "$VSCODE_INJECTION" ]] && [[ -z "$CI" ]] && (( $+commands[radar] )); then
  add-zsh-hook precmd _radar_notify
fi

# 4. Interactive Session Picker on Terminal Startup
if [[ -o interactive ]] && [[ -t 0 ]] && [[ -z "$TMUX" ]] && [[ -z "$ANTIGRAVITY_SHELL" ]] && [[ -z "$VSCODE_INJECTION" ]] && [[ -z "$CI" ]]; then
  print -P "%F{cyan}┌────────────────────────────────────────────────────────┐%f"
  print -P "%F{cyan}│%f  %BSelect Workspace Session:%b                             %F{cyan}│%f"
  print -P "%F{cyan}│%f   %F{yellow}[1]%f 🏢  %BWork%b      (Claude Code, EA GitLab, Jira)     %F{cyan}│%f"
  print -P "%F{cyan}│%f   %F{green}[2]%f 🏠  %BPersonal%b  (Antigravity, GitHub)             %F{cyan}│%f"
  print -P "%F{cyan}│%f   %F{blue}[3]%f ⚡  %BScratch%b   (Direct shell without tmux)       %F{cyan}│%f"
  print -P "%F{cyan}└────────────────────────────────────────────────────────┘%f"
  read -k 1 "choice?Choice [1/2/3] (default 1): "
  echo
  case "$choice" in
    2) personal ;;
    3) ;;
    *) work ;;
  esac
fi
