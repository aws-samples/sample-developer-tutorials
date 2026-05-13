#!/bin/bash
set -e

REGION='us-east-1'
SUFFIX=$(date +%s | sha256sum | base64 | head -c 6 ; echo '')
DOMAIN_NAME="domain-${SUFFIX}"
REPO_NAME="repo-${SUFFIX}"
PACKAGE_GROUP_NAME="package-group-${SUFFIX}"
ROLE_ARN='arn:aws:iam::559823168634:role/doc-babu-codeartifact-role'

echo "Creating domain..."
aws codeartifact create-domain \
    --domain "$DOMAIN_NAME" \
    --region "$REGION" > /dev/null && \
echo "Domain created: $DOMAIN_NAME"

echo "Creating repository..."
aws codeartifact create-repository \
    --domain "$DOMAIN_NAME" \
    --repository "$REPO_NAME" \
    --external-connections 'public:pypi' \
    --region "$REGION" > /dev/null && \
echo "Repository created: $REPO_NAME"

echo "Creating package group..."
aws codeartifact create-package-group \
    --domain "$DOMAIN_NAME" \
    --package-group "$PACKAGE_GROUP_NAME" \
    --contact-info 'test@example.com' \
    --description 'Test package group' \
    --region "$REGION" > /dev/null && \
echo "Package group created: $PACKAGE_GROUP_NAME"

echo "Associating external connection..."
aws codeartifact associate-external-connection \
    --domain "$DOMAIN_NAME" \
    --repository "$REPO_NAME" \
    --external-connection 'public:pypi' \
    --region "$REGION" > /dev/null && \
echo "External connection associated"

echo "Copying package versions..."
aws codeartifact copy-package-versions \
    --domain "$DOMAIN_NAME" \
    --repository "$REPO_NAME" \
    --format 'pypi' \
    --package 'sample-package' \
    --versions '1.0.0' \
    --target-repository "$REPO_NAME" \
    --region "$REGION" > /dev/null && \
echo "Package versions copied"

echo "Deleting package group..."
aws codeartifact delete-package-group \
    --domain "$DOMAIN_NAME" \
    --package-group "$PACKAGE_GROUP_NAME" \
    --region "$REGION" > /dev/null && \
echo "Package group deleted: $PACKAGE_GROUP_NAME"

echo "Deleting repository..."
aws codeartifact delete-repository \
    --domain "$DOMAIN_NAME" \
    --repository "$REPO_NAME" \
    --region "$REGION" > /dev/null && \
echo "Repository deleted: $REPO_NAME"

echo "Deleting domain..."
aws codeartifact delete-domain \
    --domain "$DOMAIN_NAME" \
    --region "$REGION" > /dev/null && \
echo "Domain deleted: $DOMAIN_NAME"

echo "PASS"