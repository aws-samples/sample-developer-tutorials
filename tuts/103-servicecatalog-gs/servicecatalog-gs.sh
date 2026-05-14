#!/bin/bash
set -e

# Configuration
TEMP_DIR=$(mktemp -d)
LOG_FILE="${TEMP_DIR}/script.log"
CREATED_RESOURCES=()

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
PORT_ID=$(aws servicecatalog create-portfolio \
    --display-name "my-portfolio-${SUFFIX}" \
    --description "This is a test portfolio" \
    --provider-name "MyOrg" \
    --idempotency-token "${SUFFIX}" \
    --query 'PortfolioDetail.Id' --output text)
CREATED_RESOURCES+=("${PORT_ID}")
echo "Portfolio created with ID: ${PORT_ID}" {LOG_FILE}"

# Step 2: Describe the created portfolio
DESCRIBE_PORTFOLIO_RESPONSE=$(aws servicecatalog describe-portfolio \
    --id "${PORT_ID}")
echo "Portfolio description: ${DESCRIBE_PORTFOLIO_RESPONSE}" {LOG_FILE}"

# Step 3: List all portfolios
LIST_PORTFOLIOS_RESPONSE=$(aws servicecatalog list-portfolios \
    --query 'PortfolioDetails[].DisplayName' --output text)
echo "Portfolios: ${LIST_PORTFOLIOS_RESPONSE}" {LOG_FILE}"

echo "PASS" {LOG_FILE}"