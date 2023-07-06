#!/usr/bin/env bash

export \
    TASK_CONFIG_VAR="TASK_CONFIG" \
    TASK_USER_CONFIG_VAR="TASK_USER_CONFIG"
task.load_config() {
    local \
        task_name="${1}" \
        toml_file \
        task_part \
        task="" \
        IFS="."

    [ "${task_name}" = "${TASK_MAIN-}" ] && [ -f "./project.toml" ] && \
        toml.load "./project.toml" "${TASK_USER_CONFIG_VAR}"

    for task_part in ${task_name}; do
        task="${task:+${task}.}${task_part}"
        if toml_file="$(task.find_file "${task}" toml)"; then
            toml.load "${toml_file}" "${TASK_CONFIG_VAR}"
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

    task.get_config^try_prefix "${TASK_USER_CONFIG_VAR}"
    [ -n "${key_ref-}" ] || \
        task.get_config^try_prefix "${TASK_CONFIG_VAR}"
}
task.get_config^try_prefix() {
    local \
        config_var="${1}" \
        toml_key="" \
        task_part \
        IFS="."

    for task_part in ${task_name}; do
        toml_key="${toml_key-}.${task_part}"
        if [ -n "$(toml.get_value "${toml_key}.${key_name}" "${config_var}")" ]; then
            toml.map_value "${toml_key}.${key_name}" "${key_name}" "${config_var}"
        fi
    done
}
export -f task.get_config task.get_config^try_prefix