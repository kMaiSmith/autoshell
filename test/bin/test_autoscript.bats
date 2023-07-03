#!/usr/bin/env bats

bats_require_minimum_version "1.5.0"

AUTOSCRIPT="${PWD}/src/bin/autoscript"

setup() {
    export AUTOSHELL_SCRIPT_PATH="${BATS_TEST_TMPDIR}/scripts"
    export TMPDIR="${BATS_TEST_TMPDIR}"

    cd "${BATS_TEST_TMPDIR}"
}

build_script() { # script_name
    local script_name="${1}"
    local script_file="${AUTOSHELL_SCRIPT_PATH}/${script_name}"

    mkdir -p "$(dirname "${script_file}")"
    touch "${script_file}"
    chmod +x "${script_file}"

    echo "${script_file}"
}

@test "autoscript: runs the __script_exec function of a found task definition" {
    script_name="script1"

    expected_task_output="${RANDOM}"
    cat <<EOT >"$(build_script "${script_name}")"
#!/usr/bin/env bash

__script_exec() {
    echo "${expected_task_output}"
}
EOT

    run "${AUTOSCRIPT}" "${script_name}"

    echo "${output}"

    [ "${status}" -eq 0 ]
    [ "${output}" = "${expected_task_output}" ]
}
