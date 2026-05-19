#!/bin/bash
set -e
SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)

# Step 1: Create Variable
echo "Step 1: Creating a variable to be used in the detector."
VARIABLE_NAME="variable_${SUFFIX}"
aws frauddetector create-variable --name "${VARIABLE_NAME}" --data-type STRING --data-source EVENT --default-value UNKNOWN --description "Sample variable for tutorial" --tag-list Key=project,Value=doc-smith Key=tutorial,Value=frauddetector-gs --query 'path' --output text
echo "Variable ${VARIABLE_NAME} created."

# Step 2: Create Detector
echo "Step 2: Creating a detector to evaluate fraud."
DETECTOR_NAME="detector_${SUFFIX}"
aws frauddetector put-detector --detector-id "${DETECTOR_NAME}" --description "Sample detector for tutorial" --event-type sample_event --tag-list Key=project,Value=doc-smith Key=tutorial,Value=frauddetector-gs --query 'path' --output text
echo "Detector ${DETECTOR_NAME} created."

# Cleanup
echo "Cleanup."
aws frauddetector delete-variable --name "${VARIABLE_NAME}" || true
aws frauddetector delete-detectors --detector-id "${DETECTOR_NAME}" || true
echo "PASS"
