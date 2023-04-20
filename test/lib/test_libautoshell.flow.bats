#!/usr/bin/env bats

# Load the libautoshell.sh script
source "src/lib/libautoshell.flow.bash"

setup() {
    script_file="$(mktemp)"
}

teardown() {
    rm "${script_file}"
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

# Test fatal function
@test "fatal: logs a FATAL message and exits the process" {
    run try "fatal 'This is a FATAL error message'"
    [ "$status" -eq 1 ]
    # Using regex to match the output since the log may contain additional information
    [ "$output" = "FATAL: This is a FATAL error message" ]
}

@test "fatal: when libautoshell.log is included, the message is logged" {
    source "src/lib/libautoshell.log.bash"

    run try "fatal 'This is a FATAL error message'"
    [ "$status" -eq 1 ]
    # Using regex to match the output since the log may contain additional information
    [[ "$output" =~ \[FATAL\].*This\ is\ a\ FATAL\ error\ message ]]
}
