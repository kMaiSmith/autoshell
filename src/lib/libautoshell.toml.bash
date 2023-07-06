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
        dest_var="${2}" \
        config_var_name="${3:-"${TOML_CONFIG_VAR}"}" \
        config_value
    local -n config_var="${config_var_name}"
    [ -n "${config_var[*]-}" ] && \
        config_value="${config_var["${toml_key}"]-}"

    declare -g "${dest_var}=${config_value-}"
}
export -f toml.map_value
