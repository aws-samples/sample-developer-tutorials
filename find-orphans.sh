#!/bin/bash
# Find tutorial resources that may have been left behind by failed script runs.
# Searches by the 'tutorial' tag that all tutorial scripts apply to resources.
# Usage: ./find-orphans.sh [tutorial-id]
# Example: ./find-orphans.sh kinesis
#          ./find-orphans.sh          (finds all tutorial-tagged resources)
set -eo pipefail

FILTER="${1:-}"

echo "Searching for resources tagged with 'tutorial'..."
echo ""

if [ -n "$FILTER" ]; then
    echo "Filter: tutorial=$FILTER"
    RESULTS=$(aws resourcegroupstaggingapi get-resources \
        --tag-filters "Key=tutorial,Values=$FILTER" \
        --query 'ResourceTagMappingList[].ResourceARN' --output text 2>/dev/null)
else
    RESULTS=$(aws resourcegroupstaggingapi get-resources \
        --tag-filters "Key=tutorial" \
        --query 'ResourceTagMappingList[].ResourceARN' --output text 2>/dev/null)
fi

if [ -z "$RESULTS" ]; then
    echo "No orphaned resources found."
    exit 0
fi

echo "Found resources:"
echo "$RESULTS" | tr '\t' '\n' | while read ARN; do
    # Extract service and resource type from ARN
    SERVICE=$(echo "$ARN" | cut -d: -f3)
    TYPE=$(echo "$ARN" | cut -d: -f6 | cut -d/ -f1)
    NAME=$(echo "$ARN" | rev | cut -d/ -f1 | rev)
    printf "  %-20s %-20s %s\n" "$SERVICE" "$TYPE" "$NAME"
done

echo ""
TOTAL=$(echo "$RESULTS" | tr '\t' '\n' | wc -l)
echo "Total: $TOTAL resources"
echo ""
echo "To delete these manually, use the appropriate AWS CLI delete commands."
echo "To delete all resources from a specific tutorial:"
echo "  aws resourcegroupstaggingapi get-resources --tag-filters Key=tutorial,Values=<id> --query 'ResourceTagMappingList[].ResourceARN' --output text"
