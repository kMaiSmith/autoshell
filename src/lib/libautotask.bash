#!/usr/bin/env bash

export TASK_USER_CONFIG_PREFIX="TASK_USER_CONFIG"

execute_task_dependencies() (
    # # Inner function is reached via traps
    # # shellcheck disable=SC2317
    # _cleanup_execute_task_dependencies() {
    #     trap - RETURN
    #     unset -f _cleanup_execute_task_dependencies \
    #         depends_on finalized_by
    # }
    # trap "_cleanup_execute_task_dependencies" RETURN

    # Inner function is reached via calls from task.dependencies
    # shellcheck disable=SC2317
    depends_on() { # depends_on_task_name
        local depends_on_task_name="${1}"

        autotask "${depends_on_task_name}"
    }

    # Inner function is reached via calls from task.dependencies
    # shellcheck disable=SC2317
    finalized_by() {
        local finalized_by_task_name="${1}"

        # TASK_EXECUTION_LOG needs to be set one-off by the first subsehell
        #   execution, once set the file name is valid for every subshell
        # shellcheck disable=SC2031
        echo "${finalized_by_task_name}:~" >> "${TASK_EXECUTION_LOG}"
    }

    task.dependencies
)
export -f execute_task_dependencies

task.get_config() {
    local key_name="${1}"
    declare -g "${key_name}"
    local -n task_var="${key_name}"

    local -n user_config_var="${TASK_USER_CONFIG_PREFIX}_${TASK_NAME/\./\/}_KEY_${key_name}"
    if [ -n "${user_config_var-}" ]; then
        task_var="${user_config_var}"
    else
        local -n config_var="${TASK_CONFIG_PREFIX}_${TASK_NAME/\./\/}_KEY_${key_name}"
        task_var="${config_var-}"
    fi
}
export -f task.get_config

export TASK_CONFIG_PREFIX="TASK_CONFIG"
task.load_config() {
    [ -f "${TASK_FILE/\.bash/\.toml}" ] && {
        # import "$(find_lib autoshell.toml)"
        load_toml "${TASK_FILE/\.bash/\.toml}" "${TASK_CONFIG_PREFIX}"
    }
}
export -f task.load_config