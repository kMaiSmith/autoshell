#!/usr/bin/env bash

task.exec() {
    local dir
    local -a files

    task.get_config dir
    task.get_config files

    log INFO "Creating staging directory: ${dir}"
    rm -rf "${dir}"
    mkdir -p "${dir}"

    log INFO "Copying files:"
    cd "${dir}" || \
        fatal "Could not enter staging directory"
    for cp_expr in "${files[@]}"; do
        [ -n "${cp_expr}" ] || \
            continue

        log INFO " - ${cp_expr}"
        local IFS=":"
        local -a cp_files=(${cp_expr})
        [ "${#cp_files[@]}" -gt 1 ] || \
            fatal "stage.files: ${cp_expr}: destination not specified"

        mkdir -p "$(dirname "${cp_files[-1]}")"
        cp -r "${cp_files[@]}"
    done
}