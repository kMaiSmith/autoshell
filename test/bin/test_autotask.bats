#!/usr/bin/env bats

bats_require_minimum_version "1.5.0"

AUTOTASK="${PWD}/src/bin/autotask"

setup() {
    export AUTOSHELL_TASK_PATH="${BATS_TEST_TMPDIR}/tasks"
    export TMPDIR="${BATS_TEST_TMPDIR}"

    cd "${BATS_TEST_TMPDIR}"
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

@test "autotask: runs the task.exec function of a found task definition" {
    task_name="task1"

    expected_task_output="${RANDOM}"
    cat <<EOT >"$(build_task "${task_name}")"
#!/usr/bin/env bash

task.exec() {
    echo "${expected_task_output}"
}
EOT

    run "${AUTOTASK}" "${task_name}"

    echo "${output}"

    [ "${status}" -eq 0 ]
    [ "${output}" = "${expected_task_output}" ]
}

@test "autotask: fatally exits when the task file does not exist" {
    task_name="task1"

    run ! "${AUTOTASK}" "${task_name}"

    echo "${output}"

    [ "${output}" = "[FATAL] autotask:${task_name}: Task ${task_name} could not be found in the AUTOSHELL_TASK_PATH" ]
}

@test "autotask: fatally exits when the task file does not include a task.exec() definition" {
    task_name="task1"
    task_file="$(build_task "${task_name}")"

    cat <<EOT >"${task_file}"
#!/usr/bin/env bash
EOT

    run "${AUTOTASK}" "${task_name}"
    echo "${output}"

    [ "${output}" = "[FATAL] autotask:${task_name}: Task file ${task_file} is invalid, task.exec() is not defined" ]
}

@test "autotask: fatally exits when free code is defined in the task body" {
    task_name="task1"
    task_file="$(build_task "${task_name}")"
    cat <<EOT >"${task_file}"
#!/usr/bin/env bash

echo "bad echo"
EOT

    run ! "${AUTOTASK}" "${task_name}"
    echo "${output}"

    [[ "${output}" == *"[FATAL] autotask:${task_name}: The task file ${task_file} is invalid" ]]
}

@test "autotask: searches all directories in the AUTOSHELL_TASK_PATH" {
    task_name="task1"

    expected_task_output="${RANDOM}"
    cat <<EOT >"$(build_task "${task_name}")"
#!/usr/bin/env bash

task.exec() {
    echo "${expected_task_output}"
}
EOT

    AUTOSHELL_TASK_PATH="/tmp:${AUTOSHELL_TASK_PATH}"

    run -0 "${AUTOTASK}" "${task_name}"

    [ "${output}" = "${expected_task_output}" ]
}

@test "autotask: finds child tasks when looking for parent.child" {
    task_name="parent.child"

    expected_task_output="${RANDOM}"
    cat <<EOT >"$(build_task "${task_name}")"
#!/usr/bin/env bash

task.exec() {
    echo "${expected_task_output}"
}
EOT

    run -0 "${AUTOTASK}" "${task_name}"

    [ "${output}" = "${expected_task_output}" ]
}

@test "autotask: skips task execution when up_to_date returns zero" {
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

    run -0 "${AUTOTASK}" "${task_name}"

    [ -z "${output}" ]
}

@test "autotask: executes depends_on tasks before executing the named task" {
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

    run "${AUTOTASK}" "${main_task_name}"

    echo "${output}"

    readarray -t task_executions <<< "${output}"

    [ "${task_executions[0]}" = "${dependency_task_name}" ]
    [ "${task_executions[1]}" = "${main_task_name}" ]
}

@test "autotask: dependency management does not execute a task more than once per run" {
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

    run "${AUTOTASK}" "${main_task_name}"

    echo "${output}"

    readarray -t task_executions <<< "${output}"

    [ "${task_executions[0]}" = "${dependency_task_name}" ]
    [ "${task_executions[1]}" = "${dependency_task2_name}" ]
    [ "${task_executions[2]}" = "${main_task_name}" ]
}

@test "autotask: finalized_by dependencies are run after task execution" {
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

    run "${AUTOTASK}" "${main_task_name}"

    echo "${output}"

    readarray -t task_executions <<< "${output}"

    [ "${task_executions[0]}" = "${main_task_name}" ]
    [ "${task_executions[1]}" = "${final_task_name}" ]
}

@test "autotask: finalizers are only run once at the end of main execution" {
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

    run "${AUTOTASK}" "${main_task_name}"

    echo "${output}"

    readarray -t task_executions <<< "${output}"

    [ "${task_executions[0]}" = "${dependency_task_name}" ]
    [ "${task_executions[1]}" = "${main_task_name}" ]
    [ "${task_executions[2]}" = "${final_task_name}" ]
}

@test "autotask: provides configuration variables from task config TOML" {
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

    run "${AUTOTASK}" "${task_name}"

    echo "${output}"

    [ "${output}" = "${expected_task_output}" ]
}

@test "autotask: task configuration is overridden by users project.toml" {
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
test_value = default_value
EOC

    cat <<EOC > "./project.toml"
[task1]
test_value = ${expected_task_output}
EOC

    run -0 "${AUTOTASK}" "${task_name}"

    echo "${output}"

    [ "${output}" = "${expected_task_output}" ]
}

@test "autotask: parent task configs are presented as first-class configs to child tasks" {
    parent_task_name="task1"
    child_task_name="task1.child"

    expected_task_output="${RANDOM}"
    cat <<EOT >"$(build_task "${child_task_name}")"
#!/usr/bin/env bash

task.exec() {
    task.get_config test_value

    echo "\${test_value}"
}
EOT

    cat <<EOC >"$(build_task.config "${parent_task_name}")"
[task1]
test_value = ${expected_task_output}
EOC

    run -0 "${AUTOTASK}" "${child_task_name}"

    echo "${output}"

    [ "${output}" = "${expected_task_output}" ]
}