#!/bin/bash

# CloudFront Getting Started Tutorial Script
# This script creates an S3 bucket, uploads sample content, creates a CloudFront distribution with OAC,
# and demonstrates how to access content through CloudFront.

set -euo pipefail

# Security: Set secure umask
umask 077

# Set up logging with secure permissions
LOG_FILE="cloudfront-tutorial.log"
touch "$LOG_FILE"
chmod 600 "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Starting CloudFront Getting Started Tutorial at $(date)"

# Function to handle errors
handle_error() {
    echo "ERROR: $1" >&2
    echo "Resources created before error:"
    if [ -n "${BUCKET_NAME:-}" ]; then
        echo "- S3 Bucket: $BUCKET_NAME"
    fi
    if [ -n "${OAC_ID:-}" ]; then
        echo "- CloudFront Origin Access Control: $OAC_ID"
    fi
    if [ -n "${DISTRIBUTION_ID:-}" ]; then
        echo "- CloudFront Distribution: $DISTRIBUTION_ID"
    fi
    
    echo "Attempting to clean up resources..."
    cleanup
    exit 1
}

# Function to securely create temporary files
secure_temp_file() {
    local temp_file
    temp_file=$(mktemp) || handle_error "Failed to create temporary file"
    chmod 600 "$temp_file"
    echo "$temp_file"
}

# Function to clean up resources
cleanup() {
    echo "Cleaning up resources..."
    
    if [ -n "${DISTRIBUTION_ID:-}" ]; then
        echo "Disabling CloudFront distribution $DISTRIBUTION_ID..."
        
        # Get the current configuration and ETag
        local temp_config
        temp_config=$(secure_temp_file)
        
        if aws cloudfront get-distribution-config --id "$DISTRIBUTION_ID" > "$temp_config" 2>/dev/null; then
            local etag
            etag=$(jq -r '.ETag' "$temp_config" 2>/dev/null || true)
            
            if [ -n "$etag" ] && [ "$etag" != "null" ]; then
                # Create a modified configuration with Enabled=false
                local disabled_config
                disabled_config=$(secure_temp_file)
                
                jq '.DistributionConfig.Enabled = false' "$temp_config" > "$disabled_config" 2>/dev/null || true
                
                # Update the distribution to disable it
                if [ -f "$disabled_config" ]; then
                    aws cloudfront update-distribution \
                        --id "$DISTRIBUTION_ID" \
                        --distribution-config file://"$disabled_config" \
                        --if-match "$etag" 2>/dev/null || true
                        
                    echo "Waiting for distribution to be disabled (this may take several minutes)..."
                    aws cloudfront wait distribution-deployed --id "$DISTRIBUTION_ID" 2>/dev/null || true
                    
                    # Delete the distribution
                    if aws cloudfront get-distribution-config --id "$DISTRIBUTION_ID" > "$temp_config" 2>/dev/null; then
                        etag=$(jq -r '.ETag' "$temp_config" 2>/dev/null || true)
                        if [ -n "$etag" ] && [ "$etag" != "null" ]; then
                            aws cloudfront delete-distribution --id "$DISTRIBUTION_ID" --if-match "$etag" 2>/dev/null || true
                            echo "CloudFront distribution deleted."
                        fi
                    fi
                fi
                
                rm -f "$disabled_config"
            fi
        else
            echo "Failed to get distribution config. Continuing with cleanup..."
        fi
        
        rm -f "$temp_config"
    fi
    
    if [ -n "${OAC_ID:-}" ]; then
        echo "Deleting Origin Access Control $OAC_ID..."
        local temp_oac
        temp_oac=$(secure_temp_file)
        
        if aws cloudfront get-origin-access-control --id "$OAC_ID" > "$temp_oac" 2>/dev/null; then
            local oac_etag
            oac_etag=$(jq -r '.ETag' "$temp_oac" 2>/dev/null || true)
            
            if [ -n "$oac_etag" ] && [ "$oac_etag" != "null" ]; then
                aws cloudfront delete-origin-access-control --id "$OAC_ID" --if-match "$oac_etag" 2>/dev/null || true
                echo "Origin Access Control deleted."
            else
                echo "Failed to get Origin Access Control ETag. You may need to delete it manually."
            fi
        else
            echo "Failed to get Origin Access Control. You may need to delete it manually."
        fi
        
        rm -f "$temp_oac"
    fi
    
    if [ -n "${BUCKET_NAME:-}" ] && [ "${BUCKET_IS_SHARED:-false}" != "true" ]; then
        echo "Deleting S3 bucket $BUCKET_NAME and its contents..."
        aws s3 rm "s3://$BUCKET_NAME" --recursive 2>/dev/null || true
        
        aws s3 rb "s3://$BUCKET_NAME" 2>/dev/null || true
        echo "S3 bucket deletion attempted."
    fi
    
    # Clean up temporary files securely
    rm -f temp_disabled_config.json
    rm -rf temp_content
    rm -f distribution-config.json
    rm -f bucket-policy.json
}

# Trap to ensure cleanup on script exit
trap cleanup EXIT

# Validate AWS CLI is installed and configured
if ! command -v aws &> /dev/null; then
    handle_error "AWS CLI is not installed or not in PATH"
fi

if ! command -v jq &> /dev/null; then
    handle_error "jq is not installed or not in PATH"
fi

# Test AWS credentials
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    handle_error "AWS credentials are not configured or invalid"
fi

# Generate a random identifier for the bucket name
RANDOM_ID=$(openssl rand -hex 6)

# Check for shared prereq bucket
PREREQ_BUCKET=$(aws cloudformation describe-stacks --stack-name tutorial-prereqs-bucket \
    --query 'Stacks[0].Outputs[?OutputKey==`BucketName`].OutputValue' --output text 2>/dev/null || true)

if [ -n "$PREREQ_BUCKET" ] && [ "$PREREQ_BUCKET" != "None" ]; then
    BUCKET_NAME="$PREREQ_BUCKET"
    BUCKET_IS_SHARED=true
    echo "Using shared bucket: $BUCKET_NAME"
else
    BUCKET_IS_SHARED=false
    BUCKET_NAME="cloudfront-${RANDOM_ID}"
fi

echo "Using bucket name: $BUCKET_NAME"

# Validate bucket name format
if ! [[ "$BUCKET_NAME" =~ ^[a-z0-9][a-z0-9.-]*[a-z0-9]$ ]]; then
    handle_error "Invalid bucket name format: $BUCKET_NAME"
fi

# Create a temporary directory for content with secure permissions
TEMP_DIR="temp_content"
mkdir -p "$TEMP_DIR/css"
chmod 700 "$TEMP_DIR"
if [ $? -ne 0 ]; then
    handle_error "Failed to create temporary directory"
fi

# Step 1: Create an S3 bucket
echo "Creating S3 bucket: $BUCKET_NAME"
aws s3 mb "s3://$BUCKET_NAME" --region us-east-1
if [ $? -ne 0 ]; then
    handle_error "Failed to create S3 bucket"
fi

# Enable block public access
aws s3api put-public-access-block --bucket "$BUCKET_NAME" \
    --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
if [ $? -ne 0 ]; then
    echo "Warning: Failed to configure public access block, but continuing..."
fi

# Enable versioning for safety
aws s3api put-bucket-versioning --bucket "$BUCKET_NAME" --versioning-configuration Status=Enabled
if [ $? -ne 0 ]; then
    echo "Warning: Failed to enable versioning, but continuing..."
fi

# Enable encryption
aws s3api put-bucket-encryption --bucket "$BUCKET_NAME" \
    --server-side-encryption-configuration '{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]}'
if [ $? -ne 0 ]; then
    echo "Warning: Failed to enable encryption, but continuing..."
fi

# Disable S3 access logging by default (can be enabled if needed)
# Enable object lock if high security is required
# aws s3api put-object-lock-configuration --bucket "$BUCKET_NAME" --object-lock-configuration 'ObjectLockEnabled=Enabled' 2>/dev/null || true

# Tag S3 bucket
aws s3api put-bucket-tagging --bucket "$BUCKET_NAME" \
    --tagging 'TagSet=[{Key=project,Value=doc-smith},{Key=tutorial,Value=cloudfront-gettingstarted}]'
if [ $? -ne 0 ]; then
    echo "Warning: Failed to tag S3 bucket, but continuing..."
fi

# Step 2: Create sample content
echo "Creating sample content..."
cat > "$TEMP_DIR/index.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Hello World</title>
    <link rel="stylesheet" type="text/css" href="css/styles.css">
</head>
<body>
    <h1>Hello world!</h1>
</body>
</html>
EOF

cat > "$TEMP_DIR/css/styles.css" << 'EOF'
body {
    font-family: Arial, sans-serif;
    margin: 40px;
    background-color: #f5f5f5;
}
h1 {
    color: #333;
    text-align: center;
}
EOF

chmod 600 "$TEMP_DIR/index.html" "$TEMP_DIR/css/styles.css"

# Step 3: Upload content to the S3 bucket
echo "Uploading content to S3 bucket..."
aws s3 cp "$TEMP_DIR/" "s3://$BUCKET_NAME/" --recursive --sse AES256
if [ $? -ne 0 ]; then
    handle_error "Failed to upload content to S3 bucket"
fi

# Step 4: Create Origin Access Control
echo "Creating Origin Access Control..."
local oac_config_file
oac_config_file=$(secure_temp_file)

cat > "$oac_config_file" << EOF
{
    "Name": "oac-for-$BUCKET_NAME",
    "SigningProtocol": "sigv4",
    "SigningBehavior": "always",
    "OriginAccessControlOriginType": "s3"
}
EOF

OAC_RESPONSE=$(aws cloudfront create-origin-access-control \
    --origin-access-control-config file://"$oac_config_file")

if [ $? -ne 0 ]; then
    handle_error "Failed to create Origin Access Control"
fi

OAC_ID=$(echo "$OAC_RESPONSE" | jq -r '.OriginAccessControl.Id')
if [ -z "$OAC_ID" ] || [ "$OAC_ID" = "null" ]; then
    handle_error "Failed to extract Origin Access Control ID"
fi

rm -f "$oac_config_file"

echo "Created Origin Access Control with ID: $OAC_ID"

# Tag Origin Access Control using tag-resource
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
if [ $? -ne 0 ]; then
    handle_error "Failed to get AWS account ID"
fi

# Validate account ID format
if ! [[ "$ACCOUNT_ID" =~ ^[0-9]{12}$ ]]; then
    handle_error "Invalid AWS Account ID format: $ACCOUNT_ID"
fi

aws cloudfront tag-resource --resource-arn "arn:aws:cloudfront::${ACCOUNT_ID}:origin-access-control/$OAC_ID" \
    --tags Key=project,Value=doc-smith Key=tutorial,Value=cloudfront-gettingstarted 2>/dev/null || true

# Step 5: Create CloudFront distribution
echo "Creating CloudFront distribution..."

# Create distribution configuration
local dist_config_file
dist_config_file=$(secure_temp_file)

cat > "$dist_config_file" << EOF
{
    "CallerReference": "cli-tutorial-\$(date +%s)-\$(openssl rand -hex 4)",
    "Origins": {
        "Quantity": 1,
        "Items": [
            {
                "Id": "S3-$BUCKET_NAME",
                "DomainName": "$BUCKET_NAME.s3.amazonaws.com",
                "S3OriginConfig": {
                    "OriginAccessIdentity": ""
                },
                "OriginAccessControlId": "$OAC_ID"
            }
        ]
    },
    "DefaultCacheBehavior": {
        "TargetOriginId": "S3-$BUCKET_NAME",
        "ViewerProtocolPolicy": "redirect-to-https",
        "AllowedMethods": {
            "Quantity": 2,
            "Items": ["GET", "HEAD"],
            "CachedMethods": {
                "Quantity": 2,
                "Items": ["GET", "HEAD"]
            }
        },
        "DefaultTTL": 86400,
        "MinTTL": 0,
        "MaxTTL": 31536000,
        "Compress": true,
        "ForwardedValues": {
            "QueryString": false,
            "Cookies": {
                "Forward": "none"
            }
        }
    },
    "Comment": "CloudFront distribution for tutorial",
    "Enabled": true,
    "WebACLId": ""
}
EOF

DIST_RESPONSE=$(aws cloudfront create-distribution --distribution-config file://"$dist_config_file")
if [ $? -ne 0 ]; then
    handle_error "Failed to create CloudFront distribution"
fi

DISTRIBUTION_ID=$(echo "$DIST_RESPONSE" | jq -r '.Distribution.Id')
DOMAIN_NAME=$(echo "$DIST_RESPONSE" | jq -r '.Distribution.DomainName')

if [ -z "$DISTRIBUTION_ID" ] || [ "$DISTRIBUTION_ID" = "null" ]; then
    handle_error "Failed to extract Distribution ID"
fi

# Validate distribution ID format
if ! [[ "$DISTRIBUTION_ID" =~ ^[A-Z0-9]+$ ]]; then
    handle_error "Invalid Distribution ID format: $DISTRIBUTION_ID"
fi

rm -f "$dist_config_file"

echo "Created CloudFront distribution with ID: $DISTRIBUTION_ID"
echo "CloudFront domain name: $DOMAIN_NAME"

# Tag CloudFront distribution
aws cloudfront tag-resource --resource-arn "arn:aws:cloudfront::${ACCOUNT_ID}:distribution/$DISTRIBUTION_ID" \
    --tags Key=project,Value=doc-smith Key=tutorial,Value=cloudfront-gettingstarted 2>/dev/null || true

# Step 6: Update S3 bucket policy
echo "Updating S3 bucket policy..."
local bucket_policy_file
bucket_policy_file=$(secure_temp_file)

cat > "$bucket_policy_file" << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowCloudFrontOAC",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudfront.amazonaws.com"
            },
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::$BUCKET_NAME/*",
            "Condition": {
                "StringEquals": {
                    "AWS:SourceArn": "arn:aws:cloudfront::${ACCOUNT_ID}:distribution/$DISTRIBUTION_ID"
                }
            }
        }
    ]
}
EOF

aws s3api put-bucket-policy --bucket "$BUCKET_NAME" --policy file://"$bucket_policy_file"
if [ $? -ne 0 ]; then
    handle_error "Failed to update S3 bucket policy"
fi

rm -f "$bucket_policy_file"

# Step 7: Wait for distribution to deploy
echo "Waiting for CloudFront distribution to deploy (this may take 5-10 minutes)..."
aws cloudfront wait distribution-deployed --id "$DISTRIBUTION_ID" 2>/dev/null || true
echo "CloudFront distribution deployment in progress."

# Step 8: Display access information
echo ""
echo "===== CloudFront Distribution Setup Complete ====="
echo "You can access your content at: https://$DOMAIN_NAME/index.html"
echo ""
echo "Resources created:"
echo "- S3 Bucket: $BUCKET_NAME"
echo "- CloudFront Origin Access Control: $OAC_ID"
echo "- CloudFront Distribution: $DISTRIBUTION_ID"
echo ""

# Ask user if they want to clean up resources
if [ -t 0 ]; then
    read -p "Do you want to clean up all resources created by this script? (y/n): " -r CLEANUP_RESPONSE
    if [[ "$CLEANUP_RESPONSE" =~ ^[Yy]$ ]]; then
        cleanup
        echo "All resources have been cleaned up."
        exit 0
    else
        echo "Resources will not be cleaned up. You can manually delete them later."
        echo "To access your content, visit: https://$DOMAIN_NAME/index.html"
    fi
fi

echo "Tutorial completed at $(date)"