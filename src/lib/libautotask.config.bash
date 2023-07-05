#!/usr/bin/env bash

export \
    TASK_CONFIG_PREFIX="TASK_CONFIG" \
    TASK_USER_CONFIG_PREFIX="TASK_USER_CONFIG"
task.load_config() {
    local \
        task_name="${1}" \
        toml_file \
        task_part \
        task="" \
        IFS="."
    
    [ "${task_name}" = "${TASK_MAIN-}" ] && [ -f "./project.toml" ] && \
        toml.load "./project.toml" "${TASK_USER_CONFIG_PREFIX}"

    for task_part in ${task_name}; do
        task="${task:+${task}.}${task_part}"
        if toml_file="$(task.find_file "${task}" toml)"; then
            toml.load "${toml_file}" "${TASK_CONFIG_PREFIX}"
        fi
    done
}
export -f task.load_config

task.get_config() { # key_name[, task_name=$TASK_NAME]
    local \
        key_name="${1}" \
        task_name="${2:-${TASK_NAME}}"
    export "${key_name}"
    local -n key_ref="${key_name}"

    task.get_config^try_prefix "${TASK_USER_CONFIG_PREFIX}"
    [ -n "${key_ref-}" ] || \
        task.get_config^try_prefix "${TASK_CONFIG_PREFIX}"
}
task.get_config^try_prefix() {
    local \
        toml_prefix="${1}" \
        toml_section="" \
        task_part \
        IFS="."
    local -a toml_config=()

    for task_part in ${task_name}; do
        toml_section="${toml_section:+${toml_section}_}${task_part}"
        toml_config=("${key_name}" "${toml_section}" "${toml_prefix}")
        if [ -n "$(toml.get_value "${toml_config[@]}")" ]; then
            toml.map_value "${toml_config[@]}"
        fi
    done
}
export -f task.get_config task.get_config^try_prefix