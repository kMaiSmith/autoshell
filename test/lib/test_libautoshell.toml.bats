bats_require_minimum_version "1.5.0"

source "src/lib/libautoshell.bash"
source "src/lib/libautoshell.toml.bash"

@test "toml.load: reads toml values into global bash variables" {
    toml_file="${BATS_TEST_TMPDIR}/config.toml"
    expected_value="${RANDOM}"
    cat <<EOC >"${toml_file}"
[heading1]
key1 = ${expected_value}
EOC

    toml.load "${toml_file}"

    [ "${TOML_heading1_KEY_key1}" = "${expected_value}" ]
}

@test "toml.load: can override variable prefix values are loaded into" {
    toml_file="${BATS_TEST_TMPDIR}/config.toml"
    expected_value="${RANDOM}"
    cat <<EOC >"${toml_file}"
[heading1]
key1 = ${expected_value}
EOC

    toml.load "${toml_file}" "MY_PREFIX"

    [ "${MY_PREFIX_heading1_KEY_key1}" = "${expected_value}" ]
}

@test "toml.get_value: echos loaded toml environment variable value for the header and key" {
    toml_file="${BATS_TEST_TMPDIR}/config.toml"
    expected_value="${RANDOM}"
    cat <<EOC >"${toml_file}"
[heading1]
key1 = ${expected_value}
EOC

    toml.load "${toml_file}"

    [ "$(toml.get_value "key1" "heading1")" = "${expected_value}" ]
}

@test "toml.map_value: references loaded toml environment variable to variable named toml_key" {
    toml_file="${BATS_TEST_TMPDIR}/config.toml"
    expected_value="${RANDOM}"
    cat <<EOC >"${toml_file}"
[heading1]
key1 = ${expected_value}
EOC

    toml.load "${toml_file}"

    toml.map_value "key1" "heading1"

    [ "${key1}" = "${expected_value}" ]
}
