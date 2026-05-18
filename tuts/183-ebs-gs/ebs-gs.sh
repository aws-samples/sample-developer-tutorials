#!/bin/bash
set -e

# Create a temporary directory and clean up on exit
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Print statuses
echo "PASS"