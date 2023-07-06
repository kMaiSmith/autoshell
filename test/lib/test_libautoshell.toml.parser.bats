#!/usr/bin/env bats

source "src/lib/libautoshell.bash"
include "$(find_lib autoshell.toml.parser)"

setup() {
    declare -Ag TEST_CONFIG
    cd "${BATS_TEST_TMPDIR}"
}

@test "tomlparser.parse: parses key=value pairs from the input file" {
    toml_key="key1"
    toml_value="value1"
    toml_file="./test.toml"
    cat <<TOML >"${toml_file}"
${toml_key}=${toml_value}
TOML

    tomlparser.parse TEST_CONFIG < "${toml_file}"

    [ "${TEST_CONFIG[.${toml_key}]}" = "${toml_value}" ]
}

@test "tomlparser.parse: parses double quoted string values" {
    toml_key="key1"
    toml_value="space separated value"
    toml_file="./test.toml"
    cat <<TOML >"${toml_file}"
${toml_key}="${toml_value}"
TOML

    tomlparser.parse TEST_CONFIG < "${toml_file}"

    echo "${TEST_CONFIG[.${toml_key}]}"
    [ "${TEST_CONFIG[.${toml_key}]}" = "${toml_value}" ]
}

@test "tomlparser.parse: parses multiple values from the file" {
    toml_key1="key1"
    toml_key2="key2"
    toml_value1="value1"
    toml_value2="value2"
    toml_file="./test.toml"
    cat <<TOML >"${toml_file}"
${toml_key1}="${toml_value1}"
${toml_key2}="${toml_value2}"
TOML

    tomlparser.parse TEST_CONFIG < "${toml_file}"

    [ "${TEST_CONFIG[.${toml_key1}]}" = "${toml_value1}" ]
    [ "${TEST_CONFIG[.${toml_key2}]}" = "${toml_value2}" ]
}

@test "tomlparser.parse: prepends table headers onto key names" {
    toml_heading="heading1"
    toml_key="key1"
    toml_value="${RANDOM}"
    toml_file="./test.toml"
    cat <<TOML >"${toml_file}"
[${toml_heading}]
${toml_key}="${toml_value}"
TOML

    tomlparser.parse TEST_CONFIG < "${toml_file}"

    echo "${TEST_CONFIG[.${toml_heading}.${toml_key}]}"
    [ "${TEST_CONFIG[.${toml_heading}.${toml_key}]}" = "${toml_value}" ]
}

@test "tomlparser.parse: parses array values into multiple, enumerated CONFIG entries" {
    toml_heading="heading1"
    toml_key="key1"
    toml_value1="${RANDOM}"
    toml_value2="${RANDOM}"
    toml_file="./test.toml"
    cat <<TOML >"${toml_file}"
[${toml_heading}]
${toml_key} = [ "${toml_value1}", "${toml_value2}" ]
TOML

    tomlparser.parse TEST_CONFIG < "${toml_file}"

    [ "${TEST_CONFIG[.${toml_heading}.${toml_key}[0]]}" = "${toml_value1}" ]
    [ "${TEST_CONFIG[.${toml_heading}.${toml_key}[1]]}" = "${toml_value2}" ]
}

@test "tomlparser.parse: parses arrays expressed over multiple lines" {
    toml_heading="heading1"
    toml_key="key1"
    toml_value1="${RANDOM}"
    toml_value2="${RANDOM}"
    toml_file="./test.toml"
    cat <<TOML >"${toml_file}"
[${toml_heading}]
${toml_key} = [
    "${toml_value1}",
    "${toml_value2}"
]
TOML

    tomlparser.parse TEST_CONFIG < "${toml_file}"

    [ "${TEST_CONFIG[.${toml_heading}.${toml_key}[0]]}" = "${toml_value1}" ]
    [ "${TEST_CONFIG[.${toml_heading}.${toml_key}[1]]}" = "${toml_value2}" ]
}