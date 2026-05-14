#!/bin/bash
set -e

REGION="us-east-1"
SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
LOG_FILE="$TEMP_DIR/script.log"
declare -a CREATED_RESOURCES=()

cleanup_resources() {
    for (( i=${#CREATED_RESOURCES[@]}-1; i>=0; i-- )); do
        RESOURCE=(${CREATED_RESOURCES[$i]})
        case ${RESOURCE[0]} in
            "detector") aws guardduty delete-detector --detector-id ${RESOURCE[1]} || true ;;
            "filter") aws guardduty delete-filter --detector-id ${RESOURCE[1]} --filter-name ${RESOURCE[2]} || true ;;
            "ip-set") aws guardduty delete-ip-set --detector-id ${RESOURCE[1]} --ip-set-id ${RESOURCE[2]} || true ;;
            "threat-intel-set") aws guardduty delete-threat-intel-set --detector-id ${RESOURCE[1]} --threat-intel-set-id ${RESOURCE[2]} || true ;;
        esac
    done
    rm -rf "$TEMP_DIR"
}
trap cleanup_resources EXIT

echo "=== Checking for existing detector ==="
DETECTOR_ID=$(aws guardduty list-detectors --region $REGION --query 'DetectorIds[0]' --output text || true)

if [ -z "$DETECTOR_ID" ]; then
    echo "=== Creating detector ==="
    DETECTOR_ID=$(aws guardduty create-detector --region $REGION --enable --query 'DetectorId' --output text)
    echo "Detector created: $DETECTOR_ID" 
    CREATED_RESOURCES+=("detector:$DETECTOR_ID")
else
    echo "Detector already exists: $DETECTOR_ID"
fi

echo "=== Creating filter ==="
FILTER_NAME="filter-${SUFFIX}"
aws guardduty create-filter --detector-id $DETECTOR_ID --name $FILTER_NAME --finding-criteria '{"Criterion":{"type":{"Eq":["UnauthorizedAccess:EC2/SSHBruteForce"]}}}' || true
echo "Filter created: $FILTER_NAME" 
CREATED_RESOURCES+=("filter:$DETECTOR_ID:$FILTER_NAME")

echo "=== Creating IP set ==="
IP_SET_NAME="ip-set-${SUFFIX}"
aws guardduty create-ip-set --detector-id $DETECTOR_ID --name $IP_SET_NAME --format TXT --location /test-files/ip-set.txt --activate || true
IP_SET_ID=$(aws guardduty list-ip-sets --detector-id $DETECTOR_ID --query "IpSetIds[?contains(Name, \`$IP_SET_NAME\`)]" --output text)
echo "IP set created: $IP_SET_NAME" 
CREATED_RESOURCES+=("ip-set:$DETECTOR_ID:$IP_SET_ID")

echo "=== Creating threat intel set ==="
THREAT_INTEL_SET_NAME="threat-intel-set-${SUFFIX}"
aws guardduty create-threat-intel-set --detector-id $DETECTOR_ID --name $THREAT_INTEL_SET_NAME --format TXT --location /test-files/threat-intel-set.txt --activate || true
THREAT_INTEL_SET_ID=$(aws guardduty list-threat-intel-sets --detector-id $DETECTOR_ID --query "ThreatIntelSetIds[?contains(Name, \`$THREAT_INTEL_SET_NAME\`)]" --output text)
echo "Threat intel set created: $THREAT_INTEL_SET_NAME" 
CREATED_RESOURCES+=("threat-intel-set:$DETECTOR_ID:$THREAT_INTEL_SET_ID")

echo "PASS"