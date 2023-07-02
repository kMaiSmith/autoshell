#!/usr/bin/env bash
#
# Entrypoint for the autoshell.sh scripting framework.
set -ue

REPO_ROOT="$(cd "$(dirname "${0}")" || exit 1; pwd)"
AUTOSHELL_ROOT="${REPO_ROOT}/src"
AUTOSHELL_TASK_PATH="${REPO_ROOT}/tasks"
export REPO_ROOT AUTOSHELL_ROOT AUTOSHELL_TASK_PATH

source "${AUTOSHELL_ROOT}/libautoshell.bash"

include "$(find_lib autoshell.task)"

execute_task "${1}"
# TODO:
# load configurations from autoshell.toml using a new library libtoml.sh
# load and execute a script using libscript.sh