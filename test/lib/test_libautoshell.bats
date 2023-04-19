#!/usr/bin/env bats

# Load the libautoshell.sh script
source "src/lib/libautoshell.bash"

setup() {
    script_file="$(mktemp)"
}

teardown() {
    rm "${script_file}"
}

# Test include function
@test "include: successfully includes a valid script file" {
    cat <<EOM > "${script_file}"
#!/usr/bin/env bash

valid_function() {
    echo "This is a valid function"
}
EOM
    run include "${script_file}"
    [ "${status}" -eq 0 ]

    # Actually perform the include unwrapped to test if it loads functions
    include "${script_file}"
    valid_function_output="$(valid_function)"
    [ "${valid_function_output}" == "This is a valid function" ]
}

@test "include: fails when the script file is not found" {
    run include "non_existent_script.sh"
    [ "${status}" -eq 1 ]
}

@test "include: fails when the script is not a Bash script" {
    cat <<EOM > "${script_file}"
This is not a Bash script
EOM
    run include "${script_file}"
    [ "${status}" -eq 1 ]
}

@test "include: fails when the script contains more than function definitions" {
    cat <<EOM > "${script_file}"
#!/usr/bin/env bash
echo "This should not be here"
another_valid_function() {
    echo "This is another valid function"
}
EOM
    run include "${script_file}"
    [ "$status" -eq 2 ]
}

# Test try function
@test "try: successfully evaluates an expression without errors" {
    run try "echo 'successful expression'"
    [ "$status" -eq 0 ]
    [ "$output" == "successful expression" ]
}

@test "try: evaluates an expression with errors and returns gracefully" {
    run try "non_existent_command"
    [ "$status" -ne 0 ]
}

# Test log function
@test "log: successfully logs a message when the log level is equal or higher than LOG_LEVEL" {
    run log "INFO" "This is an INFO level message"
    [ "$status" -eq 0 ]
    [[ "$output" =~ \[INFO\].*This\ is\ an\ INFO\ level\ message ]]
}

@test "log: does not log a message when the log level is lower than LOG_LEVEL" {
    LOG_LEVEL="WARN"
    run log "DEBUG" "This is a DEBUG level message"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
    LOG_LEVEL="INFO"
}

# Test fatal function
@test "fatal: logs a FATAL message and exits the process" {
    run try "fatal 'This is a FATAL error message'"
    [ "$status" -eq 1 ]
    # Using regex to match the output since the log may contain additional information
    [[ "$output" =~ \[FATAL\].*This\ is\ a\ FATAL\ error\ message ]]
}
