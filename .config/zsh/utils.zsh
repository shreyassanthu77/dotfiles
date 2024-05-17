function addpath() {
	export PATH=$1:$PATH
}

function addlibpath() {
	export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$1
}
