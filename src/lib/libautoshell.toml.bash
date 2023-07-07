#!/usr/bin/env bash

export TOML_CONFIG_VAR="TOML_CONFIG"
toml.load() { # toml_file[, toml_prefix=$TOML_PREFIX]
        toml_file="${1}" \
        config_var="${2:-"${TOML_CONFIG_VAR}"}"

    include "$(find_lib autoshell.toml.parser)"

    declare -gA "${config_var}"

    tomlparser.parse "${config_var}" < "${toml_file}"
}
export -f toml.load

toml.get_value() { # toml_key, toml_section[, toml_prefix=$TOML_PREFIX]
    local \
        toml_key="${1}" \
        config_var_name="${2:-"${TOML_CONFIG_VAR}"}"

    toml.map_value "${toml_key}" TOML_VALUE "${config_var_name}"

    echo "${TOML_VALUE-}"
}

toml.map_value() { # toml_key, dest_var[, config_var=$TOML_CONFIG_VAR]
    local \
        toml_key="${1}" \
        dest_var_name="${2}" \
        config_var_name="${3:-"${TOML_CONFIG_VAR}"}"
    local -n config_ref="${config_var_name}"
    local -n var_ref="${dest_var_name}"
    declare -g "${dest_var_name}"
    var_ref=""

    [ -n "${config_ref[*]-}" ] || \
        return 0

    var_ref="${config_ref["${toml_key}"]-}"

    [ -n "${var_ref-}" ] || {
        [ "$(type -t map.keys)" = "function" ] || \
            include "$(find_lib map)"
        declare -ga "${dest_var_name}=()"
        while read -r key; do var_ref+=("${config_ref[${key}]}"); done < \
            <( map.keys config_ref | grep "${toml_key}\[[0-9]*\]" | sort )
    }
}
export -f toml.map_value