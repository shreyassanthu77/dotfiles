function addpath() {
	# skip if already present, so re-sourcing .zshrc doesn't duplicate PATH
	case ":$PATH:" in
	*":$1:"*) ;;
	*) export PATH=$1:$PATH ;;
	esac
}

function addlibpath() {
	export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$1
}
