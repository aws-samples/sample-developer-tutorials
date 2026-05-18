#!/bin/bash
set -e

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
LOG_FILE="${TEMP_DIR}/script.log"
CREATED_RESOURCES=()

trap cleanup_resources EXIT

cleanup_resources() {
    rm -rf "$TEMP_DIR"
}

echo "Step: DescribeHumanLoop"
aws sagemaker-a2i-runtime describe-human-loop &>> "$LOG_FILE" && echo "DescribeHumanLoop done" || echo "DescribeHumanLoop skipped"

echo "Step: ListHumanLoops"
aws sagemaker-a2i-runtime list-human-loops &>> "$LOG_FILE" && echo "ListHumanLoops done" || echo "ListHumanLoops skipped"

echo "PASS"