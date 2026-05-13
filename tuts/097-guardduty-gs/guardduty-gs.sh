#!/bin/bash
# Enable threat detection
# Resources created: GuardDuty Detector

set -euo pipefail

UNIQUE_ID=$(head -c 8 /dev/urandom | tr -dc '[:alnum:]')
LOG_FILE="guardduty-tutorial-${UNIQUE_ID}.log"
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
        IFS=':' read -r type name <<< "$resource"
        echo "Deleting $type: $name"
        if [[ "$type" == "detector" ]]; then
            aws guardduty delete-detector --detector-id "$name" || true
        fi
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
DETECTOR_ID=$(aws guardduty create-detector --enable --query 'DetectorId' --output text)
check_error "$?" "creating detector"
CREATED_RESOURCES+=("detector:$DETECTOR_ID")

echo "=== Step 2: Verify ==="
aws guardduty get-detector --detector-id "$DETECTOR_ID"
aws guardduty list-detectors
aws guardduty list-findings --detector-id "$DETECTOR_ID"

echo "=== Summary ==="
echo "Created resources:"
for resource in "${CREATED_RESOURCES[@]}"; do
    echo "$resource"
done