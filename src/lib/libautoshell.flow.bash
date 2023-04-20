#!/usr/bin/env bash
#
# Additional shell flow control functions for quality of life

###############################
# Try an expression in a subshell, always return gracefully
# Arguments:
#   Expression to evaluate in a subshell
# Returns:
#   Return value of the expression, never exits
###############################
try() (
    local _expression="${*}"

    set -ueo pipefail;

    eval "${_expression}"
)

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
