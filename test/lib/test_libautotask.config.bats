#!/usr/bin/env bats

source "src/lib/libautoshell.bash"
include "$(find_lib autoshell.toml)"
include "$(find_lib autotask)"
include "$(find_lib autotask.config)"

setup() {
    export AUTOSHELL_TASK_PATH="${BATS_TEST_TMPDIR}"
    export TMPDIR="${BATS_TEST_TMPDIR}"
    cd "${BATS_TEST_TMPDIR}"
}

build_config() {
    task_name="${1/\./\/}"
    config_file="${AUTOSHELL_TASK_PATH}/${task_name}/$(basename "${task_name}").toml"

    mkdir -p "$(dirname "${config_file}")"
    touch "${config_file}"

    echo "${config_file}"
}

@test "task.load_config: loads matching .toml file to found task file" {
    task_name="task1"
    task_config_key="key1"
    expected_value="${RANDOM}"
    loaded_config_key=".${task_name}.${task_config_key}"

    cat <<EOC >"$(build_config "${task_name}")"
[${task_name}]
${task_config_key} = ${expected_value}
EOC

    task.load_config "${task_name}"

    [ "$(toml.get_value "${loaded_config_key}" "${TASK_CONFIG_VAR}")" = "${expected_value}" ]
}

@test "task.load_config: also loads parent config when present" {
    parent_task_name="parent"
    task_name="${parent_task_name}.task1"
    task_config_key="key1"
    expected_value="${RANDOM}"
    loaded_config_key=".${parent_task_name}.${task_config_key}"

    cat <<EOC >"$(build_config "${parent_task_name}")"
[${parent_task_name}]
${task_config_key} = ${expected_value}
EOC

    task.load_config "${task_name}"

    [ "$(toml.get_value "${loaded_config_key}" "${TASK_CONFIG_VAR}")" = "${expected_value}" ]
}

@test "task.load_config: loads user config into TASK_USER_CONFIG_VAR" {
    task_name="task1"
    TASK_MAIN="${task_name}"
    task_config_key="key1"
    expected_value="${RANDOM}"
    loaded_config_key=".${task_name}.${task_config_key}"

    cat <<EOC >"./project.toml"
[${task_name}]
${task_config_key} = ${expected_value}
EOC

    task.load_config "${task_name}"

    [ "$(toml.get_value "${loaded_config_key}" "${TASK_USER_CONFIG_VAR}")" = "${expected_value}" ]
}

@test "task.load_config: does not load user config when not running as main task" {
    TASK_MAIN="other_task"
    task_name="task1"
    task_config_key="key1"

    cat <<EOC >"./project.toml"
[${task_name}]
${task_config_key} = bad
EOC

    task.load_config "${task_name}"

    [ -z "$(toml.get_value "${task_config_key}" "${task_name}" "${TASK_USER_CONFIG_VAR}")" ]
}

@test "task.get_config: copies the TOML loaded config value into the key name variable" {
    task_name="task1"
    task_config_key="my_value"
    expected_value="${RANDOM}"

    cat <<EOC >"$(build_config "${task_name}")"
[${task_name}]
${task_config_key} = ${expected_value}
EOC

    task.load_config "${task_name}"

    [ -z "${my_value-}" ]

    task.get_config my_value "${task_name}"

    [ "${my_value}" = "${expected_value}" ]
}

@test "task.get_config: reads config from env TASK_NAME when task_name is unset" {
    export TASK_NAME="task1"
    task_config_key="my_value"
    expected_value="${RANDOM}"

    cat <<EOC >"$(build_config "${TASK_NAME}")"
[${TASK_NAME}]
${task_config_key} = ${expected_value}
EOC

    task.load_config "${TASK_NAME}"

    [ -z "${my_value-}" ]

    task.get_config "${task_config_key}"

    [ "${my_value}" = "${expected_value}" ]
}

@test "task.get_config: reads parent task config values when task does not contain config name" {
    parent_task="parent"
    export TASK_NAME="${parent_task}.task1"
    task_config_key="my_value"
    expected_value="${RANDOM}"

    cat <<EOC >"$(build_config "${parent_task}")"
[${parent_task}]
${task_config_key} = ${expected_value}
EOC

    task.load_config "${TASK_NAME}"

    [ -z "${my_value-}" ]

    task.get_config "${task_config_key}"

    [ "${my_value-}" = "${expected_value}" ]
}

@test "task.get_config: loads user parent task config value trump task config" {
    task_parent_name="parent"
    export TASK_NAME="${task_parent_name}.task1"
    export TASK_MAIN="${TASK_NAME}"
    task_config_key="my_value"
    expected_value="${RANDOM}"

    cat <<EOC >"$(build_config "${TASK_NAME}")"
[${TASK_NAME}]
${task_config_key} = default
EOC
    cat <<EOC >"./project.toml"
[${task_parent_name}]
${task_config_key} = ${expected_value}
EOC

    task.load_config "${TASK_NAME}"

    [ -z "${my_value-}" ]

    task.get_config "${task_config_key}"

    echo "${my_value}"

    [ "${my_value}" = "${expected_value}" ]
}