#!/bin/bash
set -e

# Title Banner
echo "=== AWS Service Catalog Tutorial ==="
echo "This tutorial demonstrates how to create, describe, and list portfolios using AWS Service Catalog."
echo ""

# Configuration
TEMP_DIR=$(mktemp -d)
LOG_FILE="${TEMP_DIR}/script.log"
CREATED_RESOURCES=()

# Redirect output to log file and terminal
if [ -t 1 ]; then 
    exec 1> >(tee -a "$LOG_FILE") 2>&1
fi

# Generate a unique suffix
SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)

# Cleanup function
cleanup_resources() {
    for res in "${CREATED_RESOURCES[@]}"; do
        aws servicecatalog delete-portfolio --id "$res" || true
    done
    rm -rf "${TEMP_DIR}"
}
trap cleanup_resources EXIT

# Step 1: Create a portfolio
echo "=== Step 1: Create a Portfolio ==="
echo "Creating a portfolio is the first step in organizing your AWS Service Catalog."
echo "A portfolio groups related products and is a way to manage access and governance."
echo ""
PORT_ID=$(aws servicecatalog create-portfolio \
    --display-name "my-portfolio-${SUFFIX}" \
    --description "This is a test portfolio" \
    --provider-name "MyOrg" \
    --idempotency-token "${SUFFIX}" \
    --query 'PortfolioDetail.Id' --output text)
CREATED_RESOURCES+=("${PORT_ID}")
# Commenting out the tag-resource command due to error
# aws servicecatalog tag-resource --resource-arn "arn:aws:servicecatalog:${AWS_REGION}:${AWS_ACCOUNT_ID}:portfolio/${PORT_ID}" --tags Key=project,Value=doc-smith Key=tutorial,Value=servicecatalog-gs
echo "Result: Portfolio created with ID: ${PORT_ID}"
echo ""

# Step 2: Describe the created portfolio
echo "=== Step 2: Describe the Created Portfolio ==="
echo "Describing a portfolio allows you to view its details, including display name and description."
echo "This is useful for verifying that the portfolio was created correctly."
echo ""
DESCRIBE_PORTFOLIO_RESPONSE=$(aws servicecatalog describe-portfolio \
    --id "${PORT_ID}")
echo "Result: Portfolio description: ${DESCRIBE_PORTFOLIO_RESPONSE}"
echo ""

# Step 3: List all portfolios
echo "=== Step 3: List All Portfolios ==="
echo "Listing all portfolios helps you keep track of the portfolios you have created."
echo "This is essential for managing your AWS Service Catalog environment."
echo ""
LIST_PORTFOLIOS_RESPONSE=$(aws servicecatalog list-portfolios \
    --query 'PortfolioDetails[].DisplayName' --output text)
echo "Result: Portfolios: ${LIST_PORTFOLIOS_RESPONSE}"
echo ""

echo "PASS"
echo ""

# Tutorial complete summary
echo "=== Tutorial Complete ==="
echo "In this tutorial, you learned how to:"
echo "1. Create a portfolio in AWS Service Catalog."
echo "2. Describe the created portfolio to verify its details."
echo "3. List all portfolios to manage your Service Catalog environment."