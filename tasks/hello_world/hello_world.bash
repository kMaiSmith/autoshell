#!/usr/bin/env bash

task.dependencies() {
    depends_on "hello_world.get_name"
    finalized_by "hello_world.goodbye"
}

task.exec() {
    task.get_config greeting
    name="$(cat ./myname)"

    log NOTICE "${greeting}, ${name}!"
}