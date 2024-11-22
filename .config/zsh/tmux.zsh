alias t="tmux"
function ts() {
    if [[ -n "$TMUX" ]]; then
        # If already in tmux, switch to session or create if not exists
        tmux switch-client -t "$1" 2>/dev/null || tmux new-session -d -s "$1" \; switch-client -t "$1"
    else
        # Attach to session or create if not exists
        tmux attach -t "$1" || tmux new -s "$1"
    fi
}

function ta() {
    wd=$(pwd)
    if [ "$wd" = "$HOME" ]; then
        base="home"
    else
        base=$(basename "$wd")
    fi
    
    tmux_sessions=$(tmux list-sessions -F "#S" 2> /dev/null)
    if [ -z "$tmux_sessions" ]; then
        tmux new -s "$base"
        return
    fi
    
    new_session="New Session"
    selected_session=$(echo "$new_session"$'\n'"$tmux_sessions" | fzf)
    
    if [ "$selected_session" = "$new_session" ]; then
        ts "$base"
    else
        ts "$selected_session"
    fi
}
