[[ ${DEBUG:-0} -ne 0 ]] && set -x

eval "$(plenv init -)"

function assss90() {
  perlver=${1:-"system"}
  perlscope=${2:-"shell"}
  shift 2
  args=("$@")
  echo "☆ ${args[*]} ☆"
  plenv "$perlscope" "$perlver" 2>&1
  return $?
}

assss90 "$@"
