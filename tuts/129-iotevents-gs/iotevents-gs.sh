#!/bin/bash
set -e

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT
CREATED_RESOURCES=()

echo "Creating input..."
INPUT_NAME="test-input-$SUFFIX"
INPUT_DEFINITION='{"attributes":[{"name":"attribute1"}]}'
INPUT_ARN=$(aws iotevents create-input --input-name "$INPUT_NAME" --input-definition "$INPUT_DEFINITION" --query 'inputConfiguration.inputArn' --output text)
CREATED_RESOURCES+=("$INPUT_ARN")

echo "Verifying input creation..."
aws iotevents describe-input --input-name "$INPUT_NAME"

if [[ -n "${TUTORIAL_ROLE_ARN:-}" ]]; then
  echo "Creating detector model..."
  DETECTOR_MODEL_NAME="test-detector-model-$SUFFIX"
  DETECTOR_MODEL_DEFINITION='{"states":[{"stateName":"state1","onInput":{"events":[{"eventName":"event1","condition":"true","actions":[{"sns":{"targetArn":"arn:aws:sns:region:account-id:topic"}}}]}],"initialStateName":"state1"}'
  ROLE_ARN=${TUTORIAL_ROLE_ARN}
  DETECTOR_MODEL_ARN=$(aws iotevents create-detector-model --detector-model-name "$DETECTOR_MODEL_NAME" --detector-model-definition "$DETECTOR_MODEL_DEFINITION" --role-arn "$ROLE_ARN" --query 'detectorModelConfiguration.detectorModelArn' --output text)
  CREATED_RESOURCES+=("$DETECTOR_MODEL_ARN")

  echo "Verifying detector model creation..."
  aws iotevents describe-detector-model --detector-model-name "$DETECTOR_MODEL_NAME"
fi

echo "PASS"
