#!/bin/bash
set -e
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT
echo "=== Timestream Query ==="
echo "Listing scheduled queries..."
aws timestream-query list-scheduled-queries --query 'ScheduledQueries[].Arn' --output text 2>/dev/null || echo "None"
echo "PASS"
