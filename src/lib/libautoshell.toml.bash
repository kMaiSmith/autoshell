#!/usr/bin/env bash

load_toml() { # toml_file
    local \
        current_heading="default" \
        current_key \
        current_value \
        global_var_name \
        line \
        toml_file="${1}"

    while read -r line; do
        case "${line}" in
        \[*\])
            current_heading="$(sed -e 's/\[\(.*\)\]/\1/' <<< "${line}")"
            ;;
        *\ \=\ *)
            current_key="$(sed -e 's/^\(.*\) = .*$/\1/' <<< "${line}")"
            current_value="$(sed -e 's/^.* = \(.*\)$/\1/' <<< "${line}")"
            global_var_name="TOML_${current_heading}_KEY_${current_key}"
            declare -g "${global_var_name}"
            local -n ref_var="${global_var_name}"
            ref_var="${current_value}"
            ;;
        esac
    done < "${toml_file}"
}
export -f load_toml