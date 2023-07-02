#!/usr/bin/env bats

bats_require_minimum_version "1.5.0"

source "src/libautoshell.bash"
source "src/lib/libautoshell.task.bash"

setup() {
    export AUTOSHELL_TASK_PATH="${BATS_TEST_TMPDIR}/tasks"
}

build_task() { # task_name
    local task_name="${1/\./\/}"
    local task_file="${AUTOSHELL_TASK_PATH}/${task_name}/$(basename ${task_name}).bash"

    mkdir -p "$(dirname "${task_file}")"
    touch "${task_file}"

    echo "${task_file}"
}

@test "execute_task: runs the task.exec function of a found task definition" {
    task_name="task1"

    expected_task_output="${RANDOM}"
    cat <<EOT >"$(build_task "${task_name}")"
#!/usr/bin/env bash

task.exec() {
    echo "${expected_task_output}"
}
EOT

    run -0 execute_task "${task_name}"

    [ "${output}" = "${expected_task_output}" ]
}

@test "execute_task: fatally exits when the task file does not exist" {
    task_name="task1"

    run ! execute_task "${task_name}"

    [ "${output}" = "[FATAL] execute_task: Task ${task_name} could not be found in the AUTOSHELL_TASK_PATH" ]
}

@test "execute_task: fatally exits when the task file does not include a task.exec() definition" {
    task_name="task1"
    task_file="$(build_task "${task_name}")"

    cat <<EOT >"${task_file}"
#!/usr/bin/env bash
EOT

    run execute_task "${task_name}"
    echo "${output}"

    [ "${output}" = "[FATAL] execute_task: Task file ${task_file} is invalid, task.exec() is not defined" ]
}

@test "execute_task: fatally exits when free code is defined in the task body" {
    task_name="task1"
    task_file="$(build_task "${task_name}")"

    cat <<EOT >"${task_file}"
#!/usr/bin/env bash

echo "bad echo"

task.exec() { :; }
EOT

    run ! execute_task "${task_name}"
    echo "${output}"

    [[ "${output}" == *"[FATAL] execute_task: The task file ${task_file} is invalid" ]]
}

@test "execute_task: searches all directories in the AUTOSHELL_TASK_PATH" {
    task_name="task1"

    expected_task_output="${RANDOM}"
    cat <<EOT >"$(build_task "${task_name}")"
#!/usr/bin/env bash

task.exec() {
    echo "${expected_task_output}"
}
EOT

    AUTOSHELL_TASK_PATH="/tmp:${AUTOSHELL_TASK_PATH}"

    run -0 execute_task "${task_name}"

    [ "${output}" = "${expected_task_output}" ]
}

@test "execute_task: finds child tasks when looking for parent.child" {
    task_name="parent.child"

    expected_task_output="${RANDOM}"
    cat <<EOT >"$(build_task "${task_name}")"
#!/usr/bin/env bash

task.exec() {
    echo "${expected_task_output}"
}
EOT

    run -0 execute_task "${task_name}"

    [ "${output}" = "${expected_task_output}" ]
}

@test "execute_task: skips task execution when up_to_date returns zero" {
    task_name="task1"

    cat <<EOT >"$(build_task "${task_name}")"
#!/usr/bin/env bash

task.up_to_date() {
    true
}

task.exec() {
    echo "bad echo"
}
EOT

    run -0 execute_task "${task_name}"

    [ -z "${output}" ]
}
