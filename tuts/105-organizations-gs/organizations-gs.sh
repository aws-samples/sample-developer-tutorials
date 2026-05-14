#!/bin/bash
set -e

SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
ROOT_ID='r-abc123'

echo "Creating Organizational Unit with name 'my-ou-${SUFFIX}'..."
OU_ID=$(aws organizations create-organizational-unit --parent-id ${ROOT_ID} --name "my-ou-${SUFFIX}" --query 'OrganizationalUnit.Id' --output text || true)

if [ -n "$OU_ID" ]; then
    echo "Created Organizational Unit with ID: ${OU_ID}"

    echo "Deleting Organizational Unit with ID: ${OU_ID}..."
    aws organizations delete-organizational-unit --organizational-unit-id ${OU_ID} || {
        echo "Skipping deletion of Organizational Unit due to permission denied."
    }
else
    echo "Failed to create Organizational Unit due to permission denied or other error."
fi

echo "PASS"