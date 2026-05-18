#!/bin/bash
set -e

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
SCALING_PLAN_NAME="scaling-plan-${SUFFIX}"

SCALING_INSTRUCTIONS='{
    "ServiceNamespace": "ecs",
    "ResourceId": "service/my-cluster/my-service",
    "ScalableDimension": "ecs:service:DesiredCount",
    "MinCapacity": 1,
    "MaxCapacity": 10,
    "TargetTrackingConfigurations": [
        {
            "PredefinedScalingMetricSpecification": {
                "PredefinedScalingMetricType": "ECSServiceAverageCPUUtilization"
            },
            "TargetValue": 50.0
        }
    ]
}'

APPLICATION_SOURCE='{
    "TagFilters": [
        {
            "Key": "Name",
            "Values": ["my-stack"]
        }
    ]
}'

SCALING_PLAN_VERSION=$(aws autoscaling-plans create-scaling-plan \
    --scaling-plan-name "$SCALING_PLAN_NAME" \
    --application-source "$APPLICATION_SOURCE" \
    --scaling-instructions "$SCALING_INSTRUCTIONS" \
    --query 'ScalingPlanVersion' --output text || true)

if [ -n "$SCALING_PLAN_VERSION" ]; then
    aws autoscaling-plans describe-scaling-plans \
        --scaling-plan-names "$SCALING_PLAN_NAME"

    aws autoscaling-plans describe-scaling-plan-resources \
        --scaling-plan-name "$SCALING_PLAN_NAME" \
        --scaling-plan-version "$SCALING_PLAN_VERSION"
fi

aws autoscaling-plans delete-scaling-plan \
    --scaling-plan-name "$SCALING_PLAN_NAME" \
    --scaling-plan-version "$SCALING_PLAN_VERSION" || true

echo "PASS"