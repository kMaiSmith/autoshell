#!/usr/bin/env bash
#
# The basic autoshell framework

initialize_autoshell() {
    AUTOSHELL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1; pwd)"
    AUTOSHELL_LIB_PATH+=":${AUTOSHELL_ROOT}/lib"
    AUTOSHELL_SCRIPT_PATH+=":${AUTOSHELL_ROOT}/script"

    # Bootstrap safe include functions
    . "${AUTOSHELL_ROOT}/lib/libautoshell.include.bash"

    # Include core autoshell functionality
    include "$(find_lib autoshell.log)"
    include "$(find_lib autoshell.flow)"
    include "$(find_lib autoshell.script)"
}