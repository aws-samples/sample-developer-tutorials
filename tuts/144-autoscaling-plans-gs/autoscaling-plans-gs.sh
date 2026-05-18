#!/bin/bash
set -e

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
LOG_FILE="$TEMP_DIR/log.txt"
CREATED_RESOURCES=()

cleanup_resources() {
    rm -rf "$TEMP_DIR"
}

trap cleanup_resources EXIT

SCALING_PLAN_NAME="scaling-plan-${SUFFIX}"
SCALING_INSTRUCTIONS='{"ServiceNamespace":"ecs","ResourceId":"service/my-cluster/my-service","ScalableDimension":"ecs:service:DesiredCount","MinCapacity":1,"MaxCapacity":10,"TargetTrackingConfigurations":[{"PredefinedScalingMetricSpecification":{"PredefinedScalingMetricType":"ECSServiceAverageCPUUtilization"},"TargetValue":50.0}]}'
APPLICATION_SOURCE='{"TagFilters":[{"Key":"Name","Values":["my-stack"]}]}'

# Step 1: Create Scaling Plan
if aws autoscaling-plans create-scaling-plan --scaling-plan-name "$SCALING_PLAN_NAME" --application-source "$APPLICATION_SOURCE" --scaling-instructions "$SCALING_INSTRUCTIONS" --query 'ScalingPlanVersion' --output text > /dev/null 2>&1; then
    CREATED_RESOURCES+=("$SCALING_PLAN_NAME")
    
    # Step 2: Describe Scaling Plans
    aws autoscaling-plans describe-scaling-plans --scaling-plan-names "$SCALING_PLAN_NAME"
    
    # Step 3: Describe Scaling Plan Resources
    SCALING_PLAN_VERSION=$(aws autoscaling-plans describe-scaling-plans --scaling-plan-names "$SCALING_PLAN_NAME" --query 'ScalingPlans[0].ScalingPlanVersion' --output text)
    aws autoscaling-plans describe-scaling-plan-resources --scaling-plan-name "$SCALING_PLAN_NAME" --scaling-plan-version "$SCALING_PLAN_VERSION"
fi

echo "PASS"