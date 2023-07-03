#!/usr/bin/env bash
#
# Functions for managing execution flows within scripts

###############################
# Try an expression in a subshell, always return gracefully
# Arguments:
#   Expression to evaluate in a subshell
# Returns:
#   Return value of the expression, never triggers script exit
###############################
try() (
    local _expression="${*}"

    set -ueo pipefail;

    eval "${_expression}"
)
export -f try

###############################
# Task failed, error out of the current process
# Arguments:
#   Message to display describing the error
# Outputs:
#   logs the message
# Returns:
#   1 and exits the current process
###############################
fatal() {
    local _message="${1}"

    if type log &>/dev/null; then
        log FATAL "${_message}" "${FUNCNAME[1]-}"
    else
        echo "FATAL: ${_message}"
    fi

    exit 1
}
export -f fatal

# Runs a function if it is defined, does nothing if it is not
invoke_optionally() {
    local _function="${1}"
    local _args=("${@:2}")

    [  "$(type -t "${_function}")" = "function" ] || \
        return 0

    "${_function}" "${_args[@]}"
}
export -f invoke_optionally