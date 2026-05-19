#!/bin/bash
set -e

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
DETECTOR_MODEL_NAME="TestDetectorModel${SUFFIX}"
ROLE_ARN="${TUTORIAL_ROLE_ARN:?Set TUTORIAL_ROLE_ARN to an IAM role ARN with iotevents permissions}"
TEMP_DIR=$(mktemp -d)
LOG_FILE="$TEMP_DIR/script.log"
CREATED_RESOURCES=()

cleanup_resources() {
  for resource in "${CREATED_RESOURCES[@]}"; do
    aws iotevents delete-detector-model --detector-model-name "$resource" || true
  done
  rm -rf "$TEMP_DIR"
}

trap cleanup_resources EXIT

echo "Creating detector model..."
DETECTOR_MODEL_DEFINITION='{
  "states": [
    {
      "stateName": "InitialState",
      "onInput": {
        "events": [
          {
            "eventName": "testEvent",
            "condition": "${sensorData.temperature} > 30",
            "actions": [
              {
                "sns": {
                  "targetArn": "arn:aws:sns:us-east-1:123456789012:test-topic"
                }
              }
            ]
          }
        ]
      },
      "onEnter": {
        "events": [
          {
            "eventName": "EnterEvent",
            "condition": "true",
            "actions": [
              {
                "setVariable": {
                  "variableName": "temp",
                  "value": "${sensorData.temperature}"
                }
              }
            ]
          }
        ]
      }
    }
  ]
}'

aws iotevents create-detector-model \
  --detector-model-name "$DETECTOR_MODEL_NAME" \
  --detector-model-definition "$DETECTOR_MODEL_DEFINITION" \
  --role-arn "$ROLE_ARN" \
  --tags Key=project,Value=doc-smith Key=tutorial,Value=iotevents-gs && echo "Created detector model: $DETECTOR_MODEL_NAME" >> "$LOG_FILE"
CREATED_RESOURCES+=("$DETECTOR_MODEL_NAME")

echo "Describing detector model..."
aws iotevents describe-detector-model \
  --detector-model-name "$DETECTOR_MODEL_NAME" && echo "Described detector model: $DETECTOR_MODEL_NAME" >> "$LOG_FILE"

echo "Deleting detector model..."
aws iotevents delete-detector-model \
  --detector-model-name "$DETECTOR_MODEL_NAME" && echo "Deleted detector model: $DETECTOR_MODEL_NAME" >> "$LOG_FILE"

echo "PASS"
