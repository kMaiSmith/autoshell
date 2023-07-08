#!/usr/bin/env bash

task.dependencies() {
    depends_on "package.stage"
}

task.exec() {
    local archive dir

    task.get_config archive
    task.get_config dir package.stage

    log INFO "Creating archive: ${archive}"
    mkdir -p "$(dirname "${archive}")"
    tar -czf "${archive}" -C "${dir}" ./
}