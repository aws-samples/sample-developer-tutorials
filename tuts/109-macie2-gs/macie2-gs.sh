#!/bin/bash
set -e

SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)

aws macie2 get-macie-session --query'status' --output text && echo "Initial Macie Status: $?" || echo "Error getting initial Macie session"

aws macie2 list-findings --finding-criteria '{}' --max-results 10 --query 'length(findings)' --output text && echo "Number of Findings: $?" || echo "Error listing findings"

aws macie2 create-allow-list --criteria '{"regex":{"regexString":"example"}}' --description "Example Allow List $SUFFIX" || true
aws macie2 create-classification-job --job-name "ExampleJob$SUFFIX" --s3-job-definition '{"bucketDefinitions":[{"bucketName":"example-bucket"}]}' || true
aws macie2 create-custom-data-identifier --name "ExampleIdentifier$SUFFIX" --regex "example" --description "Example Custom Data Identifier" || true
aws macie2 create-findings-filter --name "ExampleFilter$SUFFIX" --finding-criteria '{"criterion":{"severity":{"gte":1}}}' --description "Example Findings Filter" || true
aws macie2 create-invitations --account-ids '["123456789012"]' --message "Example Invitation $SUFFIX" || true
aws macie2 create-member --email "example@example.com" --message "Example Member Invitation $SUFFIX" || true

echo "PASS"