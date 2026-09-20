# x seed shell.

# Local user binaries: dots/theme-sync/davincix/timex wrappers and x tooling.
# Kept here so they are reachable from interactive shells and TTY logins even
# when the desktop did not start.
export PATH="$HOME/.local/bin:$PATH"

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

# If zsh is in use, also load this rc.
if [ -n "$ZSH_VERSION" ]; then
    true
fi
