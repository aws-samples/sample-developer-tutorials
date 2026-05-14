#!/bin/bash
set -e

# Generate a unique suffix
SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)

# Create a portfolio
PORT_ID=$(aws servicecatalog create-portfolio \
    --display-name "my-portfolio-${SUFFIX}" \
    --description "This is a test portfolio" \
    --provider-name "MyOrg" \
    --idempotency-token "${SUFFIX}" \
    --query 'PortfolioDetail.Id' --output text)

echo "Portfolio created with ID: ${PORT_ID}"

# Describe the created portfolio
DESCRIBE_PORTFOLIO_RESPONSE=$(aws servicecatalog describe-portfolio \
    --id "${PORT_ID}")

echo "Portfolio description: ${DESCRIBE_PORTFOLIO_RESPONSE}"

# List all portfolios
LIST_PORTFOLIOS_RESPONSE=$(aws servicecatalog list-portfolios \
    --query 'PortfolioDetails[].DisplayName' --output text)

echo "Portfolios: ${LIST_PORTFOLIOS_RESPONSE}"

# Delete the created portfolio
aws servicecatalog delete-portfolio \
    --id "${PORT_ID}" || true

echo "Portfolio with ID ${PORT_ID} deleted"

echo "PASS"