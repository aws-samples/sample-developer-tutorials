#!/bin/bash
set -e
SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
LOG_FILE="${TEMP_DIR}/script.log"
CREATED_RESOURCES=()
trap cleanup_resources EXIT

cleanup_resources() {
    # Add cleanup logic if necessary
}

echo "Calling list-price-lists..." &>> "$LOG_FILE"
aws pricing list-price-lists --output text &>> "$LOG_FILE"

echo "Calling describe-services..." &>> "$LOG_FILE"
aws pricing describe-services --service-code AmazonEC2 --output text &>> "$LOG_FILE"

echo "Calling get-attribute-values..." &>> "$LOG_FILE"
aws pricing get-attribute-values --service-code AmazonEC2 --attribute-name volumeType --output text &>> "$LOG_FILE"

echo "Calling get-price-list-file-url..." &>> "$LOG_FILE"
aws pricing get-price-list-file-url --file-format JSON --compression-format GZIP --service-code AmazonEC2 --output text &>> "$LOG_FILE"

echo "Calling get-products..." &>> "$LOG_FILE"
aws pricing get-products --service-code AmazonEC2 --filters Type=TERM_MATCH,Field=volumeType,Value=gp2 --output text &>> "$LOG_FILE"

echo "PASS"