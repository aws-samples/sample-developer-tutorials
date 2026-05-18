#!/bin/bash
set -e
TEMP_DIR=$(mktemp -d)
LOG_FILE="$TEMP_DIR/log.txt"
CREATED_RESOURCES=()

cleanup_resources() {
  rm -rf "$TEMP_DIR"
}
trap cleanup_resources EXIT

echo "=== SSM Quick Setup Tutorial ==="
echo "Quick Setup helps you configure AWS services and features across"
echo "your organization with recommended best practices."
echo ""

echo "=== Listing configuration managers ==="
MANAGERS_COUNT=$(aws ssm-quicksetup list-configuration-managers --query 'length(ConfigurationManagersList)' --output text)
echo "Configuration managers: $MANAGERS_COUNT"
echo ""

echo "=== Getting service settings ==="
SETTINGS=$(aws ssm-quicksetup get-service-settings --query 'ServiceSettings.ExplorerEnablingRoleArn' --output text || echo "not set")
echo "Explorer enabled: $SETTINGS"
echo ""

echo "=== Tutorial complete ==="
echo "To create a configuration, use create_configuration_manager with a"
echo "configuration definition specifying the target service and parameters."
echo "PASS"