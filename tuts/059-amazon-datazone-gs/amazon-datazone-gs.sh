#!/bin/bash

# Amazon DataZone Getting Started Script
# This script automates the steps in the Amazon DataZone Getting Started tutorial

# FIXES FOR HIGH SEVERITY ISSUES:
# 1. Enhanced IAM role permissions for DataZone domain execution
# 2. Improved asset type availability verification before asset creation

# Setup logging
LOG_FILE="datazone_script_v3_fixed.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Starting Amazon DataZone Getting Started Script at $(date)"
echo "============================================================"

# Function to check for errors in command output
check_error() {
    local output=$1
    local cmd=$2
    
    if echo "$output" | grep -i "error\|exception" > /dev/null; then
        echo "ERROR detected in command: $cmd"
        echo "$output"
        cleanup_resources
        exit 1
    fi
}

# Function to clean up resources
cleanup_resources() {
    echo ""
    echo "============================================================"
    echo "RESOURCES CREATED:"
    echo "============================================================"
    
    if [ -n "$SUBSCRIPTION_REQUEST_ID" ]; then
        echo "- Subscription Request: $SUBSCRIPTION_REQUEST_ID"
    fi
    
    if [ -n "$ASSET_ID" ]; then
        echo "- Asset: $ASSET_ID"
    fi
    
    if [ -n "$ASSET_TYPE_ID" ]; then
        echo "- Asset Type: $ASSET_TYPE_ID"
    fi
    
    if [ -n "$FORM_TYPE_ID" ]; then
        echo "- Form Type: $FORM_TYPE_ID"
    fi
    
    if [ -n "$DATA_SOURCE_ID" ]; then
        echo "- Data Source: $DATA_SOURCE_ID"
    fi
    
    if [ -n "$ENVIRONMENT_ID" ]; then
        echo "- Environment: $ENVIRONMENT_ID"
    fi
    
    if [ -n "$ENVIRONMENT_PROFILE_ID" ]; then
        echo "- Environment Profile: $ENVIRONMENT_PROFILE_ID"
    fi
    
    if [ -n "$CONSUMER_PROJECT_ID" ]; then
        echo "- Consumer Project: $CONSUMER_PROJECT_ID"
    fi
    
    if [ -n "$PROJECT_ID" ]; then
        echo "- Project: $PROJECT_ID"
    fi
    
    if [ -n "$DOMAIN_ID" ]; then
        echo "- Domain: $DOMAIN_ID"
    fi
    
    echo ""
    echo "============================================================"
    echo "CLEANUP CONFIRMATION"
    echo "============================================================"
    echo "Do you want to clean up all created resources? (y/n): "
    read -r CLEANUP_CHOICE
    
    if [[ "$CLEANUP_CHOICE" =~ ^[Yy]$ ]]; then
        echo "Starting cleanup process..."
        
        # Delete resources in reverse order of creation
        if [ -n "$SUBSCRIPTION_REQUEST_ID" ]; then
            echo "Deleting subscription request..."
            aws datazone delete-subscription-request --domain-identifier "$DOMAIN_ID" --identifier "$SUBSCRIPTION_REQUEST_ID" --region "$REGION" || echo "Failed to delete subscription request"
        fi
        
        if [ -n "$ASSET_ID" ]; then
            echo "Deleting asset..."
            aws datazone delete-asset --domain-identifier "$DOMAIN_ID" --identifier "$ASSET_ID" --region "$REGION" || echo "Failed to delete asset"
        fi
        
        if [ -n "$ASSET_TYPE_ID" ]; then
            echo "Deleting asset type..."
            aws datazone delete-asset-type --domain-identifier "$DOMAIN_ID" --identifier "$ASSET_TYPE_ID" --region "$REGION" || echo "Failed to delete asset type"
        fi
        
        if [ -n "$FORM_TYPE_ID" ]; then
            echo "Deleting form type..."
            aws datazone delete-form-type --domain-identifier "$DOMAIN_ID" --identifier "$FORM_TYPE_ID" --region "$REGION" || echo "Failed to delete form type"
        fi
        
        if [ -n "$DATA_SOURCE_ID" ]; then
            echo "Deleting data source..."
            aws datazone delete-data-source --domain-identifier "$DOMAIN_ID" --identifier "$DATA_SOURCE_ID" --region "$REGION" || echo "Failed to delete data source"
        fi
        
        if [ -n "$ENVIRONMENT_ID" ]; then
            echo "Deleting environment..."
            aws datazone delete-environment --domain-identifier "$DOMAIN_ID" --identifier "$ENVIRONMENT_ID" --region "$REGION" || echo "Failed to delete environment"
        fi
        
        if [ -n "$ENVIRONMENT_PROFILE_ID" ]; then
            echo "Deleting environment profile..."
            aws datazone delete-environment-profile --domain-identifier "$DOMAIN_ID" --identifier "$ENVIRONMENT_PROFILE_ID" --region "$REGION" || echo "Failed to delete environment profile"
        fi
        
        if [ -n "$CONSUMER_PROJECT_ID" ]; then
            echo "Deleting consumer project..."
            aws datazone delete-project --domain-identifier "$DOMAIN_ID" --identifier "$CONSUMER_PROJECT_ID" --region "$REGION" || echo "Failed to delete consumer project"
        fi
        
        if [ -n "$PROJECT_ID" ]; then
            echo "Deleting project..."
            aws datazone delete-project --domain-identifier "$DOMAIN_ID" --identifier "$PROJECT_ID" --region "$REGION" || echo "Failed to delete project"
        fi
        
        if [ -n "$DOMAIN_ID" ]; then
            echo "Deleting domain..."
            aws datazone delete-domain --identifier "$DOMAIN_ID" --region "$REGION" || echo "Failed to delete domain"
        fi
        
        echo "Cleanup completed."
    else
        echo "Cleanup skipped. Resources will remain in your account."
    fi
}

# Trap for script interruption
trap cleanup_resources EXIT INT TERM

# Get AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "Using AWS Account ID: $ACCOUNT_ID"

# Get AWS region
REGION=$(aws configure get region)
if [ -z "$REGION" ]; then
    REGION="us-east-1"
    echo "No region configured, defaulting to $REGION"
fi
echo "Using AWS Region: $REGION"

# Generate random suffix for resource names
SUFFIX=$(openssl rand -hex 4)
echo "Using random suffix for resource names: $SUFFIX"

# Step 1: Create an Amazon DataZone Domain
echo ""
echo "Step 1: Creating Amazon DataZone Domain..."
DOMAIN_NAME="MyDataZoneDomain-$SUFFIX"

# Check if the domain execution role exists
ROLE_NAME="AmazonDataZoneDomainExecutionRole"
ROLE_CHECK=$(aws iam get-role --role-name "$ROLE_NAME" 2>&1 || echo "Role not found")

if echo "$ROLE_CHECK" | grep -i "error\|not found" > /dev/null; then
    echo "Domain execution role not found. Creating role..."
    
    # Create trust policy document
    cat > trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "datazone.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

    # Create the role
    ROLE_CREATE=$(aws iam create-role --role-name "$ROLE_NAME" --assume-role-policy-document file://trust-policy.json)
    check_error "$ROLE_CREATE" "create-role"
    
    # FIX: Enhanced IAM role permissions for DataZone domain execution
    # Attach necessary policies with more comprehensive permissions
    aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn "arn:aws:iam::aws:policy/AmazonDataZoneFullAccess"
    aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn "arn:aws:iam::aws:policy/AmazonS3FullAccess"
    aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn "arn:aws:iam::aws:policy/AWSGlueConsoleFullAccess"
    
    # Create additional inline policy for Lake Formation permissions
    cat > lakeformation-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "lakeformation:GetDataAccess",
        "lakeformation:GrantPermissions",
        "lakeformation:RevokePermissions",
        "lakeformation:BatchGrantPermissions",
        "lakeformation:BatchRevokePermissions",
        "lakeformation:ListPermissions"
      ],
      "Resource": "*"
    }
  ]
}
EOF

    aws iam put-role-policy --role-name "$ROLE_NAME" --policy-name "DataZoneLakeFormationAccess" --policy-document file://lakeformation-policy.json
    
    # Wait for role to propagate
    echo "Waiting for role to propagate..."
    sleep 30
    
    echo "Domain execution role created with enhanced permissions."
    rm trust-policy.json lakeformation-policy.json
fi

# Create the domain
echo "Creating domain $DOMAIN_NAME..."
DOMAIN_RESULT=$(aws datazone create-domain \
  --name "$DOMAIN_NAME" \
  --description "My first DataZone domain" \
  --domain-execution-role "arn:aws:iam::$ACCOUNT_ID:role/$ROLE_NAME" \
  --region "$REGION")

check_error "$DOMAIN_RESULT" "create-domain"
echo "$DOMAIN_RESULT"

# Extract domain ID
DOMAIN_ID=$(echo "$DOMAIN_RESULT" | grep -o '"id":[^,}]*' | sed 's/"id":[[:space:]]*"\([^"]*\)".*/\1/')
echo "Domain created with ID: $DOMAIN_ID"

# Wait for domain to be available
echo "Waiting for domain to become available..."
sleep 30
DOMAIN_STATUS=$(aws datazone get-domain --identifier "$DOMAIN_ID" --query "status" --output text --region "$REGION")
echo "Domain status: $DOMAIN_STATUS"

while [ "$DOMAIN_STATUS" != "AVAILABLE" ]; do
    echo "Domain is not yet available. Current status: $DOMAIN_STATUS. Waiting..."
    sleep 30
    DOMAIN_STATUS=$(aws datazone get-domain --identifier "$DOMAIN_ID" --query "status" --output text --region "$REGION")
    echo "Domain status: $DOMAIN_STATUS"
done

# Step 2: Create a Publishing Project
echo ""
echo "Step 2: Creating Publishing Project..."
PROJECT_NAME="PublishingProject-$SUFFIX"

PROJECT_RESULT=$(aws datazone create-project \
  --domain-identifier "$DOMAIN_ID" \
  --name "$PROJECT_NAME" \
  --region "$REGION")

check_error "$PROJECT_RESULT" "create-project"
echo "$PROJECT_RESULT"

# Extract project ID
PROJECT_ID=$(echo "$PROJECT_RESULT" | grep -o '"id":[^,}]*' | sed 's/"id":[[:space:]]*"\([^"]*\)".*/\1/')
echo "Project created with ID: $PROJECT_ID"

# Create a Consumer Project for later subscription
echo ""
echo "Creating Consumer Project for later subscription..."
CONSUMER_PROJECT_NAME="ConsumerProject-$SUFFIX"

CONSUMER_PROJECT_RESULT=$(aws datazone create-project \
  --domain-identifier "$DOMAIN_ID" \
  --name "$CONSUMER_PROJECT_NAME" \
  --region "$REGION")

check_error "$CONSUMER_PROJECT_RESULT" "create-consumer-project"
echo "$CONSUMER_PROJECT_RESULT"

# Extract consumer project ID
CONSUMER_PROJECT_ID=$(echo "$CONSUMER_PROJECT_RESULT" | grep -o '"id":[^,}]*' | sed 's/"id":[[:space:]]*"\([^"]*\)".*/\1/')
echo "Consumer Project created with ID: $CONSUMER_PROJECT_ID"

# Step 3: Create an Environment Profile
echo ""
echo "Step 3: Creating Environment Profile..."

# List available environment blueprints
echo "Listing available environment blueprints..."
BLUEPRINTS_RESULT=$(aws datazone list-environment-blueprints \
  --domain-identifier "$DOMAIN_ID" \
  --region "$REGION")

check_error "$BLUEPRINTS_RESULT" "list-environment-blueprints"
echo "$BLUEPRINTS_RESULT"

# Extract the first blueprint ID using jq-like approach with grep and sed
BLUEPRINT_ID=$(echo "$BLUEPRINTS_RESULT" | grep -o '"id":[^,}]*' | head -1 | sed 's/"id":[[:space:]]*"\([^"]*\)".*/\1/')
echo "Using Environment Blueprint ID: $BLUEPRINT_ID"

# Verify that we have a valid blueprint ID
if [ -z "$BLUEPRINT_ID" ]; then
    echo "ERROR: Could not extract a valid environment blueprint ID"
    echo "Available blueprints:"
    echo "$BLUEPRINTS_RESULT"
    exit 1
fi

# Create environment profile
PROFILE_NAME="DataLakeProfile-$SUFFIX"

PROFILE_RESULT=$(aws datazone create-environment-profile \
  --description "DataLake environment profile" \
  --domain-identifier "$DOMAIN_ID" \
  --aws-account-id "$ACCOUNT_ID" \
  --aws-account-region "$REGION" \
  --environment-blueprint-identifier "$BLUEPRINT_ID" \
  --name "$PROFILE_NAME" \
  --project-identifier "$PROJECT_ID" \
  --region "$REGION")

check_error "$PROFILE_RESULT" "create-environment-profile"
echo "$PROFILE_RESULT"

# Extract environment profile ID
ENVIRONMENT_PROFILE_ID=$(echo "$PROFILE_RESULT" | grep -o '"id":[^,}]*' | sed 's/"id":[[:space:]]*"\([^"]*\)".*/\1/')
echo "Environment Profile created with ID: $ENVIRONMENT_PROFILE_ID"

# Verify that we have a valid environment profile ID
if [ -z "$ENVIRONMENT_PROFILE_ID" ]; then
    echo "ERROR: Could not extract a valid environment profile ID"
    exit 1
fi

# Step 4: Create an Environment
echo ""
echo "Step 4: Creating Environment..."
ENVIRONMENT_NAME="DataLakeEnvironment-$SUFFIX"

ENVIRONMENT_RESULT=$(aws datazone create-environment \
  --description "DataLake environment for data publishing" \
  --domain-identifier "$DOMAIN_ID" \
  --environment-profile-identifier "$ENVIRONMENT_PROFILE_ID" \
  --name "$ENVIRONMENT_NAME" \
  --project-identifier "$PROJECT_ID" \
  --region "$REGION")

check_error "$ENVIRONMENT_RESULT" "create-environment"
echo "$ENVIRONMENT_RESULT"

# Extract environment ID
ENVIRONMENT_ID=$(echo "$ENVIRONMENT_RESULT" | grep -o '"id":[^,}]*' | sed 's/"id":[[:space:]]*"\([^"]*\)".*/\1/')
echo "Environment created with ID: $ENVIRONMENT_ID"

# Verify that we have a valid environment ID
if [ -z "$ENVIRONMENT_ID" ]; then
    echo "ERROR: Could not extract a valid environment ID"
    exit 1
fi

# Wait for environment to be provisioned
echo "Waiting for environment to be provisioned..."
sleep 30
ENV_STATUS=$(aws datazone get-environment \
  --domain-identifier "$DOMAIN_ID" \
  --identifier "$ENVIRONMENT_ID" \
  --project-identifier "$PROJECT_ID" \
  --query "status" \
  --output text \
  --region "$REGION")
echo "Environment status: $ENV_STATUS"

while [ "$ENV_STATUS" != "ACTIVE" ] && [ "$ENV_STATUS" != "FAILED" ]; do
    echo "Environment is not yet active. Current status: $ENV_STATUS. Waiting..."
    sleep 30
    ENV_STATUS=$(aws datazone get-environment \
      --domain-identifier "$DOMAIN_ID" \
      --identifier "$ENVIRONMENT_ID" \
      --project-identifier "$PROJECT_ID" \
      --query "status" \
      --output text \
      --region "$REGION")
    echo "Environment status: $ENV_STATUS"
done

if [ "$ENV_STATUS" == "FAILED" ]; then
    echo "ERROR: Environment creation failed"
    cleanup_resources
    exit 1
fi

# Step 5: Create a Data Source for AWS Glue
echo ""
echo "Step 5: Creating Data Source for AWS Glue..."

# Check if we have a Glue database to use
GLUE_DATABASES=$(aws glue get-databases --query "DatabaseList[].Name" --output text --region "$REGION")
check_error "$GLUE_DATABASES" "get-databases"

if [ -z "$GLUE_DATABASES" ]; then
    echo "No Glue databases found. Creating a sample database..."
    GLUE_DB_NAME="datazone-sample-db-$SUFFIX"
    
    aws glue create-database --database-input "{\"Name\":\"$GLUE_DB_NAME\"}" --region "$REGION"
    echo "Created Glue database: $GLUE_DB_NAME"
else
    GLUE_DB_NAME=$(echo "$GLUE_DATABASES" | head -1)
    echo "Using existing Glue database: $GLUE_DB_NAME"
fi

# Create data source
DATA_SOURCE_NAME="GlueDataSource-$SUFFIX"

# Create data access role for Glue
GLUE_ROLE_NAME="AmazonDataZoneGlueAccess-$REGION-$DOMAIN_ID"
GLUE_ROLE_CHECK=$(aws iam get-role --role-name "$GLUE_ROLE_NAME" 2>&1 || echo "Role not found")

if echo "$GLUE_ROLE_CHECK" | grep -i "error\|not found" > /dev/null; then
    echo "Glue access role not found. Creating role..."
    
    # Create trust policy document
    cat > glue-trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "datazone.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

    # Create the role
    GLUE_ROLE_CREATE=$(aws iam create-role --role-name "$GLUE_ROLE_NAME" --assume-role-policy-document file://glue-trust-policy.json)
    check_error "$GLUE_ROLE_CREATE" "create-glue-role"
    
    # Create policy document
    cat > glue-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "glue:GetDatabases",
        "glue:GetTables",
        "glue:GetPartitions",
        "glue:GetDatabase",
        "glue:GetTable",
        "glue:GetPartition"
      ],
      "Resource": "*"
    }
  ]
}
EOF

    # Create and attach policy
    aws iam put-role-policy --role-name "$GLUE_ROLE_NAME" --policy-name "DataZoneGlueAccess" --policy-document file://glue-policy.json
    
    # Wait for role to propagate
    echo "Waiting for role to propagate..."
    sleep 15
    
    echo "Glue access role created."
    rm glue-trust-policy.json glue-policy.json
fi

# Create data source configuration
cat > data-source-config.json << EOF
{
  "glueRunConfiguration": {
    "dataAccessRole": "arn:aws:iam::$ACCOUNT_ID:role/$GLUE_ROLE_NAME",
    "relationalFilterConfigurations": [
      {
        "databaseName": "$GLUE_DB_NAME",
        "filterExpressions": [
          {"expression": "*", "type": "INCLUDE"}
        ]
      }
    ]
  }
}
EOF

DATA_SOURCE_RESULT=$(aws datazone create-data-source \
  --name "$DATA_SOURCE_NAME" \
  --description "Data source for AWS Glue metadata" \
  --domain-identifier "$DOMAIN_ID" \
  --environment-identifier "$ENVIRONMENT_ID" \
  --project-identifier "$PROJECT_ID" \
  --enable-setting "ENABLED" \
  --publish-on-import false \
  --recommendation '{"enableBusinessNameGeneration": true}' \
  --type "GLUE" \
  --configuration file://data-source-config.json \
  --schedule '{"schedule": "cron(0 0 * * ? *)", "timezone": "UTC"}' \
  --region "$REGION")

check_error "$DATA_SOURCE_RESULT" "create-data-source"
echo "$DATA_SOURCE_RESULT"

# Extract data source ID
DATA_SOURCE_ID=$(echo "$DATA_SOURCE_RESULT" | grep -o '"id":[^,}]*' | sed 's/"id":[[:space:]]*"\([^"]*\)".*/\1/')
echo "Data Source created with ID: $DATA_SOURCE_ID"
rm data-source-config.json

# Step 6: Create and Publish Custom Assets
echo ""
echo "Step 6: Creating and Publishing Custom Assets..."

# Step 6.1: Create a Custom Form Type
echo "Creating Custom Form Type..."
FORM_TYPE_NAME="CustomDataForm-$SUFFIX"

FORM_TYPE_RESULT=$(aws datazone create-form-type \
  --domain-identifier "$DOMAIN_ID" \
  --name "$FORM_TYPE_NAME" \
  --model '{"smithy": "structure CustomDataForm { description: String, owner: String }"}' \
  --owning-project-identifier "$PROJECT_ID" \
  --status "ENABLED" \
  --region "$REGION")

check_error "$FORM_TYPE_RESULT" "create-form-type"
echo "$FORM_TYPE_RESULT"

# Extract form type ID
FORM_TYPE_ID=$(echo "$FORM_TYPE_RESULT" | grep -o '"id":[^,}]*' | sed 's/"id":[[:space:]]*"\([^"]*\)".*/\1/')
echo "Form Type created with ID: $FORM_TYPE_ID"

# Wait for form type to be available
echo "Waiting for form type to be available..."
sleep 15

# Step 6.2: Create a Custom Asset Type
echo "Creating Custom Asset Type..."
ASSET_TYPE_NAME="CustomDataAssetType-$SUFFIX"

# Create forms input JSON
cat > forms-input.json << EOF
{
  "$FORM_TYPE_NAME": {
    "typeIdentifier": "$FORM_TYPE_ID",
    "typeRevision": "1",
    "required": true
  }
}
EOF

ASSET_TYPE_RESULT=$(aws datazone create-asset-type \
  --domain-identifier "$DOMAIN_ID" \
  --name "$ASSET_TYPE_NAME" \
  --forms-input file://forms-input.json \
  --owning-project-identifier "$PROJECT_ID" \
  --region "$REGION")

check_error "$ASSET_TYPE_RESULT" "create-asset-type"
echo "$ASSET_TYPE_RESULT"

# Extract asset type ID
ASSET_TYPE_ID=$(echo "$ASSET_TYPE_RESULT" | grep -o '"id":[^,}]*' | sed 's/"id":[[:space:]]*"\([^"]*\)".*/\1/')
echo "Asset Type created with ID: $ASSET_TYPE_ID"
rm forms-input.json

# FIX: Improved asset type availability verification before asset creation
# Verify that the asset type is available before proceeding
echo "Verifying asset type availability..."
MAX_RETRIES=10
RETRY_COUNT=0
ASSET_TYPE_AVAILABLE=false

while [ $RETRY_COUNT -lt $MAX_RETRIES ] && [ "$ASSET_TYPE_AVAILABLE" = false ]; do
    ASSET_TYPE_CHECK=$(aws datazone get-asset-type \
      --domain-identifier "$DOMAIN_ID" \
      --identifier "$ASSET_TYPE_ID" \
      --region "$REGION" 2>&1)
    
    if echo "$ASSET_TYPE_CHECK" | grep -i "error\|exception" > /dev/null; then
        echo "Asset type not yet available. Waiting..."
        sleep 15
        RETRY_COUNT=$((RETRY_COUNT + 1))
    else
        ASSET_TYPE_STATUS=$(echo "$ASSET_TYPE_CHECK" | grep -o '"status":[^,}]*' | sed 's/"status":[[:space:]]*"\([^"]*\)".*/\1/')
        if [ "$ASSET_TYPE_STATUS" = "ENABLED" ] || [ "$ASSET_TYPE_STATUS" = "ACTIVE" ]; then
            ASSET_TYPE_AVAILABLE=true
            echo "Asset type is now available with status: $ASSET_TYPE_STATUS"
        else
            echo "Asset type status: $ASSET_TYPE_STATUS. Waiting..."
            sleep 15
            RETRY_COUNT=$((RETRY_COUNT + 1))
        fi
    fi
done

if [ "$ASSET_TYPE_AVAILABLE" = false ]; then
    echo "ERROR: Asset type did not become available within the expected time"
    cleanup_resources
    exit 1
fi

# Step 6.3: Create a Custom Asset
echo "Creating Custom Asset..."
ASSET_NAME="MyCustomAsset-$SUFFIX"

# Create forms input JSON for asset
cat > asset-forms-input.json << EOF
[
  {
    "formName": "$FORM_TYPE_NAME",
    "typeIdentifier": "$FORM_TYPE_ID",
    "content": "{\"description\":\"Sample data for analysis\",\"owner\":\"Data Team\"}"
  }
]
EOF

ASSET_RESULT=$(aws datazone create-asset \
  --domain-identifier "$DOMAIN_ID" \
  --name "$ASSET_NAME" \
  --description "A custom data asset" \
  --owning-project-identifier "$PROJECT_ID" \
  --type-identifier "$ASSET_TYPE_ID" \
  --forms-input file://asset-forms-input.json \
  --region "$REGION")

check_error "$ASSET_RESULT" "create-asset"
echo "$ASSET_RESULT"

# Extract asset ID
ASSET_ID=$(echo "$ASSET_RESULT" | grep -o '"id":[^,}]*' | sed 's/"id":[[:space:]]*"\([^"]*\)".*/\1/')
echo "Asset created with ID: $ASSET_ID"
rm asset-forms-input.json

# Step 6.4: Publish the Asset
echo "Publishing the Asset..."

PUBLISH_RESULT=$(aws datazone create-listing-change-set \
  --domain-identifier "$DOMAIN_ID" \
  --entity-identifier "$ASSET_ID" \
  --entity-type "ASSET" \
  --action "PUBLISH" \
  --region "$REGION")

check_error "$PUBLISH_RESULT" "create-listing-change-set"
echo "$PUBLISH_RESULT"

# Extract listing ID
LISTING_ID=$(echo "$PUBLISH_RESULT" | grep -o '"listingId":[^,}]*' | sed 's/"listingId":[[:space:]]*"\([^"]*\)".*/\1/')
echo "Asset published with Listing ID: $LISTING_ID"

# Wait for listing to be available
echo "Waiting for listing to be available..."
sleep 15

# Step 7: Search for Assets and Subscribe
echo ""
echo "Step 7: Searching for Assets and Creating Subscription..."

# Step 7.1: Search for Assets
echo "Searching for Assets..."

SEARCH_RESULT=$(aws datazone search-listings \
  --domain-identifier "$DOMAIN_ID" \
  --search-text "$ASSET_NAME" \
  --region "$REGION")

check_error "$SEARCH_RESULT" "search-listings"
echo "$SEARCH_RESULT"

# Step 7.2: Create a Subscription Request
echo "Creating Subscription Request..."

# Create subscription request JSON
cat > subscription-request.json << EOF
{
  "domainIdentifier": "$DOMAIN_ID",
  "subscribedPrincipals": [
    {
      "project": {
        "identifier": "$CONSUMER_PROJECT_ID"
      }
    }
  ],
  "subscribedListings": [
    {
      "identifier": "$LISTING_ID"
    }
  ],
  "requestReason": "Need this data for analysis"
}
EOF

SUBSCRIPTION_RESULT=$(aws datazone create-subscription-request \
  --cli-input-json file://subscription-request.json \
  --region "$REGION")

check_error "$SUBSCRIPTION_RESULT" "create-subscription-request"
echo "$SUBSCRIPTION_RESULT"

# Extract subscription request ID
SUBSCRIPTION_REQUEST_ID=$(echo "$SUBSCRIPTION_RESULT" | grep -o '"id":[^,}]*' | sed 's/"id":[[:space:]]*"\([^"]*\)".*/\1/')
echo "Subscription Request created with ID: $SUBSCRIPTION_REQUEST_ID"
rm subscription-request.json

# Step 7.3: Accept the Subscription Request
echo "Accepting Subscription Request..."

ACCEPT_RESULT=$(aws datazone accept-subscription-request \
  --domain-identifier "$DOMAIN_ID" \
  --identifier "$SUBSCRIPTION_REQUEST_ID" \
  --region "$REGION")

check_error "$ACCEPT_RESULT" "accept-subscription-request"
echo "$ACCEPT_RESULT"

echo ""
echo "============================================================"
echo "Amazon DataZone Getting Started Script completed successfully!"
echo "============================================================"
echo ""
echo "Resources created:"
echo "- Domain: $DOMAIN_ID ($DOMAIN_NAME)"
echo "- Publishing Project: $PROJECT_ID ($PROJECT_NAME)"
echo "- Consumer Project: $CONSUMER_PROJECT_ID ($CONSUMER_PROJECT_NAME)"
echo "- Environment Profile: $ENVIRONMENT_PROFILE_ID ($PROFILE_NAME)"
echo "- Environment: $ENVIRONMENT_ID ($ENVIRONMENT_NAME)"
echo "- Data Source: $DATA_SOURCE_ID ($DATA_SOURCE_NAME)"
echo "- Form Type: $FORM_TYPE_ID ($FORM_TYPE_NAME)"
echo "- Asset Type: $ASSET_TYPE_ID ($ASSET_TYPE_NAME)"
echo "- Asset: $ASSET_ID ($ASSET_NAME)"
echo "- Subscription Request: $SUBSCRIPTION_REQUEST_ID"
echo ""
echo "You can now explore these resources in the Amazon DataZone console."
echo "Log file: $LOG_FILE"

# Prompt for cleanup
cleanup_resources

exit 0
