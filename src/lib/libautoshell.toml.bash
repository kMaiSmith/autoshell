#!/usr/bin/env bash

export TOML_PREFIX="TOML"
toml.load() { # toml_file[, toml_prefix=$TOML_PREFIX]
    local \
        current_heading="default" \
        current_key \
        current_value \
        global_var_name \
        line \
        toml_file="${1}" \
        toml_prefix="${2:-"${TOML_PREFIX}"}"

    while read -r line; do
        case "${line}" in
        \[*\])
            current_heading="$(sed -e 's/\[\(.*\)\]/\1/' <<< "${line}")"
            ;;
        *\ \=\ *)
            current_key="$(sed -e 's/^\(.*\) = .*$/\1/' <<< "${line}")"
            current_value="$(sed -e 's/^.* = \(.*\)$/\1/' <<< "${line}")"

            if [ -n "${current_value}" ]; then
                global_var_name="${toml_prefix}_${current_heading/\./_}_KEY_${current_key}"
                declare -gx "${global_var_name}"
                local -n ref_var="${global_var_name}"
                ref_var="${current_value}"
            fi
            ;;
        esac
    done < <(cat "${toml_file}"; echo)
}
export -f toml.load

toml.get_value() { # toml_key, toml_section[, toml_prefix=$TOML_PREFIX]
    local \
        toml_key="${1}" \
        toml_section="${2}" \
        toml_prefix="${3:-"${TOML_PREFIX}"}"

    toml.map_value "${toml_key}" "${toml_section}" "${toml_prefix}" TOML_VALUE

    echo "${TOML_VALUE-}"
}

toml.map_value() { # toml_key, toml_section[, toml_prefix=$TOML_PREFIX, dest_var=$toml_key]
    local \
        toml_key="${1}" \
        toml_section="${2}" \
        toml_prefix="${3:-"${TOML_PREFIX}"}" \
        dest_var="${4:-${1}}"

    declare -gn "${dest_var}=${toml_prefix}_${toml_section}_KEY_${toml_key}"
}
export -f toml.map_value
