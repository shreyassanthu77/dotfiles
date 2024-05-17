source ~/.config/zsh/utils.zsh
source ~/.config/zsh/zinit.zsh
source ~/.config/zsh/prompt.zsh
source ~/.config/zsh/config.zsh

alias r="source ~/.zshrc"

alias ls="ls --color"
alias l="ls -lah"

alias time="/usr/bin/time"
function md() {
	mkdir -p $@ && cd ${@:$#}
}

alias v="nvim"
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
function gi() {
	curl -sLw "\n" https://www.toptal.com/developers/gitignore/api/$@
}


# openssl for node js
addlibpath $HOME/.pkgx/openssl.org/v1.1.1w/lib

export GOPATH=$HOME/go
export PNPM_HOME="/home/shreyas/.local/share/pnpm"

PATHS=(
	"$GOPATH/bin"
	"$PNPM_HOME"
	"$HOME/.pulumi/bin"
	"$HOME/zig"
	"$HOME/.cargo/bin"
	"$HOME/.sst/bin"
	"$HOME/.turso"
)

for p in $PATHS; do
	addpath $p
done

source <(pkgx --shellcode)
source <(caddy completion zsh)
