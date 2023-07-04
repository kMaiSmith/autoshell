#!/usr/bin/env bats

# Load the libautoshell.sh script
source "src/lib/libautoshell.log.bash"

setup() {
    LOG_LEVEL="INFO"
}

# Test log function
@test "log: successfully logs a message when the log level is equal or higher than LOG_LEVEL" {
    log_level="INFO"
    log_message="This is an INFO level message"
    log_context="context1"

    run log "${log_level}" "${log_message}" "${log_context}"

    [ ${status} -eq 0 ]
    [[ "${output}" = "[${log_level}] ${log_context}: ${log_message}" ]]
}

@test "log: does not log a message when the log level is lower than LOG_LEVEL" {
    LOG_LEVEL="WARN"

    run log "DEBUG" "This is a DEBUG level message"

    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "log: context can be modified by modifying the LOG_CONTEXT_BUILDER" {
    log_level="INFO"
    log_message="This is an INFO level message"
    log_context="context1"
    context_var="morectx"

    LOG_CONTEXT_BUILDER="\${context_var}:${LOG_CONTEXT_BUILDER}"

    run log "${log_level}" "${log_message}" "${log_context}"

    [ "${status}" -eq 0 ]
    [[ "${output}" =~ "[${log_level}] ${context_var}:${log_context}: ${log_message}" ]]
}