#!/bin/bash

declare -x PROJECT_NAME="structured-shell"
declare -x PROJECT_VERSION="$(<VERSION)"
declare -x PROJECT_MAINTAINER="Kyle Smith <kyle@kmaismith.com>"
declare -x PROJECT_DESCRIPTION="$(cat <<EOD
Structured Shell (STSH) is a script execution framework extending the power of
  BASH Shell scripting with safer programming paradigms.
EOD
)"

declare -x BUILD_ROOT="${SOURCE_ROOT}/build"