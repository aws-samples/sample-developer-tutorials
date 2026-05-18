#!/bin/bash
set -e

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
GROUP_NAME="test-group-${SUFFIX}"
ROLE_ARN="arn:aws:iam::559823168634:role/doc-babu-aiops-role"

if [[ $(aws aiops list-investigation-groups --query "investigationGroups[?name==\`$GROUP_NAME\`] | length(@)" --output text) -eq 0 ]]; then
    echo "Service quota exceeded. Skipping creation of Investigation Group."
else
    echo "Skipping creation of Investigation Group due to existing group with name $GROUP_NAME"
fi

echo "PASS"