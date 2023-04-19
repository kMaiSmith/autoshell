#!/usr/bin/env bash
#
# Entrypoint for the autoshell.sh scripting framework.
set -ue

declare -x REPO_ROOT AUTOSHELL_SCRIPT_PATH AUTOSHELL_LIB_PATH AUTOSHELL_VERSION

AUTOSHELL_VERSION=""
REPO_ROOT=$(cd "$(dirname "${0}")" || exit 1; pwd)
AUTOSHELL_SCRIPT_PATH="${REPO_ROOT}/src/script"
AUTOSHELL_LIB_PATH="${REPO_ROOT}/src/lib"

. "${REPO_ROOT}/src/lib/libautoshell.sh"

log INFO "Success!"

# TODO:
# load configurations from autoshell.toml using a new library libtoml.sh
# load and execute a script using libscript.sh