#!/usr/bin/env bash
#
# The basic autoshell framework

[ -d "${AUTOSHELL_ROOT-}" ] || \
    AUTOSHELL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1; pwd)"
[[ ":${AUTOSHELL_LIB_PATH-}:" == *":${AUTOSHELL_ROOT}/lib:"* ]] || \
    AUTOSHELL_LIB_PATH+=":${AUTOSHELL_ROOT}/lib"

# Minimum helper definitions to get bootstrapped
include() { source "${1}"; }
find_lib() { echo "${AUTOSHELL_ROOT}/lib/lib${1}.bash"; }

include "$(find_lib autoshell.include)"
include "$(find_lib autoshell.log)"
include "$(find_lib autoshell.exec)"