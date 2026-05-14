#!/bin/bash
set -e

REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
COLLABORATION_NAME="collab-${SUFFIX}"

# Create Collaboration
COLLAB_ID=$(aws cleanrooms create-collaboration \
    --cli-input-json "{\"name\":\"$COLLABORATION_NAME\",\"description\":\"Test collaboration\",\"creatorMemberAbilities\":[\"CAN_QUERY\",\"CAN_RECEIVE_RESULTS\"],\"creatorDisplayName\":\"DocBabu\",\"members\":[],\"queryLogStatus\":\"DISABLED\"}" \
    --query "collaboration.id" --output text)
echo "Collaboration created: $COLLAB_ID"

# Verify Collaboration
COLLAB_DETAILS=$(aws cleanrooms get-collaboration \
    --collaboration-identifier "$COLLAB_ID" \
    --query "collaboration.name" --output text)
echo "Collaboration verified: $COLLAB_DETAILS"

# List Collaborations
COLLABORATIONS_COUNT=$(aws cleanrooms list-collaborations \
    --query "length(collaborationList)" --output text)
echo "Listed collaborations: $COLLABORATIONS_COUNT"

# Clean up
aws cleanrooms delete-collaboration \
    --collaboration-identifier "$COLLAB_ID" || true
echo "Collaboration deleted"

echo "PASS"