#!/bin/bash
set -e

# Generate a random suffix
SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)

# Create a temporary directory and clean up on exit
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Describe Home Region Controls
echo "Calling DescribeHomeRegionControls..."
aws migrationhub-config describe-home-region-controls --query 'HomeRegionControls[].ControlId' --output text > $TEMP_DIR/control_ids_before.txt
cat $TEMP_DIR/control_ids_before.txt

# Get Home Region
echo "Calling GetHomeRegion..."
HOME_REGION=$(aws migrationhub-config get-home-region --query 'HomeRegion' --output text)
echo $HOME_REGION

# Create Home Region Control
echo "Calling CreateHomeRegionControl..."
CONTROL_ID="test-control-$SUFFIX"
aws migrationhub-config create-home-region-control --home-region us-east-1 --target "Type=ACCOUNT,Id=$(aws sts get-caller-identity --query 'Account' --output text)"

# Describe Home Region Controls again
echo "Calling DescribeHomeRegionControls again..."
aws migrationhub-config describe-home-region-controls --query 'HomeRegionControls[].ControlId' --output text > $TEMP_DIR/control_ids_after.txt
cat $TEMP_DIR/control_ids_after.txt

# Delete Home Region Control
echo "Calling DeleteHomeRegionControl..."
NEW_CONTROL_ID=$(comm -13 $TEMP_DIR/control_ids_before.txt $TEMP_DIR/control_ids_after.txt)
aws migrationhub-config delete-home-region-control --control-id $NEW_CONTROL_ID

echo "PASS"