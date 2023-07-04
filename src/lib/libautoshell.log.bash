#!/usr/bin/env bash
#
# Logging tools

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
export LOG_CONTEXT_BUILDER='${CONTEXT:-${FUNCNAME[1]-}}:'
log() {
    local _level="${1^^}"
    local _message="${2}"
    local CONTEXT="${3-}"

    [ -n "${LOG_LEVELS-}" ] || declare -Ag LOG_LEVELS=(
            ["TRACE"]=0
            ["DEBUG"]=10
            ["INFO"]=20
            ["WARN"]=30
            ["ERROR"]=40
            ["FATAL"]=50
        )
    [ -n "${LOG_LEVEL-}" ] || declare -g LOG_LEVEL="INFO"

    # shellcheck disable=SC2086
    [ ${LOG_LEVELS["${_level}"]-99} -lt ${LOG_LEVELS["${LOG_LEVEL}"]-0} ] || {
        echo -n "[${_level}] "
        eval "echo -n \"${LOG_CONTEXT_BUILDER}\""
        echo " ${_message}"
    }
}
export -f log