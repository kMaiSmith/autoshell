#!/usr/bin/env bash

task.execute_dependencies() (
    # Inner function is reached via calls from task.dependencies
    # shellcheck disable=SC2317
    depends_on() { # depends_on_task_name
        local depends_on_task_name="${1}"

        execute_script "${AUTOTASK}" "${depends_on_task_name}"
    }

    # Inner function is reached via calls from task.dependencies
    # shellcheck disable=SC2317
    finalized_by() {
        local finalized_by_task_name="${1}"

        tasklog.set_entry "${finalized_by_task_name}" "${TASKLOG_PENDING_MARK}"
    }

    task.dependencies
)
export -f task.execute_dependencies

###############################
# Find the task file in the provided AUTOSHELL_TASK_PATH
# Globals:
#   AUTOSHELL_TASK_PATH: Colon-separated list of paths to search for task files
# Arguments:
#   Name of the task to find
# Outputs:
#   The path of the first task file found matching the name
# Returns:
#   0 => Successfully found the library file
#   1 => Library file not found
###############################
export TASK_FILE_TYPE=bash
task.find_file() {
    local \
        task_name="${1/\./\/}" \
        file_type="${2:-${TASK_FILE_TYPE}}" \
        path \
        plausible_task_file
    local -a plausible_task_files

    local IFS=":"
    for path in ${AUTOSHELL_TASK_PATH}; do
        plausible_task_files=(
            "${path}/${task_name}/$(basename "${task_name}").${file_type}"
            "${path}/${task_name}.${file_type}"
        )
        for plausible_task_file in "${plausible_task_files[@]}"; do
            if [ -f "${plausible_task_file}" ]; then
                echo "${plausible_task_file}"
                return 0
            fi
        done
    done

    return 1
}
export -f task.find_file