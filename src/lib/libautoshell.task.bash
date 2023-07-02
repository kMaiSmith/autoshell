#!/usr/bin/env bash

execute_task() {
    local task_name="${1}"
    local task_file="$(find_task "${task_name}")"

    [ -n "${task_file}" ] || \
        fatal "Task ${task_name} could not be found in the AUTOSHELL_TASK_PATH"

    include "${task_file}" || \
        fatal "The task file ${task_file} is invalid"

    [ "$(type -t task.exec)" = "function" ] || \
        fatal "Task file ${task_file} is invalid, task.exec() is not defined"

    [ "$(type -t task.up_to_date)" = "function" ] && \
        task.up_to_date || \
        task.exec
}