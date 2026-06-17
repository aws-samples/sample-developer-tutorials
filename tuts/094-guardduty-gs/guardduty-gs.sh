#!/bin/bash
set -e

echo "=== AWS GuardDuty Setup Tutorial ==="
echo "This tutorial will guide you through setting up an AWS GuardDuty detector, creating a filter, an IP set, and a threat intel set."

REGION="us-east-1"
SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
LOG_FILE="$TEMP_DIR/script.log"
declare -a CREATED_RESOURCES=()

if [ -t 1 ]; then 
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

echo "=== Step 1: Checking for existing detector ==="
echo "GuardDuty detectors are essential for monitoring and protecting your AWS accounts."
echo "We first check if an existing detector is available to avoid creating duplicates."
DETECTOR_ID=$(aws guardduty list-detectors --query 'DetectorIds[0]' --output text || true)
echo "Result: $DETECTOR_ID"
echo ""

if [ -z "$DETECTOR_ID" ]; then
    echo "=== Step 2: Creating detector ==="
    echo "Since no detector was found, we create a new one. This enables GuardDuty in your account."
    DETECTOR_ID=$(aws guardduty create-detector --enable --tags Key=project,Value=doc-smith Key=tutorial,Value=guardduty-gs --query 'DetectorId' --output text)
    echo "Detector created: $DETECTOR_ID" 
    CREATED_RESOURCES+=("detector:$DETECTOR_ID")
else
    echo "Detector already exists: $DETECTOR_ID"
fi
echo ""

echo "=== Step 3: Creating filter ==="
echo "Filters in GuardDuty allow you to focus on specific types of findings."
echo "We create a filter to capture unauthorized access attempts via SSH brute force."
FILTER_NAME="filter-${SUFFIX}"
aws guardduty create-filter --detector-id $DETECTOR_ID --tags Key=project,Value=doc-smith Key=tutorial,Value=guardduty-gs --name $FILTER_NAME --finding-criteria '{"Criterion":{"type":{"Eq":["UnauthorizedAccess:EC2/SSHBruteForce"]}}}' || true
echo "Filter created: $FILTER_NAME" 
CREATED_RESOURCES+=("filter:$DETECTOR_ID:$FILTER_NAME")
echo ""

echo "=== Step 4: Creating IP set ==="
echo "IP sets in GuardDuty help you define a list of trusted or malicious IP addresses."
echo "We create an IP set to specify a list of IPs to monitor."
IP_SET_NAME="ip-set-${SUFFIX}"
aws guardduty create-ip-set --detector-id $DETECTOR_ID --tags Key=project,Value=doc-smith Key=tutorial,Value=guardduty-gs --name $IP_SET_NAME --format TXT --location /test-files/ip-set.txt --activate || true
IP_SET_ID=$(aws guardduty list-ip-sets --detector-id $DETECTOR_ID --query "IpSetIds[?contains(Name, \`$IP_SET_NAME\`)]" --output text)
echo "IP set created: $IP_SET_NAME" 
CREATED_RESOURCES+=("ip-set:$DETECTOR_ID:$IP_SET_ID")
echo ""

echo "=== Step 5: Creating threat intel set ==="
echo "Threat intel sets in GuardDuty allow you to upload your own threat intelligence."
echo "We create a threat intel set to include a list of known malicious IP addresses."
THREAT_INTEL_SET_NAME="threat-intel-set-${SUFFIX}"
aws guardduty create-threat-intel-set --detector-id $DETECTOR_ID --tags Key=project,Value=doc-smith Key=tutorial,Value=guardduty-gs --name $THREAT_INTEL_SET_NAME --format TXT --location /test-files/threat-intel-set.txt --activate || true
THREAT_INTEL_SET_ID=$(aws guardduty list-threat-intel-sets --detector-id $DETECTOR_ID --query "ThreatIntelSetIds[?contains(Name, \`$THREAT_INTEL_SET_NAME\`)]" --output text)
echo "Threat intel set created: $THREAT_INTEL_SET_NAME" 
CREATED_RESOURCES+=("threat-intel-set:$DETECTOR_ID:$THREAT_INTEL_SET_ID")
echo ""
fi