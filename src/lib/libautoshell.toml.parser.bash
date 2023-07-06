#!/usr/bin/env bash

tomlparser.parse() {
    local \
        heading="" \
        key="" \
        value="" \
        quote="" \
        array_index="" \
        mode="read" \
        line char
    local -n ref=key
    local -n config="${1}"

    _flush_value() {
        [ -n "${key}" ] && [ -n "${value}" ] && {
            local config_key="${heading:+.${heading}}.${key}${array_index:+[${array_index}]}"
            config["${config_key}"]="${value}"
        }
        value=""
    }

    _flush_key() {
        _flush_value
        key=""
    }

    while read -r line; do
        while read -n1 char; do
            case "${char}" in
            $'=')
                [ -z "${quote-}" ] && \
                    local -n ref=value
                ;;
            "${quote}")
                quote=""
                ;;
            $'"')
                quote="${char}"
                ;;
            $'[')
                [ -z "${quote-}" ] && {
                    if [[ "$(declare -p ref)" == *"value"* ]]; then
                        array_index=0
                    else
                        local -n ref=heading
                    fi
                }
                ;;
            $']')
                [ -z "${quote-}" ] && {
                    log INFO "]"
                    _flush_key
                    array_index=""
                    break
                }
                ;;
            $',')
                [ -z "${quote-}" ] && {
                    log INFO ","
                    _flush_value
                    array_index=$((array_index + 1))
                }
                ;;
            $'')
                [ -z "${quote-}" ] || \
                    ref+=" "
                ;;
            *)
                ref+="${char}"
                ;;
            esac
        done <<< "${line}"
        [ -n "${array_index-}" ] || {
            local -n ref=key
            _flush_key
        }
    done
}