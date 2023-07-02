#!/usr/bin/env bash

load_toml() { # toml_file, var_prefix
    local \
        current_heading="default" \
        current_key \
        current_value \
        global_var_name \
        line \
        toml_file="${1}" \
        var_prefix="${2:-"TOML"}"

    while read -r line; do
        case "${line}" in
        \[*\])
            current_heading="$(sed -e 's/\[\(.*\)\]/\1/' <<< "${line}")"
            ;;
        *\ \=\ *)
            current_key="$(sed -e 's/^\(.*\) = .*$/\1/' <<< "${line}")"
            current_value="$(sed -e 's/^.* = \(.*\)$/\1/' <<< "${line}")"

            if [ -n "${current_value}" ]; then
                global_var_name="${var_prefix}_${current_heading}_KEY_${current_key}"
                declare -gx "${global_var_name}"
                local -n ref_var="${global_var_name}"
                ref_var="${current_value}"
            fi
            ;;
        esac
    done < <(cat "${toml_file}"; echo)
}
export -f load_toml