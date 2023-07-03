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
