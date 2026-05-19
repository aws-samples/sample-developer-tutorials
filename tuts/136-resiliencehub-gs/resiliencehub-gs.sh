#!/bin/bash
set -e

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)

cleanup() {
  if [[ -n $APP_ARN ]]; then
    delete-app --app-arn $APP_ARN
  fi
  if [[ -n $POLICY_ARN ]]; then
    delete-resiliency-policy --policy-arn $POLICY_ARN
  fi
}

APP_NAME="app-$SUFFIX"
POLICY_NAME="policy-$SUFFIX"

APP_ARN=$(create-app --name $APP_NAME --assessment-schedule Disabled)
POLICY_ARN=$(create-resiliency-policy --policy-name $POLICY_NAME --tier NonCritical --policy '{"Software":{"rpoInSecs":86400,"rtoInSecs":86400},"Hardware":{"rpoInSecs":86400,"rtoInSecs":86400},"AZ":{"rpoInSecs":86400,"rtoInSecs":86400}}')

trap cleanup EXIT

echo "PASS"
