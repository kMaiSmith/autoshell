#!/bin/bash

declare -x PROJECT_NAME="libsafescript"
declare -x PROJECT_VERSION="$(<VERSION)"
declare -x PROJECT_MAINTAINER="Kyle Smith <kyle@kmaismith.com>"
declare -x PROJECT_DESCRIPTION="$(cat <<EOD
SafeScript is a structured script execution framework extending the power of
  BASH with safer programming paradigms.
EOD
)"

declare -x BUILD_ROOT="${SOURCE_ROOT}/build"