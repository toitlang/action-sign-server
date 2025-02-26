#!/bin/bash

# A small script that updates the README for releases.
# Arguments to the script
# 1. the new release-hash
# 2. the version number

hash=$1
version=$2

HASH_MARKER='${HASH}'
VERSION_MARKER='${VERSION}'

# Replace the old hash and version with the new hash and version in
# the README.md file.
sed "s/$HASH_MARKER/$hash/g" README.md.in > README.md
sed -i "s/$VERSION_MARKER/$version/g" README.md
