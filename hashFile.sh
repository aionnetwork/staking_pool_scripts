#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# This script can be used to hash the pool meta-data json file.
#
# Usage: ./hashFile.sh path_to_file
# -----------------------------------------------------------------------------
TOOLS_JAR=Tools.jar

file_path="$1"

if [ $# -ne 1 ]
then
    echo "Invalid number of parameters."
    echo "Usage: ./hashFile.sh path_to_file"
    exit 1
fi

hash="$(java -cp $TOOLS_JAR cli.HashFile "$file_path")"
echo "Meta-data content hash:"
echo "$hash"