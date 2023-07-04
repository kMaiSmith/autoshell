#!/usr/bin/env bats

export \
    TASKLOG_COMPLETION_MARK="#" \
    TASKLOG_PENDING_MARK="~" \
    TASKLOG_FILE

tasklog.initialize() {
    [ -n "${TASKLOG_FILE-}" ] || \
        TASKLOG_FILE="$(mktemp)"
}
export -f tasklog.initialize

tasklog.is_complete() {
    local task_name="${1}"

    grep -q "^${task_name}:${TASKLOG_COMPLETION_MARK}" "${TASKLOG_FILE}"
}
export -f tasklog.is_complete

tasklog.set_entry() {
    local task_name="${1}"
    local task_mark="${2-}"

    sed -i "/^${task_name}:/d" "${TASKLOG_FILE}"
    echo "${task_name}:${task_mark-}" >> "${TASKLOG_FILE}"
}
export -f tasklog.set_entry

tasklog.get_next_pending() {
    grep -v -m1 ".*:${TASKLOG_COMPLETION_MARK}$" "${TASKLOG_FILE}" | \
        awk -F: '{print $1}'
}
export -f tasklog.get_next_pending