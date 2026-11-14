# mise shims — covers GUI and non-interactive shells that never source .zshrc
export PATH="$HOME/.local/share/mise/shims:$PATH"

# keep PATH free of duplicates even when .zshrc is re-sourced or the parent
# environment already has entries (zsh ties $PATH to the unique $path array)
typeset -U path

[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# Tailscale SSH sessions skip logind, so give them the running user session's
# runtime dir (needed by waypipe, systemctl --user, pipewire, dbus).
[ -z "$XDG_RUNTIME_DIR" ] && [ -d "/run/user/$UID" ] && export XDG_RUNTIME_DIR="/run/user/$UID"

# ZVM
export ZVM_INSTALL="$HOME/.zvm/self"
export PATH="$PATH:$HOME/.zvm/bin"
export PATH="$PATH:$HOME/.local/share/pnpm/bin"
export PATH="$PATH:$ZVM_INSTALL"

export WINEDEBUG=-all
