#!/bin/bash
set -e

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
LOG_FILE="${TEMP_DIR}/script.log"
CREATED_RESOURCES=()

cleanup_resources() {
    for resource in "${CREATED_RESOURCES[@]}"; do
        aws simpledbv2 delete-domain-export --domain-export-name "$resource" &>> "$LOG_FILE"
    done
}

trap cleanup_resources EXIT

list_exports_response=$(aws simpledbv2 list-exports --output text --query 'Exports[*].Name' &>> "$LOG_FILE")
echo "ListExports: $list_exports_response"

domain_export_name="example-domain-export-${SUFFIX}"
start_domain_export_response=$(aws simpledbv2 start-domain-export --domain-export-name "$domain_export_name" --domain-name "example-domain" --output text --query 'ExportId' &>> "$LOG_FILE")
echo "StartDomainExport: $start_domain_export_response"
CREATED_RESOURCES+=("$domain_export_name")

get_export_response=$(aws simpledbv2 get-export --export-id "$start_domain_export_response" &>> "$LOG_FILE")
echo "GetExport: $get_export_response"

echo "PASS"