# ~/.zshrc — plain zsh, curated. Installed to the primary user's home.

# ── PATH ──────────────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$PATH"

# ── History ───────────────────────────────────────────────────────────
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000
setopt SHARE_HISTORY          # share history across sessions
setopt HIST_IGNORE_ALL_DUPS   # drop older duplicate entries
setopt HIST_IGNORE_SPACE      # ignore commands starting with a space
setopt HIST_REDUCE_BLANKS
setopt INC_APPEND_HISTORY
setopt EXTENDED_HISTORY

# ── Shell options ─────────────────────────────────────────────────────
setopt AUTO_CD                # `mydir` == `cd mydir`
setopt AUTO_PUSHD             # cd pushes onto the dir stack
setopt PUSHD_IGNORE_DUPS
setopt INTERACTIVE_COMMENTS   # allow # comments in interactive shell
setopt NO_BEEP

# ── Completion ────────────────────────────────────────────────────────
autoload -Uz compinit && compinit -d "$HOME/.zcompdump"
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'   # case-insensitive
zstyle ':completion:*' list-colors ''
zstyle ':completion:*:descriptions' format '%B%d%b'

# ── Keybindings (emacs) + history search ──────────────────────────────
bindkey -e
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search      # Up  = prefix history search
bindkey '^[[B' down-line-or-beginning-search    # Down

# ── Git-aware prompt (native vcs_info, no framework) ──────────────────
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats ' %F{yellow}(%b)%f'
zstyle ':vcs_info:git:*' actionformats ' %F{yellow}(%b|%a)%f'
setopt PROMPT_SUBST
PROMPT='%F{cyan}%n@%m%f %F{green}%~%f${vcs_info_msg_0_} %(?.%F{green}.%F{red})❯%f '

# ── Aliases ───────────────────────────────────────────────────────────
alias ll='ls -lhF --color=auto'
alias la='ls -lAhF --color=auto'
alias l='ls -CF --color=auto'
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias gs='git status'
alias gl='git log --oneline --graph --decorate -20'
alias gd='git diff'
alias df='df -h'
alias free='free -h'
alias ports='sudo ss -tulpn'

# ── mise (runtime/version manager) ────────────────────────────────────
eval "$(mise activate zsh)"
