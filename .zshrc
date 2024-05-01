# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

source $ZSH/oh-my-zsh.sh

autoload -U +X compinit && compinit
# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

alias time="/usr/bin/time"
alias md="mkdir -p"

alias nv="nvim"
alias v="nvim"
alias vim="nvim"

alias c="clear"

alias g="git"
alias gs="git status"
alias ga="git add"
alias gaa="git add ."
alias gc="git commit"
alias gcm="git commit -m"
alias lz="lazygit"
function gcp() {
  git add .
	git commit -m "$@"
	git push
}

source <(pkgx --shellcode)  #docs.pkgx.sh/shellcode
source <(caddy completion zsh) # caddy server

# openssl
export LIBRARY_PATH=$HOME/.pkgx/openssl.org/v1.1.1w/lib
export LD_LIBRARY_PATH=$HOME/.pkgx/openssl.org/v1.1.1w/lib

# go
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin

source <(go-blueprint completion zsh)

# pnpm
export PNPM_HOME="/home/shreyas/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# add Pulumi to the PATH
export PATH=$PATH:$HOME/.pulumi/bin

# add zip to the Path
export PATH=$PATH:~/zig

# generate .gitignore
function gi() { curl -sLw "\n" https://www.toptal.com/developers/gitignore/api/$@ ;}

# cargo
export PATH=$PATH:$HOME/.cargo/bin

eval "$(zoxide init --cmd cd zsh)"

eval "$(starship init zsh)"
