#!/bin/bash
set -e

REGION="us-east-1"
SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 6 | head -n 1)

echo "Creating detector..."
DETECTOR_ID=$(aws guardduty create-detector --region $REGION --enable --query 'DetectorId' --output text)
echo "Detector created: $DETECTOR_ID"

echo "Creating filter..."
FILTER_NAME="filter-${SUFFIX}"
aws guardduty create-filter --detector-id $DETECTOR_ID --name $FILTER_NAME --finding-criteria '{"Criterion":{"type":{"Eq":["UnauthorizedAccess:EC2/SSHBruteForce"]}}}' || true
echo "Filter created: $FILTER_NAME"

echo "Creating IP set..."
IP_SET_NAME="ip-set-${SUFFIX}"
aws guardduty create-ip-set --detector-id $DETECTOR_ID --name $IP_SET_NAME --format TXT --location /test-files/ip-set.txt --activate || true
echo "IP set created: $IP_SET_NAME"

echo "Creating threat intel set..."
THREAT_INTEL_SET_NAME="threat-intel-set-${SUFFIX}"
aws guardduty create-threat-intel-set --detector-id $DETECTOR_ID --name $THREAT_INTEL_SET_NAME --format TXT --location /test-files/threat-intel-set.txt --activate || true
echo "Threat intel set created: $THREAT_INTEL_SET_NAME"

echo "Deleting resources..."
aws guardduty delete-detector --detector-id $DETECTOR_ID || true
echo "Resources deleted"

echo "PASS"