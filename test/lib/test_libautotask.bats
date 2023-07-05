#!/usr/bin/env bats

bats_require_minimum_version "1.5.0"

source "src/lib/libautoshell.bash"
include "src/lib/libautoshell.toml.bash"
include "src/lib/libautotask.bash"

setup() {
    export AUTOSHELL_TASK_PATH="${BATS_TEST_TMPDIR}/tasks"
    export TMPDIR="${BATS_TEST_TMPDIR}"
    cd "${BATS_TEST_TMPDIR}"
}

# Test task.find_file function
@test "task.find_file finds the first script file in the AUTOSHELL_TASK_PATH" {
    mkdir -p "${BATS_TEST_TMPDIR}/tasks1/testtask" "${BATS_TEST_TMPDIR}/tasks2/testtask"
    touch "${BATS_TEST_TMPDIR}/tasks1/testtask/testtask.bash"
    touch "${BATS_TEST_TMPDIR}/tasks2/testtask/testtask.bash"
    AUTOSHELL_TASK_PATH="${BATS_TEST_TMPDIR}/tasks1:${BATS_TEST_TMPDIR}/tasks2"

    run task.find_file "testtask"
    [ "${status}" -eq 0 ]
    [ "${output}" == "${BATS_TEST_TMPDIR}/tasks1/testtask/testtask.bash" ]
}

@test "task.find_file: fails when the task file is not found in the AUTOSHELL_TASK_PATH" {
    run task.find_file "nonexistenttask"
    [ "${status}" -eq 1 ]
    [ -z "${output}" ]
}

@test "task.find_file: will find child task directory in the parent task directory" {
    mkdir -p "${AUTOSHELL_TASK_PATH}/parent1/child1"
    touch "${AUTOSHELL_TASK_PATH}/parent1/child1/child1.bash"

    run task.find_file "parent1.child1"

    [ "${output}" = "${AUTOSHELL_TASK_PATH}/parent1/child1/child1.bash" ]
}

@test "task.find_file: will find child task files in the parent task directory" {
    mkdir -p "${AUTOSHELL_TASK_PATH}/parent1"
    touch "${AUTOSHELL_TASK_PATH}/parent1/child1.bash"

    run task.find_file "parent1.child1"

    [ "${output}" = "${AUTOSHELL_TASK_PATH}/parent1/child1.bash" ]
}

@test "task.find_file prefers child task directories over child task files" {
    mkdir -p "${AUTOSHELL_TASK_PATH}/parent1/child1"
    touch "${AUTOSHELL_TASK_PATH}/parent1/child1/child1.bash"
    touch "${AUTOSHELL_TASK_PATH}/parent1/child1.bash"

    run task.find_file "parent1.child1"

    [ "${output}" = "${AUTOSHELL_TASK_PATH}/parent1/child1/child1.bash" ]
}