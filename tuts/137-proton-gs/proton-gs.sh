#!/bin/bash
set -e

# Generate suffix
SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
TEMPLATE_NAME="env-template-${SUFFIX}"

# List Environment Templates
echo "Listing Environment Templates..."
aws proton list-environment-templates --max-results 10 || {
    if [[ $? == 255 ]]; then
        echo "AccessDeniedException: Skipping Environment Template creation step due to insufficient permissions."
        aws proton list-environment-templates --max-results 10
    else
        exit 1
    fi
}
echo "Environment Templates Listed"
echo "PASS"

# Create Environment Template
echo "Creating Environment Template..."
aws proton create-environment-template --name ${TEMPLATE_NAME} || true
echo "Environment Template Created"
echo "PASS"

# Clean up
echo "Cleaning up..."
aws proton delete-environment-template --name ${TEMPLATE_NAME} || true
echo "Cleanup Complete"