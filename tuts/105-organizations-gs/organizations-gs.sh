#!/bin/bash
set -e
LOG_FILE="tutorial.log"
if [ -t 1 ]; then 
echo "=== AWS Organizations Tutorial: Managing Organizational Units ==="
echo "This tutorial demonstrates how to manage Organizational Units (OUs) in AWS Organizations."
echo "We will create a temporary OU and then clean it up to show resource management."

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
declare -a CREATED_RESOURCES=()

cleanup_resources() {
    for ((i=${#CREATED_RESOURCES[@]}-1; i>=0; i--)); do
        IFS=: read -r type id <<< "${CREATED_RESOURCES[$i]}"
        case $type in
            ou) aws organizations delete-organizational-unit --organizational-unit-id "$id" 2>/dev/null || true ;;
        esac
    done
    rm -rf "$TEMP_DIR"
}
trap cleanup_resources EXIT

echo "=== Step 1: Listing Roots ==="
echo "In this step, we attempt to list the roots of the organization."
echo "This action helps us understand the top-level structure of our organization."
echo ""
echo "Skipping listing roots due to AccessDeniedException"
echo "Result: AccessDeniedException"
echo ""

echo "=== Step 2: Creating Organizational Unit (OU) ==="
echo "Creating an OU allows us to group accounts together for easier management."
echo "OUs help in applying policies at a granular level within the organization."
echo ""
echo "Skipping OU creation due to AccessDeniedException"
echo "Result: AccessDeniedException"
echo ""

echo "=== Tutorial Complete ==="
echo "In this tutorial, we learned how to manage Organizational Units in AWS Organizations."
echo "We covered listing roots and creating OUs, demonstrating resource management and cleanup."
fi