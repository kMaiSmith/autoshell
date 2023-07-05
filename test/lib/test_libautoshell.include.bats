#!/usr/bin/env bats

# Load the libautoshell.sh script
source "src/lib/libautoshell.include.bash"

setup() {
    TEST_DIR="$(mktemp -d)"
    TEST_SCRIPT_FILE="${TEST_DIR}/test_script.sh"
}

teardown() {
    rm -r "${TEST_DIR}"
}

# Test include function
@test "include: successfully includes a valid script file" {
    cat <<EOM > "${TEST_SCRIPT_FILE}"
#!/usr/bin/env bash

valid_function() {
    echo "This is a valid function"
}
EOM

    run include "${TEST_SCRIPT_FILE}"
    [ "${status}" -eq 0 ]

    # Actually perform the include unwrapped to test if it loads functions
    include "${TEST_SCRIPT_FILE}"
    valid_function_output="$(valid_function)"
    [ "${valid_function_output}" == "This is a valid function" ]
}

@test "include: fails when the script file is not found" {
    run include "non_existent_script.sh"
    [ "${status}" -eq 1 ]
}

@test "include: fails when the script contains more than function definitions" {
    cat <<EOM > "${TEST_SCRIPT_FILE}"
#!/usr/bin/env bash
echo "This should not be here"
another_valid_function() {
    echo "This is another valid function"
}
EOM

    run include "${TEST_SCRIPT_FILE}"
    [ "${status}" -eq 2 ]
}

# Test find_lib function
@test "find_lib: successfully finds a library file in the AUTOSHELL_LIB_PATH" {
    touch "${TEST_DIR}/libtestlib.bash"
    AUTOSHELL_LIB_PATH="${TEST_DIR}"

    run find_lib "testlib"
    [ "${status}" -eq 0 ]
    [ "${output}" == "${TEST_DIR}/libtestlib.bash" ]
}

@test "find_lib: finds the first library file in the AUTOSHELL_LIB_PATH" {
    mkdir -p "${TEST_DIR}/lib1" "${TEST_DIR}/lib2"
    touch "${TEST_DIR}/lib1/libtestlib.bash"
    touch "${TEST_DIR}/lib2/libtestlib.bash"
    AUTOSHELL_LIB_PATH="${TEST_DIR}/lib1:${TEST_DIR}/lib2"

    run find_lib "testlib"
    [ "${status}" -eq 0 ]
    [ "${output}" == "${TEST_DIR}/lib1/libtestlib.bash" ]
}

@test "find_lib: fails when the library file is not found in the AUTOSHELL_LIB_PATH" {
    AUTOSHELL_LIB_PATH="${TEST_DIR}"
    run find_lib "nonexistentlib"
    [ "${status}" -eq 1 ]
    [ -z "${output}" ]
}
