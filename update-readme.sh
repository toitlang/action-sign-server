#!bash

# A small script that updates the README for releases.
# Arguments to the script
# 1. the new release-hash
# 2. the version number

hash=$1
version=$2

OLD_HASH="OLD-HASH"
OLD_VERSION="OLD-VERSION"

# Replace the old hash and version with the new hash and version in
# the README.md file and this script.
sed -i "s/$OLD_HASH/$hash/g" README.md
sed -i "s/$OLD_VERSION/$version/g" README.md
sed -i "s/$OLD_HASH/$hash/g" update-readme.sh
sed -i "s/$OLD_VERSION/$version/g" update-readme.sh
