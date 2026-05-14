#!/bin/bash
set -e

SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
DETECTOR_MODEL_NAME="TestDetectorModel${SUFFIX}"
ROLE_ARN="arn:aws:iam::559823168634:role/doc-babu-iotevents-role"

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
  --role-arn "$ROLE_ARN" && echo "Created detector model: $DETECTOR_MODEL_NAME"

aws iotevents describe-detector-model \
  --detector-model-name "$DETECTOR_MODEL_NAME" && echo "Described detector model: $DETECTOR_MODEL_NAME"

aws iotevents delete-detector-model \
  --detector-model-name "$DETECTOR_MODEL_NAME" && echo "Deleted detector model: $DETECTOR_MODEL_NAME" || true

echo "PASS"