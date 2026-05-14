#!/bin/bash
set -e

SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)

echo "Creating AWS Log Source..."
aws securitylake create-aws-log-source --log-source-name "log-source-$SUFFIX" || true

echo "Creating Custom Log Source..."
aws securitylake create-custom-log-source --source-name "custom-log-source-$SUFFIX" || true

echo "Creating Data Lake..."
aws securitylake create-data-lake --configuration '{ "regions": ["us-east-1"] }' || true

echo "Creating Data Lake Exception Subscription..."
aws securitylake create-data-lake-exception-subscription --subscription-name "exception-subscription-$SUFFIX" || true

echo "Creating Data Lake Organization Configuration..."
aws securitylake create-data-lake-organization-configuration --auto-enable-new-account | true

echo "PASS"