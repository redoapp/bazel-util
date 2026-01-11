bin="$1"
shift

exec "$(rlocation "$bin")" "$@"
