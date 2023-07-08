#!/usr/bin/env bash

tomlparser.parse() { # config_var <<< TOML Data
    declare -g \
        heading="" \
        key="" \
        value="" \
        quote="" \
        array_index="" \
        line_index="1" \
        mode="key" \
        line char
    declare -gn ref=key
    declare -gn config="${1}"

    while read -r line; do
        tomlparser.parse_line "${line}"
        line_index=$(( line_index + 1 ))
    done
}

tomlparser.parse_line() {
    local \
        line="${1}" \
        last_char="" \
        char_index=0

    while read -n1 char; do
        tomlparser.parse_char "${char_index}" "${char-}" "${last_char-}"
        char_index=$(( char_index + 1 ))
        last_char="${char-}"
    done <<< "${line}"
    case "${mode}" in
    array)
        ;;
    *)
        tomlparser.flush_key
        mode=key
        ;;
    esac
}

tomlparser.parse_char() {
    local \
        char_index="${1}" \
        char="${2:- }" \
        last_char="${3:- }"

    case "${mode}" in
    key)
        if [ -n "${quote-}" ]; then
            tomlparser.parse_char^quote key "${char}"
        else
            tomlparser.parse_char^key "${char}"
        fi
        ;;
    heading)
        if [ -n "${quote-}" ]; then
            tomlparser.parse_char^quote heading "${char}"
        else
            tomlparser.parse_char^heading "${char}"
        fi
        ;;
    value)
        if [ -n "${quote-}" ]; then
            tomlparser.parse_char^quote value "${char}"
        else
            tomlparser.parse_char^value "${char}"
        fi
        ;;
    array)
        [ -n "${array_index-}" ] || array_index=0
        if [ -n "${quote-}" ]; then
            tomlparser.parse_char^quote value "${char}"
        else
            tomlparser.parse_char^array "${char}"
        fi
        ;;
    line_return)
        tomlparser.parse_char^line_return "${char}"
        ;;
    comment)
        ;;
    esac
}

tomlparser.parse_char^quote() {
    local -n ref="${1}"
    local char="${2}"

    case "${char}" in
    "${quote}")
        quote=""
        ;;
    $''|$' ')
        ref+=" "
        ;;
    *)
        ref+="${char}"
        ;;
    esac
}

tomlparser.parse_char^key() {
    case "${1}" in
    $'[')
        heading=""
        mode=heading
        ;;
    $'=')
        mode=value
        ;;
    $'"')
        quote="${char}"
        ;;
    $' ')
        ;;
    *)
        [ "${last_char}" = " " ] && [ "${char_index}" -gt 0 ] && \
            tomlparser.parse_error "Unquoted keys cannot have spaces"
        key+="${char}"
        ;;
    esac
}

tomlparser.parse_char^heading() {
    case "${1}" in
    $']')
        mode=line_return
        ;;
    $'"')
        quote="${char}"
        ;;
    $' ')
        ;;
    *)
        heading+="${char}"
        ;;
    esac
}

tomlparser.parse_char^value() {
    case "${1}" in
    $'[')
        mode=array
        ;;
    $'"')
        quote="${char}"
        ;;
    $' ')
        ;;
    $'#')
        mode=comment
        ;;
    *)
        tomlparser.parse_error "Unquoted string"
        ;;
    esac
}

tomlparser.parse_char^array() {
    case "${1}" in
    $']')
        tomlparser.flush_key
        mode=line_return
        ;;
    $',')
        tomlparser.flush_value
        array_index=$(( array_index + 1 ))
        ;;
    $'"')
        quote="${char}"
        ;;
    $' ')
        ;;
    *)
        tomlparser.parse_error "Unquoted string"
        ;;
    esac
}

tomlparser.parse_char^line_return() {
    case "${1}" in
    $' ')
        ;;
    $'#')
        mode[-1]="comment"
        ;;
    *)
        tomlparser.parse_error "Unexpected symbol: ${char}"
        ;;
    esac
}

tomlparser.flush_value() {
    [ -n "${key}" ] && [ -n "${value}" ] && {
        local config_key="${heading:+.${heading}}.${key}${array_index:+[${array_index}]}"
        local config_value="$(envsubst <<< "${value}")"
        config["${config_key}"]="${config_value}"
    }
    value=""
}

tomlparser.flush_key() {
    tomlparser.flush_value
    key=""
}

tomlparser.parse_error() {
    log FATAL "${1}" "tomlparser: line ${line_index}, char ${char_index}"
    fatal
}