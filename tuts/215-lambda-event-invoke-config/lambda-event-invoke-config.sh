#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/tut.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null))}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
echo "Step 1: Listing functions with event invoke configs"
for F in $(aws lambda list-functions --query 'Functions[:5].FunctionName' --output text 2>/dev/null); do
    CONFIG=$(aws lambda get-function-event-invoke-config --function-name "$F" 2>/dev/null)
    [ -n "$CONFIG" ] && echo "  $F: $(echo $CONFIG | python3 -c 'import sys,json;c=json.load(sys.stdin);print(f"MaxRetry={c.get(\"MaximumRetryAttempts\",\"default\")}, MaxAge={c.get(\"MaximumEventAgeInSeconds\",\"default\")}")')"
done
echo "  (Functions without custom config use defaults: 2 retries, 6 hours max age)"
echo ""; echo "Tutorial complete. Read-only."; rm -rf "$WORK_DIR"
