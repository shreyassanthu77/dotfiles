source ~/.config/zsh/utils.zsh
source ~/.config/zsh/zinit.zsh
source ~/.config/zsh/prompt.zsh
source ~/.config/zsh/config.zsh
source ~/.config/zsh/zellij.zsh

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
alias gl="git log --oneline --decorate --all --graph"
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

export CHROME_EXECUTABLE=$(which microsoft-edge-dev)
PATHS=(
	"$GOPATH/bin"
	"$PNPM_HOME"
	"$HOME/.pulumi/bin"
	"$HOME/.cargo/bin"
	"$HOME/.sst/bin"
	"$HOME/.turso"
	"$HOME/flutter/bin"
	"$HOME/Android/Sdk/platform-tools"
)

for p in $PATHS; do
	addpath $p
done

# zig version manager
if [ ! -d "$HOME/.zvm" ]; then
	echo "Zig Version Manager not installed. Do you want to install it? (y/n)"
	read -q
	echo "Installing Zig Version Manager..."
	curl https://raw.githubusercontent.com/tristanisham/zvm/master/install.sh | bash
fi
export ZVM_INSTALL="$HOME/.zvm/self"
addpath $HOME/.zvm/bin
addpath $ZVM_INSTALL


source <(pkgx --shellcode)
source <(caddy completion zsh)

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export ANTHROPIC_API_KEY=$(pass show anthropic/nvim)
