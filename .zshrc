# Add deno completions to search path
if [[ ":$FPATH:" != *":/home/shreyas/.zsh/completions:"* ]]; then export FPATH="/home/shreyas/.zsh/completions:$FPATH"; fi
source ~/.config/zsh/utils.zsh
source ~/.config/zsh/zinit.zsh
source ~/.config/zsh/prompt.zsh
source ~/.config/zsh/config.zsh
source ~/.config/zsh/zellij.zsh
source ~/.config/zsh/tmux.zsh

eval "$(direnv hook zsh)"

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

export CHROME_EXECUTABLE=$(which chromium)
PATHS=(
	"$GOPATH/bin"
	"$PNPM_HOME"
	"$HOME/.pulumi/bin"
	"$HOME/.cargo/bin"
	"$HOME/.bun/bin"
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

# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion


if [ -f /tmp/anthropic-api-key ]; then
  export ANTHROPIC_API_KEY=$(cat /tmp/anthropic-api-key)
else
	pass show anthropic/nvim > /tmp/anthropic-api-key
	export ANTHROPIC_API_KEY=$(cat /tmp/anthropic-api-key)
fi

# dune
# source $HOME/.dune/env/env.zsh
