#!/usr/bin/env bash
#
# The basic autoshell framework

###############################
# Formally include another shell script into the fold, only permitting function
#   definitions
# Arguments:
#   Path to file to include
# Returns:
#   0 => Successfully included the script file
#   1 => Failed to locate a valid script file
#   2 => The script file contained more than function definitions
###############################
include() {
    local _file="${1}"

    [ -f "${_file}" ] || {
        log ERROR "${_file}: File not found"
        return 1
    }

    [[ "$(file "${_file}")" = *"Bourne-Again shell script"* ]] || {
        log ERROR "${_file}: Not a Bash script"
        return 1
    }

    # Inner function is reached via traps
    # shellcheck disable=SC2317
    _cleanup() {
        trap - DEBUG RETURN
        shopt -u extdebug
        unset -f _cleanup _detective
    }
    trap _cleanup RETURN

    # Inner function is reached via traps
    # shellcheck disable=SC2317
    _detective() {
        [ "${BASH_COMMAND}" = ". \"\${_file}\"" ] || {
            log error \
                "${_file}: Unexpected unwrapped call: \"${BASH_COMMAND}\"" \
                "${FUNCNAME[1]}"
            return 2
        }
    }
    shopt -s extdebug
    trap _detective DEBUG

    # Shellcheck is not expected to validate the file being sourced due to the
    #   nature of the function
    # shellcheck disable=SC1090
    . "${_file}"
}


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
# Log a message about the current process
# Globals:
#   LOG_LEVELS: Global associative array of log levels to numerical intensity
#   LOG_LEVEL: Current log level
# Arguments:
#   Log level of the message
#   Message to display
#   (Optional) Name of the calling function
# Outputs:
#   writes the message to stdout with the level and name of calling function
###############################
log() {
    local _level="${1^^}"
    local _message="${2}"
    local _caller="${3-}"

    [ -n "${LOG_LEVELS-}" ] || declare -Ag LOG_LEVELS=(
            ["TRACE"]=0
            ["DEBUG"]=10
            ["INFO"]=20
            ["WARN"]=30
            ["ERROR"]=40
            ["FATAL"]=50
        )
    [ -n "${LOG_LEVEL-}" ] || declare -g LOG_LEVEL="INFO"
    [ -n "${_caller}" ] || _caller="${FUNCNAME[1]-}"

    # shellcheck disable=SC2086
    [ ${LOG_LEVELS["${_level}"]-99} -lt ${LOG_LEVELS["${LOG_LEVEL}"]-0} ] || {
        echo -n "[${_level}] "
        echo -n "${_caller:+${_caller}: }"
        echo "${_message}"
    }
}

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

    log FATAL "${_message}" "${FUNCNAME[1]-}"

    exit 1
}
