#!/usr/bin/env bash

task.up_to_date() {
    [ -f "./myname" ] && [ -n "$(cat ./myname)" ]
}

task.exec() {
    read -rp "What is your name? " name
    echo "${name}" > ./myname
}