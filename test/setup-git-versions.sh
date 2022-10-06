#!/bin/bash

set -e

MIN_SUPPORTED_VERSION=2.19

TEST_DIR="$(dirname ${BASH_SOURCE[0]})"
GIT_VERSIONS_DIR="$TEST_DIR/git-versions"

BARE_REPO="$GIT_VERSIONS_DIR/repo/bare"
MIN_REPO="$GIT_VERSIONS_DIR/repo/minimal"
LATEST_REPO="$GIT_VERSIONS_DIR/repo/latest"


build_git() {
    local src="$1"
    local prefix="$(realpath "$2")"
    make -C "$src" prefix="$prefix" install
}

mkdir -p "$GIT_VERSIONS_DIR"

if [[ -e "$BARE_REPO" ]]; then
    git -C "$BARE_REPO" remote update
else
    git clone --bare https://github.com/git/git "$BARE_REPO"
    git -C "$BARE_REPO" worktree add ../latest
    git -C "$BARE_REPO" worktree add ../minimal
fi

LATEST_VERSION=$(git -C "$BARE_REPO" tag -l --sort=-v:refname 'v*.*.*' \
                    | grep -v -e '-.*$' | head -n1)

LATEST_MIN=$(git -C "$BARE_REPO" tag -l --sort=-v:refname "v${MIN_SUPPORTED_VERSION}.*" \
                | grep -v -e '-.*$' | head -n1)

git -C "$MIN_REPO" reset --hard "$LATEST_MIN"
git -C "$LATEST_REPO" reset --hard "$LATEST_VERSION"

mkdir -p "$GIT_VERSIONS_DIR/versions"
build_git "$MIN_REPO" "$GIT_VERSIONS_DIR/versions/minimal"
build_git "$LATEST_REPO" "$GIT_VERSIONS_DIR/versions/latest"
