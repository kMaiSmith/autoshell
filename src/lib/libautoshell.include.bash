#!/usr/bin/env bash
#
# Functionality for finding and including shell files

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
    local _script="${1}"

    type log &>/dev/null || log() { echo "${*}"; }

    [ -f "${_script}" ] || {
        log ERROR "${_script}: File not found"
        return 1
    }

    [[ "$(file "${_script}")" = *"Bourne-Again shell script"* ]] || {
        log ERROR "${_script}: Not a Bash script"
        return 1
    }

    # Inner function is reached via traps
    # shellcheck disable=SC2317
    _cleanup_include() {
        trap - DEBUG RETURN
        shopt -u extdebug
        unset -f _cleanup _detective
    }
    trap _cleanup_include RETURN

    # Inner function is reached via traps
    # shellcheck disable=SC2317
    _detective() {
        [ "${BASH_COMMAND}" = "source \"\${_script}\"" ] || \
        [[ "${BASH_COMMAND}" = "export "* ]] || {
            log error \
                "${_script}: Unexpected unwrapped call: \"${BASH_COMMAND}\"" \
                "${FUNCNAME[1]}"
            return 2
        }
    }
    shopt -s extdebug
    trap _detective DEBUG

    # shellcheck source=/dev/null
    source "${_script}"
}
export -f include

###############################
# Find the library file in the provided AUTOSHELL_LIB_PATH
# Globals:
#   AUTOSHELL_LIB_PATH: Colon-separated list of paths to search for library files
# Arguments:
#   Name of the library (without the 'lib' prefix and '.bash' extension)
# Outputs:
#   The path of the first library file found
# Returns:
#   0 => Successfully found the library file
#   1 => Library file not found
###############################
find_lib() {
    local lib_file="lib${1}.bash"
    local path

    local IFS=":"
    for path in ${AUTOSHELL_LIB_PATH}; do
        if [ -f "${path}/${lib_file}" ]; then
            echo "${path}/${lib_file}"
            return 0
        fi
    done

    return 1
}
export -f find_lib

###############################
# Find the task file in the provided AUTOSHELL_TASK_PATH
# Globals:
#   AUTOSHELL_TASK_PATH: Colon-separated list of paths to search for task files
# Arguments:
#   Name of the task to find
# Outputs:
#   The path of the first task file found matching the name
# Returns:
#   0 => Successfully found the library file
#   1 => Library file not found
###############################
find_task() {
    local task_name="${1/\./\/}"
    local path plausible_task_file
    local -a plausible_task_files

    local IFS=":"
    for path in ${AUTOSHELL_TASK_PATH}; do
        plausible_task_files=(
            "${path}/${task_name}/$(basename "${task_name}").bash"
            "${path}/${task_name}.bash"
        )
        for plausible_task_file in "${plausible_task_files[@]}"; do
            if [ -f "${plausible_task_file}" ]; then
                echo "${plausible_task_file}"
                return 0
            fi
        done
    done

    return 1
}
export -f find_task