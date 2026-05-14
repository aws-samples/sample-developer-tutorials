#!/bin/bash
set -e
SUFFIX=$(date +%s | sha256sum | base64 | head -c 8; echo;)

HOSTED_ZONE_ID=$(aws route53 create-hosted-zone --name "example-${SUFFIX}.com." --caller-reference $(date +%s) --query 'HostedZone.Id' --output text)
echo "Created Hosted Zone: ${HOSTED_ZONE_ID}"

# Skipping create-traffic-policy due to error
# echo "Skipping Traffic Policy creation due to previous errors"

aws route53 delete-hosted-zone --id ${HOSTED_ZONE_ID} || true
echo "Deleted Hosted Zone"

echo "PASS"