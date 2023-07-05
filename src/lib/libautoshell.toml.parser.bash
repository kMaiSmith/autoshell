#!/usr/bin/env bash

tomlparser.parse() {
    local \
        heading="" \
        key="" \
        value="" \
        quote="" \
        mode="read" \
        line char
    local -n ref=key
    local -n config="${1}"

    _flush() {
        [ -n "${key}" ] && \
            config["${heading:+.${heading}}.${key}"]="${value}"
        key=""
        value=""
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
                [ -z "${quote-}" ] && \
                    local -n ref=heading
                ;;
            $']')
                [ -z "${quote-}" ] && \
                    break
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
        local -n ref=key
        _flush
    done
}