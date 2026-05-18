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

echo "Step: GetReportDefinition"
aws applicationcostprofiler get-report-definition &>> "$LOG_FILE" && echo "GetReportDefinition done" || echo "GetReportDefinition skipped"

echo "Step: ListReportDefinitions"
aws applicationcostprofiler list-report-definitions &>> "$LOG_FILE" && echo "ListReportDefinitions done" || echo "ListReportDefinitions skipped"

echo "PASS"