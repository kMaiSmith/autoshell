# Structured Autoshell

Automation scripts are best written to act as permanent documentation for how
to interact with a project or system.  Autoshell provides a framework for
writing predictable, understandable, and testable shell scripts.

## Overview

Autoshell is a modular shell automation framework targeting Bash, providing
structure to simplify the process of creating, managing, and executing scripts
in an automation/CICD environment. Autoshell aims to make it easier to work
with shell scripts by providing a collection of helpful tools and libraries, as
well as patterns to make writing human-readable scripts easy.

## Architecture

Autoshell consists of the following components:

 - Execution entrypoint `auto` for executing
 - A TOML parsing library (libautoshell.toml.sh) to load configurations from autoshell.toml files.
 - A BATS testing framework to unit and integration test all components.
 - A logging framework for detailed debugging of the Bash scripts.
 - A script for bundling the base scripts and libraries into a self-extracting shell executable to be distributed for use in other code repositories.
 - Support for extensions for specific applications, such as specific build tools or credential management.

## Getting Started

Execute the hello_world task via entrypoint script:

``` bash

./auto task hello_world
```

### Key Functions

 - include: Include another shell script, only permitting function definitions.
 - try: Try an expression in a subshell, always return gracefully.
 - log: Log a message about the current process.
 - fatal: Log a FATAL message and exit the current process.

Refer to src/lib/libautoshell.sh file for more information on each function's usage.

### Unit Tests

Autoshell utilizes the BATS (Bash Automated Testing System) framework for unit testing its components. To run the tests, follow these steps:

 - Install BATS (https://bats-core.readthedocs.io/en/latest/install.html)
 - Run the test suite:

``` bash

PATH="${PATH}:${PWD}/src/bin" bats test/*/
```

Refer to the test/ directory to see the test cases for each function.

## Contributions

Contributions to the Autoshell project are welcomed. Please follow the standard GitHub workflow for submitting your changes:

 - Fork the repository.
 - Create a new branch for your feature or bugfix.
 - Commit your changes to the branch.
 - Open a pull request to merge your changes into the main repository.

Before submitting your pull request, please ensure that you have tested your changes using the provided BATS test suite and that you have updated the documentation accordingly.

# License

Autoshell is released under the MIT License. See LICENSE for details.
