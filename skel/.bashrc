# x seed shell.

# Aliases
alias ..='cd ..'
alias ...='cd ../..'
alias c='clear'
alias ll='ls -lh'
alias la='ls -A'
alias l='ls -CF'

alias gc='git clone'
alias ga='git add .'
alias gs='git status'
alias gl='git log --oneline --graph --decorate'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gd='git diff'
alias gp='git pull'
alias gf='git fetch'

# Si se usa zsh, cargar tambien este rc.
if [ -n "$ZSH_VERSION" ]; then
    true
fi
