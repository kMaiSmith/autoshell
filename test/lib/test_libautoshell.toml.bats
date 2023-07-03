bats_require_minimum_version "1.5.0"

source "src/lib/libautoshell.bash"
source "src/lib/libautoshell.toml.bash"

@test "load_toml: reads toml values into global bash variables" {
    toml_file="${BATS_TEST_TMPDIR}/config.toml"
    expected_value="${RANDOM}"
    cat <<EOC >"${toml_file}"
[heading1]
key1 = ${expected_value}
EOC

    load_toml "${toml_file}"

    [ "${TOML_heading1_KEY_key1}" = "${expected_value}" ]
}

@test "load_toml: can override variable prefix values are loaded into" {
    toml_file="${BATS_TEST_TMPDIR}/config.toml"
    expected_value="${RANDOM}"
    cat <<EOC >"${toml_file}"
[heading1]
key1 = ${expected_value}
EOC

    load_toml "${toml_file}" "MY_PREFIX"

    [ "${MY_PREFIX_heading1_KEY_key1}" = "${expected_value}" ]
}