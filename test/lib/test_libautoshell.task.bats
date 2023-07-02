#!/usr/bin/env bats

bats_require_minimum_version "1.5.0"

source "src/libautoshell.bash"
source "src/lib/libautoshell.task.bash"
source "src/lib/libautoshell.toml.bash"

setup() {
    export AUTOSHELL_TASK_PATH="${BATS_TEST_TMPDIR}/tasks"
    export TMPDIR="${BATS_TEST_TMPDIR}"
}

build_task() { # task_name
    local task_name="${1/\./\/}"
    local task_file="${AUTOSHELL_TASK_PATH}/${task_name}/$(basename ${task_name}).bash"

    mkdir -p "$(dirname "${task_file}")"
    touch "${task_file}"

    echo "${task_file}"
}

build_task.config() { # task_name
    local task_file task_config task_name="${1}"
    task_file="$(build_task "${task_name}")"
    task_config="${task_file/bash/toml}"

    touch "${task_config}"

    echo "${task_config}"
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

@test "execute_task: executes depends_on tasks before executing the named task" {
    main_task_name="task1"
    dependency_task_name="dep_task1"

cat <<EOT >"$(build_task "${dependency_task_name}")"
#!/usr/bin/env bash

task.exec() {
    echo "${dependency_task_name}"
}
EOT

    cat <<EOT >"$(build_task "${main_task_name}")"
#!/usr/bin/env bash

task.dependencies() {
    depends_on "${dependency_task_name}"
}

task.exec() {
    echo "${main_task_name}"
}
EOT

    run execute_task "${main_task_name}"

    echo "${output}"

    readarray -t task_executions <<< "${output}"

    [ "${task_executions[0]}" = "${dependency_task_name}" ]
    [ "${task_executions[1]}" = "${main_task_name}" ]
}

@test "execute_task: dependency management does not execute a task more than once per run" {
    main_task_name="task1"
    dependency_task_name="dep_task1"
    dependency_task2_name="dep_task2"

cat <<EOT >"$(build_task "${dependency_task_name}")"
#!/usr/bin/env bash

task.exec() {
    echo "${dependency_task_name}"
}
EOT

    cat <<EOT >"$(build_task "${dependency_task2_name}")"
#!/usr/bin/env bash

task.dependencies() {
    depends_on "${dependency_task_name}"
}

task.exec() {
    echo "${dependency_task2_name}"
}
EOT

    cat <<EOT >"$(build_task "${main_task_name}")"
#!/usr/bin/env bash

task.dependencies() {
    depends_on "${dependency_task_name}"
    depends_on "${dependency_task2_name}"
}

task.exec() {
    echo "${main_task_name}"
}
EOT

    run execute_task "${main_task_name}"

    echo "${output}"

    readarray -t task_executions <<< "${output}"

    [ "${task_executions[0]}" = "${dependency_task_name}" ]
    [ "${task_executions[1]}" = "${dependency_task2_name}" ]
    [ "${task_executions[2]}" = "${main_task_name}" ]
}

@test "execute_task: finalized_by dependencies are run after task execution" {
    main_task_name="task1"
    final_task_name="final_task1"

cat <<EOT >"$(build_task "${final_task_name}")"
#!/usr/bin/env bash

task.exec() {
    echo "${final_task_name}"
}
EOT

    cat <<EOT >"$(build_task "${main_task_name}")"
#!/usr/bin/env bash

task.dependencies() {
    finalized_by "${final_task_name}"
}

task.exec() {
    echo "${main_task_name}"
}
EOT

    run execute_task "${main_task_name}"

    echo "${output}"

    readarray -t task_executions <<< "${output}"

    [ "${task_executions[0]}" = "${main_task_name}" ]
    [ "${task_executions[1]}" = "${final_task_name}" ]
}

@test "execute_task: finalizers are only run once at the end of main execution" {
    main_task_name="task1"
    dependency_task_name="dep_task1"
    final_task_name="final_task"

cat <<EOT >"$(build_task "${dependency_task_name}")"
#!/usr/bin/env bash

task.dependencies() {
    finalized_by "${final_task_name}"
}

task.exec() {
    echo "${dependency_task_name}"
}
EOT

    cat <<EOT >"$(build_task "${final_task_name}")"
#!/usr/bin/env bash

task.dependencies() {
    depends_on "${dependency_task_name}"
}

task.exec() {
    echo "${final_task_name}"
}
EOT

    cat <<EOT >"$(build_task "${main_task_name}")"
#!/usr/bin/env bash

task.dependencies() {
    depends_on "${dependency_task_name}"
    finalized_by "${final_task_name}"
}

task.exec() {
    echo "${main_task_name}"
}
EOT

    run execute_task "${main_task_name}"

    echo "${output}"

    readarray -t task_executions <<< "${output}"

    [ "${task_executions[0]}" = "${dependency_task_name}" ]
    [ "${task_executions[1]}" = "${main_task_name}" ]
    [ "${task_executions[2]}" = "${final_task_name}" ]
}

@test "execute_task: provides configuration variables from task config TOML" {
    task_name="task1"

    expected_task_output="${RANDOM}"
    cat <<EOT >"$(build_task "${task_name}")"
#!/usr/bin/env bash

task.exec() {
    task.get_config test_value

    echo "\${test_value}"
}
EOT

    cat <<EOC >"$(build_task.config "${task_name}")"
[task1]
test_value = ${expected_task_output}
EOC

    run -0 execute_task "${task_name}"

    echo "${output}"

    [ "${output}" = "${expected_task_output}" ]
}