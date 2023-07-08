#!/usr/bin/env bash

map.keys() {
    local -n array="${1}"
    local key
    for key in "${!array[@]}"; do
        echo "${key}"
    done
}
export -f map.keys