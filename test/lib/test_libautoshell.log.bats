#!/usr/bin/env bats

# Load the libautoshell.sh script
source "src/lib/libautoshell.log.bash"

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
