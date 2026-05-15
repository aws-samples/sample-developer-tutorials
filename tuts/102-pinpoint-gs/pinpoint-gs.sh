#!/bin/bash
set -e

# Title Banner
echo "=== AWS Pinpoint Tutorial: Creating and Managing Applications ==="
echo "This tutorial will guide you through creating, retrieving, and listing Amazon Pinpoint applications using the AWS CLI."
echo "You will learn how to manage AWS resources programmatically and understand the basics of Amazon Pinpoint."
echo ""

REGION="us-east-1"
SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
LOG_FILE="${TEMP_DIR}/log.txt"
declare -a CREATED_RESOURCES=()

cleanup_resources() {
    for (( i=${#CREATED_RESOURCES[@]}-1; i>=0; i-- )); do
        RESOURCE=(${CREATED_RESOURCES[i]})
        case ${RESOURCE[0]} in
            "pinpoint-app") aws pinpoint delete-app --application-id ${RESOURCE[1]} ;;
        esac
    done
    rm -rf ${TEMP_DIR}
}
trap cleanup_resources EXIT

if [ -t 1 ]; then 
echo "=== Step 1: Generating a Unique Suffix ==="
echo "To ensure our Pinpoint application has a unique name, we generate a random suffix."
echo "This helps avoid naming conflicts with other applications."
echo ""
echo "Generated Suffix: ${SUFFIX}"
echo ""

echo "=== Step 2: Creating a Temporary Directory ==="
echo "We create a temporary directory to store log files and other temporary data."
echo "This helps keep our workspace clean and organized."
echo ""
echo "Temporary Directory: ${TEMP_DIR}"
echo ""

echo "=== Step 3: Creating a Pinpoint Application ==="
echo "We will now create a new Amazon Pinpoint application. This application will be used to send messages to users."
echo "The application name is unique to avoid conflicts with existing applications."
echo ""
APP_NAME="my-app-${SUFFIX}"
APP_ID=$(aws pinpoint create-app --create-application-request '{"Name":"'${APP_NAME}'"}' --query 'ApplicationResponse.Id' --output text)
echo "Pinpoint application created with ID: ${APP_ID}"
CREATED_RESOURCES+=("pinpoint-app:${APP_ID}")
echo ""

echo "=== Step 4: Retrieving the Newly Created Application ==="
echo "Next, we retrieve the details of the newly created Pinpoint application to verify its creation."
echo "This step ensures that the application was created successfully and allows us to view its properties."
echo ""
aws pinpoint get-app --application-id ${APP_ID}
echo ""

echo "=== Step 5: Listing All Pinpoint Applications ==="
echo "Finally, we list all Pinpoint applications in the specified region to see the newly created application among others."
echo "This helps us understand the overall environment and the applications we have access to."
echo ""
aws pinpoint get-apps
echo ""

echo "PASS" >> ${LOG_FILE}

echo "=== Tutorial Complete ==="
echo "In this tutorial, you learned how to:"
echo "1. Generate a unique suffix for resource naming."
echo "2. Create a temporary directory for storing log files."
echo "3. Create a new Amazon Pinpoint application."
echo "4. Retrieve the details of the newly created application."
echo "5. List all Pinpoint applications in the region."
echo "These steps"
fi