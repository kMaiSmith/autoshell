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