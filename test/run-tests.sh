#!/bin/bash

# Use this to allow the pattern looking for git versions to give the null string
shopt -s nullglob

TEST_DIR="$(dirname ${BASH_SOURCE[0]})"
SETUP_GIT_VERSIONS="$(realpath "$TEST_DIR/setup-git-versions.sh" --relative-to "$(pwd)")"

usage() {
    cat <<EOF
Usage: $0 [<options>] [<bats-args>]

Run bats tests for git-pile using different versions of git.

By default, it uses the minimal supported version and the latest version to run
tests (you need to set them up with "$SETUP_GIT_VERSIONS" first).

If <bats-args> are omitted, then the default is to pass "$TEST_DIR" as the only
positional argument to bats.

Options:

--exclude-versions
    Do not use git versions created by "$SETUP_GIT_VERSIONS".

--include-system-git
    Include the system's git binary to the tests.

--include-git <path>
    Include the git binary pointed by <path> to the tests.

-h, --help
    Show this help message and exit.
EOF
}

include_system_git="no"
include_versions="yes"
gits=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --include-git)
            shift
            if [[ $# -eq 0 ]]; then
                echo "missing argument to --include-git" >&2
                exit 1
            fi
            gits+=("$(realpath "$1")")
            ;;
        --exclude-versions)
            include_versions="no"
            ;;
        --include-system-git)
            include_system_git="yes"
            ;;
        --help | -h)
            usage
            exit 0
            ;;
        *)
            # Rest of arguments are to be passed to bats
            break
    esac
    shift
done

if [[ $# -eq 0 ]]; then
    set -- "$TEST_DIR"
fi

if [[ "$include_versions" == "yes" ]]; then
    gits+=("$TEST_DIR"/git-versions/versions/*/bin/git)
fi

if [[ "$include_system_git" == "yes" ]]; then
    system_git="$(type -p git)"
    if [[ -z "$system_git" ]]; then
        echo "path system's git binary not found"
    fi
    gits+=("$system_git")
fi

if [[ ${#gits[@]} -eq 0 ]]; then
    echo "No git binary to use." >&2
    if [[ "$include_versions" == "yes" ]]; then
        echo "You can set up the git binaries with $SETUP_GIT_VERSIONS." >&2
    fi
    exit 1
fi

for git in "${gits[@]}"; do
    echo "Running tests with GIT=\"$git\""
    GIT="$git" bats "$@"
done
