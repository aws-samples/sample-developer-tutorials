#!/bin/bash
set -e
SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)

echo "=== SSM Quick Setup Tutorial ==="
echo "Quick Setup helps you configure AWS services and features across"
echo "your organization with recommended best practices."
echo ""

echo "=== Listing configuration managers ==="
echo "Configuration managers define how Quick Setup deploys configurations."
MANAGERS_COUNT=$(aws ssm-quicksetup list-configuration-managers --query 'length(ConfigurationManagersList)' --output text)
echo "Configuration managers: $MANAGERS_COUNT"
echo ""

echo "=== Getting service settings ==="
echo "Service settings show the current Quick Setup configuration for your account."
SETTINGS=$(aws ssm-quicksetup get-service-settings --query 'ServiceSettings.ExplorerEnablingRoleArn' --output text || echo "not set")
echo "Explorer enabled: $SETTINGS"
echo ""

echo "=== Tutorial complete ==="
echo "To create a configuration, use create_configuration_manager with a"
echo "configuration definition specifying the target service and parameters."
echo "PASS"