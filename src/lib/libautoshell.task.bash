#!/usr/bin/env bash

execute_task() (
    local \
        task_file="" \
        task_name="${1}" \
        next_task_name="" \
        task_completion_identifier="#"

    declare -g TASK_EXECUTION_LOG TASK_MAIN

    [ -n "${TASK_EXECUTION_LOG-}" ] || {
        # execute_task is ultimately recursive.  The TASK_EXECUTION_LOG is set
        #   on the first entry into the recursive loop (main task call), and
        #   relied upon from thereon out
        # shellcheck disable=SC2030
        TASK_EXECUTION_LOG="$(mktemp)"
    }
    [ -n "${TASK_MAIN-}" ] || \
        TASK_MAIN="${task_name}"

    grep -q "^${task_name}:${task_completion_identifier}" "${TASK_EXECUTION_LOG}" && \
        return

    task_file="$(find_task "${task_name}")"
    [ -n "${task_file}" ] || \
        fatal "Task ${task_name} could not be found in the AUTOSHELL_TASK_PATH"

    unset -f task.exec task.dependencies task.up_to_date
    include "${task_file}" || \
        fatal "The task file ${task_file} is invalid"

    [ "$(type -t task.exec)" = "function" ] || \
        fatal "Task file ${task_file} is invalid, task.exec() is not defined"

    [ "$(type -t task.dependencies)" = "function" ] && \
        execute_task_dependencies

    sed -i "/^${task_name}:/d" "${TASK_EXECUTION_LOG}"
    echo -n "${task_name}:" >> "${TASK_EXECUTION_LOG}"

    [ "$(type -t task.up_to_date)" = "function" ] && task.up_to_date ||
        task.exec
    echo "${task_completion_identifier}" >> "${TASK_EXECUTION_LOG}"

    [ "${task_name}" = "${TASK_MAIN}" ] || \
        return 0

    next_task_name="$(grep -v -m1 ".*:${task_completion_identifier}$" "${TASK_EXECUTION_LOG}" | awk -F: '{print $1}')"
    [ -n "${next_task_name-}" ] || \
        return 0

    execute_task "${next_task_name}"
)

execute_task_dependencies() {
    # Inner function is reached via traps
    # shellcheck disable=SC2317
    _cleanup_execute_task_dependencies() {
        trap - RETURN
        unset -f _cleanup_execute_task.dependencies \
            depends_on finalized_by
    }
    trap "_cleanup_execute_task_dependencies" RETURN

    # Inner function is reached via calls from task.dependencies
    # shellcheck disable=SC2317
    depends_on() { # depends_on_task_name
        local depends_on_task_name="${1}"

        execute_task "${depends_on_task_name}"
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
}