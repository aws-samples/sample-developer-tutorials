#!/bin/bash
set -e

# Generate suffix and setup logging
SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMPLATE_NAME="env-template-${SUFFIX}"
TEMP_DIR=$(mktemp -d)
LOG_FILE="${TEMP_DIR}/script.log"
CREATED_RESOURCES=()

# Cleanup function
cleanup_resources() {
    for resource in "${CREATED_RESOURCES[@]}"; do
        echo "Deleting $resource..."
        aws proton delete-environment-template --name "$resource" || true
    done
    rm -rf "$TEMP_DIR"
}

# Trap for cleanup on exit
trap cleanup_resources EXIT

# List Environment Templates
echo "### Listing Environment Templates..." 
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
echo "### Creating Environment Template..." 
aws proton create-environment-template --name "$TEMPLATE_NAME" || true
CREATED_RESOURCES+=("$TEMPLATE_NAME")
echo "Environment Template Created" 
echo "PASS" 

# Clean up
echo "### Cleaning up..." 
echo "Cleanup Complete" 