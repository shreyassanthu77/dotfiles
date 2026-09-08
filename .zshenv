[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# Tailscale SSH sessions skip logind, so give them the running user session's
# runtime dir (needed by waypipe, systemctl --user, pipewire, dbus).
[ -z "$XDG_RUNTIME_DIR" ] && [ -d "/run/user/$UID" ] && export XDG_RUNTIME_DIR="/run/user/$UID"

# ZVM
export ZVM_INSTALL="$HOME/.zvm/self"
export PATH="$PATH:$HOME/.zvm/bin"
export PATH="$PATH:$HOME/.local/share/pnpm/bin"
export PATH="$PATH:$ZVM_INSTALL/"

export WINEDEBUG=-all
