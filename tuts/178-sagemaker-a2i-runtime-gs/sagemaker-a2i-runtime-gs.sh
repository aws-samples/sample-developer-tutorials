#!/bin/bash
set -e

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo "Listing Human Loops:"
HUMAN_LOOPS=$(aws sagemaker-a2i-runtime list-human-loops --creation-sort-order Descending --max-results 10 --query 'HumanLoopSummaries[*].HumanLoopName' --output text)

if [ -n "$HUMAN_LOOPS" ]; then
    HUMAN_LOOP_NAME=$(echo "$HUMAN_LOOPS" | head -n 1)
    echo "Describing Human Loop:"
    aws sagemaker-a2i-runtime describe-human-loop --human-loop-name "$HUMAN_LOOP_NAME"
else
    echo "No existing Human Loops found. Creating a new one."
    HUMAN_LOOP_NAME="test-human-loop-$SUFFIX"
    aws sagemaker-a2i-runtime start-human-loop \
        --human-loop-name "$HUMAN_LOOP_NAME" \
        --human-loop-input file://$TEMP_DIR/input.json \
        --human-loop-config file://$TEMP_DIR/config.json
    sleep 10  # Wait for the HumanLoop to start
    echo "Describing newly created Human Loop:"
    aws sagemaker-a2i-runtime describe-human-loop --human-loop-name "$HUMAN_LOOP_NAME"
    echo "Stopping Human Loop:"
    aws sagemaker-a2i-runtime stop-human-loop --human-loop-name "$HUMAN_LOOP_NAME"
    sleep 10  # Wait for the HumanLoop to stop
    echo "Deleting Human Loop:"
    aws sagemaker-a2i-runtime delete-human-loop --human-loop-name "$HUMAN_LOOP_NAME"
fi

echo "PASS"
```

Create the input and config JSON files in the `$TEMP_DIR`:

```bash
cat > $TEMP_DIR/input.json <<EOF
{
    "InputContent": "{\"task\":\"example\"}",
    "DataSources": {
        "S3DataSource": {
            "S3Uri": "s3://example-bucket/example-key"
        }
    }
}
EOF

cat > $TEMP_DIR/config.json <<EOF
{
    "WorkteamArn": "arn:aws:sagemaker:us-east-1:123456789012:workteam/private-123456789012",
    "HumanTaskUiArn": "arn:aws:sagemaker:us-east-1:123456789012:human-task-ui/123456789012",
    "TaskCount": 1,
    "TaskDescription": "Example task",
    "TaskTitle": "Example Task Title"
}
EOF