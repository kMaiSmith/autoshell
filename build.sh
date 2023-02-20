#!/bin/bash

declare -x SOURCE_ROOT
SOURCE_ROOT=$(cd "$(dirname "${0}")"; pwd)

declare -x STSH_ROOT="${SOURCE_ROOT}/src"
declare -x PATH="${SOURCE_ROOT}/scripts:${PATH}"

[ -f "${SOURCE_ROOT}/build.config.sh" ] && \
    . "${SOURCE_ROOT}/build.config.sh"

src/stsh "${@}"
