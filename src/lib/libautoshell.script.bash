#!/usr/bin/env bash

export SAFESCRIPT_SCRIPT_FUNCS=\
"__script_parse_opts "+\
"__script_init "+\
"__script_exec "+\
"__script_succeed "+\
"__script_failed "+\
"__script_cleanup"
execute_script() ( configure_shell
    local _script_name="${1}"
    local _args=("${@:2}")

    local _script_file
    _script_file="$(PATH="${AUTOSHELL_SCRIPT_PATH-}" command -v "${_script_name}")" || \
        fatal "could not find executable script: ${_script_name}"

    for _func in ${SAFESCRIPT_SCRIPT_FUNCS}; do
        unset -f "${_func}"
    done
    include "${_script_file}" || \
        fatal "could not load script: ${_script_file}"

    [ "$(type -t __script_exec)" = "function" ] || \
        fatal "${_script_name}: malformed script: __script_exec() is not defined"

    trap "invoke_optionally __script_cleanup" EXIT

    invoke_optionally __script_parse_opts "${_args[@]}" || \
        fatal "Script could not parse arguments"

    invoke_optionally __script_init || \
        fatal  "Script could not initialize"

    __script_exec && \
        invoke_optionally __script_succeed || \
        invoke_optionally __script_failed || \
        fatal "Script execution failed"
)
export -f execute_script