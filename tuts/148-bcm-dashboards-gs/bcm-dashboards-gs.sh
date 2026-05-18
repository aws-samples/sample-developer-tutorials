#!/bin/bash
set -e

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
DASHBOARD_NAME="dashboard-${SUFFIX}"

# Create Cost Category
COST_CATEGORY_ARN=$(aws ce create-cost-category-definition \
    --cost-category-name "${DASHBOARD_NAME}" \
    --rule-version 'CostCategoryExpression.v1' \
    --rules Type=REGULAR,Value='Sample Value',Rule='{"And":[{"Or":[{"Dimension":{"Key":"SERVICE","Values":["Amazon S3"]}}]},{"Not":{"Dimension":{"Key":"USAGE_TYPE","Values":["DataTransfer-Out-Bytes"]}}}]}' \
    --split-charge-rules Type=ALLOCATE_FIXED,Value=100,Source=UNCATEGORIZED,Targets=SampleTarget \
    --query 'CostCategoryArn' --output text)

echo "Cost Category created with ARN: ${COST_CATEGORY_ARN}"

# Verify Cost Category Creation
GET_RESPONSE=$(aws ce describe-cost-category-definition \
    --cost-category-arn "${COST_CATEGORY_ARN}" \
    --query 'CostCategoryArn' --output text)

echo "Retrieved cost category: ${GET_RESPONSE}"

# List Cost Categories
LIST_RESPONSE=$(aws ce list-cost-categories \
    --query 'CostCategories' --output text)

echo "Listed cost categories: ${LIST_RESPONSE}"

# Clean Up
aws ce delete-cost-category-definition \
    --cost-category-arn "${COST_CATEGORY_ARN}" || true

echo "Deleted cost category with ARN: ${COST_CATEGORY_ARN}"

echo "PASS"