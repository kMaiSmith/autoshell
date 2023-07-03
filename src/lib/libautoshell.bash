#!/usr/bin/env bash
#
# The basic autoshell framework

[ -d "${AUTOSHELL_LIB_ROOT-}" ] || \
    AUTOSHELL_LIB_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1; pwd)"
[[ ":${AUTOSHELL_LIB_PATH-}:" == *":${AUTOSHELL_LIB_ROOT}:"* ]] || \
    AUTOSHELL_LIB_PATH+=":${AUTOSHELL_LIB_ROOT}"

configure_shell() {
    set -o nounset
    set -o errexit
    set -o pipefail
}
export -f configure_shell

configure_shell

source "${AUTOSHELL_LIB_ROOT}/libautoshell.include.bash"
include "${AUTOSHELL_LIB_ROOT}/libautoshell.log.bash"
include "${AUTOSHELL_LIB_ROOT}/libautoshell.exec.bash"