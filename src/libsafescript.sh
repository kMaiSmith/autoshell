#!/bin/bash

run_script() ( configure_shell
    local _script_name="${1}"
    local _args=("${@:2}")

    local _script_file
    _script_file="$(find_script ${_script_name})" || \
        error "run_script: Cannot find script \"${_script_name}\""

    include_script "${_script_file}" || \
        error "run_script: Cannot load script \"${_script_name}\""

    trap "invoke_optionally __script_cleanup" EXIT

    invoke_optionally __script_parse_opts "${_script_args[@]}" || \
        error "run_script: Script could not parse arguments"

    invoke_optionally __script_init || \
        error  "run_script: Script could not initialize"

    __script_exec && \
        invoke_optionally __script_succeed || \
        error "run_script: Script execution failed" "invoke_optionally __script_failed"
)

find_script() {
    local _script_name="${1}"
    local _script_file

    while read -s _script_file; do
        is_script "${_script_file}" || \
            continue

        echo "${_script_file}"
        break
    done < <(echo "${_script_name}"; find ${PATH//:/\/ } -name "${_script_name}")
}

include_script() {
    local _script_file="${1}"

    is_script "${_script_file}" || \
        error "include_script: ${_script_file}: Not a safescript file"

    . "${_script_file}"
}

is_script() {
    [ -f "${_script_file}" ] && \
    [[ "$(file "${_script_file}")" = *"safescript script"* ]]
}

# Runs a function if it is defined, does nothing if it is not
invoke_optionally() {
    local _function="${1}"
    local _args=("${@:2}")

    [  "$(type "${_function}" 2>/dev/null)" = "function" ] || \
        return 0

    "${_function}" "${_args[@]}"
}

configure_shell() {
    set -o nounset
    set -o pipefail
}

log() {
    local -u _level="${1}"
    local _message="${2}"

    echo "[${_level}] ${_message}"
}

error() {
    local _message="${1}"

    log ERROR "${_message}"

    exit 1
}