#!/bin/bash
set -e

echo "=== AWS Route53 Tutorial: Creating and Deleting a Hosted Zone ==="
echo "This tutorial demonstrates how to create and delete an AWS Route53 Hosted Zone using the AWS CLI."
echo "We will generate a unique suffix, create a temporary directory for logging, and ensure all resources are cleaned up at the end."

if [ -t 1 ]; then 
    SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
    TEMP_DIR=$(mktemp -d)
    LOG_FILE="${TEMP_DIR}/log.txt"
    declare -a CREATED_RESOURCES=()

    cleanup_resources() {
        for (( i=${#CREATED_RESOURCES[@]}-1; i>=0; i-- )); do
            resource=(${CREATED_RESOURCES[$i]})
            type=${resource[0]}
            id=${resource[1]}
            case $type in
                "hosted-zone") aws route53 delete-hosted-zone --id $id ;;
            esac
        done
        rm -rf "$TEMP_DIR"
    }
    trap cleanup_resources EXIT

    REGION="${AWS_DEFAULT_REGION:-us-east-1}"

    echo "=== Step 1: Generating a Unique Suffix ==="
    echo "We generate a unique suffix to ensure the hosted zone name is unique."
    echo "This prevents conflicts with existing hosted zones."
    echo "Generated Suffix: ${SUFFIX}"
    echo ""

    echo "=== Step 2: Creating a Hosted Zone ==="
    echo "A Hosted Zone in Route53 is a collection of DNS records."
    echo "Creating a hosted zone allows you to route traffic to your resources using DNS."
    HOSTED_ZONE_ID=$(aws route53 create-hosted-zone --name "example-${SUFFIX}.com." --caller-reference $(date +%s) --query 'HostedZone.Id' --output text)
    echo "Created Hosted Zone: ${HOSTED_ZONE_ID}"
    CREATED_RESOURCES+=("hosted-zone:$HOSTED_ZONE_ID")
    echo ""

    echo "=== Step 3: Deleting the Hosted Zone ==="
    echo "It's important to clean up resources to avoid unnecessary costs and maintain organization."
    echo "We will now delete the hosted zone we created."
    aws route53 delete-hosted-zone --id ${HOSTED_ZONE_ID}
    echo "Deleted Hosted Zone"
    echo ""

    echo "Tutorial complete. You have learned how to create and delete an AWS Route53 Hosted Zone using the AWS CLI."
    echo "You also saw how to generate a unique suffix to ensure resource names are unique and how to clean up resources to avoid unnecessary costs."
fi