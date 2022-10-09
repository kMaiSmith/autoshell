#!/bin/bash

run_script() ( configure_shell
    local _script_name="${1}"
    local _args=("${@:2}")

    local _script_file
    _script_file="$(which "${_script_name}")" || \
        error "run_script: could not find executable script: ${_script_name}"

    include_script "${_script_file}" || \
        error "run_script: could not load script: ${_script_file}"

    [ "$(type -t __script_exec)" = "function" ] || \
        error "${_script_name}: malformed script: __script_exec() is not defined"

    trap "invoke_optionally __script_cleanup" EXIT

    invoke_optionally __script_parse_opts "${_args[@]}" || \
        error "run_script: Script could not parse arguments"

    invoke_optionally __script_init || \
        error  "run_script: Script could not initialize"

    __script_exec && \
        invoke_optionally __script_succeed || \
        invoke_optionally __script_failed || \
        error "Script execution failed"
)

declare -x SAFESCRIPT_SCRIPT_FUNCS=\
"__script_parse_opts "+\
"__script_init "+\
"__script_exec "+\
"__script_succeed "+\
"__script_failed "+\
"__script_cleanup"
include_script() {
    local _script_file="${1}"

    [ -f "${_script_file}" ] || \
        error "include_script: ${_script_file} not found"

    [[ "$(file "${_script_file}")" = *"safescript script"* ]] || \
        error "include_script: ${_script_file}: Not a safescript file"

    for _func in ${SAFESCRIPT_SCRIPT_FUNCS}; do
        unset -f "${_func}"
    done

    _cleanup() {
        trap - DEBUG RETURN
        shopt -u extdebug
        unset -f _cleanup _detective
    }
    trap _cleanup RETURN

    _detective() {
        [ "${BASH_COMMAND}" = '. "${_script_file}"' ] || {
            log ERROR "include_script: Unexpected naked command call: \"${BASH_COMMAND}\""
            return 2
        }
    }
    shopt -s extdebug
    trap _detective DEBUG

    . "${_script_file}"
}

# Runs a function if it is defined, does nothing if it is not
invoke_optionally() {
    local _function="${1}"
    local _args=("${@:2}")

    [  "$(type -t "${_function}")" = "function" ] || \
        return 0

    "${_function}" "${_args[@]}"
}

configure_shell() {
    set -o nounset
    set -o pipefail
}

declare -ix LOG_LEVEL_DEBUG=0
declare -ix LOG_LEVEL_INFO=1
declare -ix LOG_LEVEL_WARN=2
declare -ix LOG_LEVEL_ERROR=3
declare -ux LOG_LEVEL="${LOG_LEVEL:-INFO}"
log() {
    local -u _level="${1}"
    local _message="${2}"

    local -n _level_i="LOG_LEVEL_${_level}"
    local -n _current_level_i="LOG_LEVEL_${LOG_LEVEL}"

    [ -n "${_level_i-}" ] || \
        error "invalid log level: ${_level}"

    [ ${_level_i} -lt ${_current_level_i:-0} ] || \
        echo "[${_level}] ${_message}"
}

error() {
    local _message="${1}"

    log ERROR "${_message}"

    exit 1
}