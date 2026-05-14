#!/bin/bash
set -e

REGION="us-east-1"
SUFFIX=$(date +%s | sha256sum | base64 | head -c 6)
DOMAIN_NAME="test-domain-${SUFFIX}"
ITEM_NAME="item-$(date +%s)"

echo "Creating domain..."
aws sdb create-domain --domain-name "$DOMAIN_NAME" || true

sleep 5  # Wait for domain to become active

echo "Verifying domain exists..."
DOMAINS=$(aws sdb list-domains --query 'Domains[].DomainName' --output text)
if [[! "$DOMAINS" == *"$DOMAIN_NAME"* ]]; then
    echo "Domain not found"
    exit 1
fi

echo "Putting attributes..."
aws sdb put-attributes --domain-name "$DOMAIN_NAME" --item-name "$ITEM_NAME" --attributes '{"attr1":"value1","attr2":"value2"}' || true

echo "Deleting domain..."
aws sdb delete-domain --domain-name "$DOMAIN_NAME" || true

sleep 5  # Wait for domain to be deleted

echo "Verifying domain deleted..."
DOMAINS=$(aws sdb list-domains --query 'Domains[].DomainName' --output text)
if [[ "$DOMAINS" == *"$DOMAIN_NAME"* ]]; then
    echo "Domain not deleted"
    exit 1
fi

echo "PASS"