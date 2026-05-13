#!/bin/bash
# Create a hosted zone and manage DNS records
# Resources created: Hosted Zone, DNS Records

set -euo pipefail

UNIQUE_ID=$(date +%s | sha256sum | base64 | head -c 8)
LOG_FILE="route53-tutorial-${UNIQUE_ID}.log"
touch "$LOG_FILE"
chmod 600 "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

check_error() {
    if echo "$1" | grep -iqE "error|failed"; then
        echo "ERROR in $2: $1" >&2
        return 1
    fi
}

declare -a CREATED_RESOURCES=()

cleanup_resources() {
    echo "=== Cleaning up resources ==="
    for (( i=${#CREATED_RESOURCES[@]}-1; i>=0; i-- )); do
        resource="${CREATED_RESOURCES[$i]}"
        IFS=':' read -r type id <<< "$resource"
        echo "Deleting $type: $id"
        case "$type" in
            "hosted-zone")
                aws route53 delete-hosted-zone --id "$id" || true
                ;;
            *)
                echo "Unknown resource type: $type" >&2
                ;;
        esac
    done
}
trap cleanup_resources EXIT

# Region check
if [[ -z "$(aws configure get region 2>/dev/null)" ]] && [[ -z "${AWS_DEFAULT_REGION:-}" ]] && [[ -z "${AWS_REGION:-}" ]]; then
    echo "ERROR: No AWS region configured"
    exit 1
fi

# Credentials check
aws sts get-caller-identity > /dev/null 2>&1 || { echo "ERROR: Invalid credentials"; exit 1; }

echo "=== Step 1: Create resources ==="
HOSTED_ZONE_NAME="example-${UNIQUE_ID}.com."
HOSTED_ZONE_ID=$(aws route53 create-hosted-zone --name "$HOSTED_ZONE_NAME" --caller-reference "$UNIQUE_ID" --query 'HostedZone.Id' --output text)
check_error "$?" "create-hosted-zone"
CREATED_RESOURCES+=("hosted-zone:$HOSTED_ZONE_ID")
echo "Created Hosted Zone: $HOSTED_ZONE_NAME with ID: $HOSTED_ZONE_ID"

echo "Adding DNS records"
CHANGE_BATCH='{
  "Comment": "Adding DNS records",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "'"$HOSTED_ZONE_NAME"'",
        "Type": "A",
        "TTL": 300,
        "ResourceRecords": [
          {
            "Value": "192.0.2.1"
          }
        ]
      }
    }
  ]
}'
aws route53 change-resource-record-sets --hosted-zone-id "$HOSTED_ZONE_ID" --change-batch "$CHANGE_BATCH"
check_error "$?" "change-resource-record-sets"
echo "Added DNS records to Hosted Zone: $HOSTED_ZONE_NAME"

echo "=== Step 2: Verify ==="
echo "Listing resource record sets for Hosted Zone: $HOSTED_ZONE_NAME"
aws route53 list-resource-record-sets --hosted-zone-id "$HOSTED_ZONE_ID"
check_error "$?" "list-resource-record-sets"

echo "=== Summary ==="
echo "Created resources:"
for resource in "${CREATED_RESOURCES[@]}"; do
    IFS=':' read -r type name <<< "$resource"
    echo "- $type: $name"
done