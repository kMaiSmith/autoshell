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
    _cleanup() {
        trap - DEBUG RETURN
        shopt -u extdebug
        unset -f _cleanup _detective
    }
    trap _cleanup RETURN

    # Inner function is reached via traps
    # shellcheck disable=SC2317
    _detective() {
        [ "${BASH_COMMAND}" = ". \"\${_script}\"" ] || {
            log error \
                "${_script}: Unexpected unwrapped call: \"${BASH_COMMAND}\"" \
                "${FUNCNAME[1]}"
            return 2
        }
    }
    shopt -s extdebug
    trap _detective DEBUG

    # shellcheck source=/dev/null
    . "${_script}"
}

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