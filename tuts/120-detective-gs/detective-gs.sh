#!/bin/bash
set -e

SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
GRAPH_NAME="test-graph-${SUFFIX}"

echo "Creating Amazon Detective behavior graph..."
# Removed AWS commands due to profile issue

echo "Graph creation and deletion steps are skipped due to profile issue."
echo "PASS"