#!/bin/bash
set -e

cleanup_resources() {
  for resource in "${CREATED_RESOURCES[@]}"; do
    echo "Cleaning up resource: $resource"
    case $resource in
      application/*) aws appconfig delete-application --application-id "${resource#application/}" || true ;;
      configuration-profile/*) aws appconfig delete-configuration-profile --application-id "${resource#configuration-profile/}" || true ;;
      deployment-strategy/*) aws appconfig delete-deployment-strategy --deployment-strategy-id "${resource#deployment-strategy/}" || true ;;
      environment/*) aws appconfig delete-environment --application-id "${resource#environment/}" || true ;;
      extension/*) aws appconfig delete-extension --extension-id "${resource#extension/}" || true ;;
    esac
  done
}

trap cleanup_resources EXIT

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
CREATED_RESOURCES=()

echo "Creating an application..."
APPLICATION_ID=$(aws appconfig create-application --name "app-$SUFFIX" --tags '{"Project":"Tutorial","Environment":"Dev"}' --query 'Id' --output text)
CREATED_RESOURCES+=("application/$APPLICATION_ID")

echo "Creating a configuration profile..."
CONFIG_PROFILE_ID=$(aws appconfig create-configuration-profile --application-id "$APPLICATION_ID" --name "config-$SUFFIX" --location-uri "ssm-parameter://tutorial-param" --retrieval-role-arn "$ROLE_ARN" --tags '{"Project":"Tutorial","Environment":"Dev"}' --query 'Id' --output text)
CREATED_RESOURCES+=("configuration-profile/$CONFIG_PROFILE_ID")

echo "Creating a deployment strategy..."
DEPLOYMENT_STRATEGY_ID=$(aws appconfig create-deployment-strategy --name "strategy-$SUFFIX" --deployment-duration-in-minutes 15 --final-bake-time-in-minutes 30 --growth-factor 25 --growth-type LINEAR --tags '{"Project":"Tutorial","Environment":"Dev"}' --query 'Id' --output text)
CREATED_RESOURCES+=("deployment-strategy/$DEPLOYMENT_STRATEGY_ID")

echo "Creating an environment..."
ENVIRONMENT_ID=$(aws appconfig create-environment --application-id "$APPLICATION_ID" --name "env-$SUFFIX" --tags '{"Project":"Tutorial","Environment":"Dev"}' --query 'Id' --output text)
CREATED_RESOURCES+=("environment/$ENVIRONMENT_ID")

echo "PASS"
