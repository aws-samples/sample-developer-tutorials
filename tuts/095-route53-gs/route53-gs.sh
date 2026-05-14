#!/bin/bash
set -e

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
LOG_FILE="${TEMP_DIR}/log.txt"
declare -a CREATED_RESOURCES=()

cleanup_resources() {
    for (( i=${#CREATED_RESOURCES[@]}-1; i>=0; i-- )); do
        resource=(${CREATED_RESOURCES[$i]})
        type=${resource[0]}
        id=${resource[1]}
        case $type in
            "hosted-zone") aws route53 delete-hosted-zone --id $id ;;
        esac
    done
    rm -rf "$TEMP_DIR"
}
trap cleanup_resources EXIT

REGION="${AWS_DEFAULT_REGION:-us-east-1}"
if [ -z "$REGION" ]; then
    echo "Region not configured. Please set the region using 'aws configure set region <region-name>'."
    exit 1
fi

echo "=== Creating Hosted Zone ==="
HOSTED_ZONE_ID=$(aws route53 create-hosted-zone --name "example-${SUFFIX}.com." --caller-reference $(date +%s) --query 'HostedZone.Id' --output text)
echo "Created Hosted Zone: ${HOSTED_ZONE_ID}"
CREATED_RESOURCES+=("hosted-zone:$HOSTED_ZONE_ID")

echo "=== Deleting Hosted Zone ==="
aws route53 delete-hosted-zone --id ${HOSTED_ZONE_ID}
echo "Deleted Hosted Zone"

echo "PASS"