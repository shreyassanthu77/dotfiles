alias z="zellij"

function zs() {
	if [[ -n "$ZELLIJ" ]]; then
		zellij pipe --plugin zessman -- $1
	else
		zellij attach -c $1
	fi
}
function za() {
	wd=$(pwd)
	if [ "$wd" = "$HOME" ]; then
		base="home"
	else
		base=$(basename $wd)
	fi
	zsessions=$(zellij ls -sn 2> /dev/null)
	if [ -z "$zsessions" ]; then
		zellij -s $base
		return
	fi
	new_session="New Session"
	selected_session=$(echo $new_session'\n'$zsessions | fzf)
	if [ "$selected_session" = "$new_session" ]; then
		# zellij -s $base
		zs $base
	else
		# zellij attach $selected_session
		zs $selected_session
	fi
	return
}
