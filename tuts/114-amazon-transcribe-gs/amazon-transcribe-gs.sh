#!/bin/bash
# Tutorial: Transcribe audio to text with Amazon Transcribe
# Source: https://docs.aws.amazon.com/transcribe/latest/dg/getting-started.html

WORK_DIR=$(mktemp -d)
LOG_FILE="$WORK_DIR/transcribe-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null)}}
if [ -z "$REGION" ]; then
    echo "ERROR: No AWS region configured. Set one with: export AWS_DEFAULT_REGION=us-east-1"
    exit 1
fi
export AWS_DEFAULT_REGION="$REGION"
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
echo "Region: $REGION"

RANDOM_ID=$(openssl rand -hex 4)
BUCKET_NAME="transcribe-tut-${RANDOM_ID}-${ACCOUNT_ID}"
JOB_NAME="tut-job-${RANDOM_ID}"

handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }
trap 'handle_error $LINENO' ERR

cleanup() {
    echo ""
    echo "Cleaning up resources..."
    aws transcribe delete-transcription-job --transcription-job-name "$JOB_NAME" 2>/dev/null && echo "  Deleted job $JOB_NAME"
    if aws s3 ls "s3://$BUCKET_NAME" > /dev/null 2>&1; then
        aws s3 rm "s3://$BUCKET_NAME" --recursive --quiet 2>/dev/null
        aws s3 rb "s3://$BUCKET_NAME" 2>/dev/null && echo "  Deleted bucket $BUCKET_NAME"
    fi
    rm -rf "$WORK_DIR"
    echo "Cleanup complete."
}

# Step 1: Create a sample audio file (WAV with silence)
echo "Step 1: Creating sample audio file"
python3 -c "
import struct, wave
with wave.open('$WORK_DIR/sample.wav', 'w') as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(16000)
    w.writeframes(struct.pack('<' + 'h' * 16000, *([0] * 16000)))
"
echo "  Created sample.wav (1 second, 16kHz mono)"

# Step 2: Upload to S3
echo "Step 2: Uploading to S3"
if [ "$REGION" = "us-east-1" ]; then
    aws s3api create-bucket --bucket "$BUCKET_NAME" > /dev/null
else
    aws s3api create-bucket --bucket "$BUCKET_NAME" \
        --create-bucket-configuration LocationConstraint="$REGION" > /dev/null
fi
aws s3 cp "$WORK_DIR/sample.wav" "s3://$BUCKET_NAME/sample.wav" --quiet
echo "  Uploaded to s3://$BUCKET_NAME/sample.wav"

# Step 3: Start transcription job
echo "Step 3: Starting transcription job: $JOB_NAME"
aws transcribe start-transcription-job \
    --transcription-job-name "$JOB_NAME" \
    --language-code en-US \
    --media "MediaFileUri=s3://$BUCKET_NAME/sample.wav" \
    --output-bucket-name "$BUCKET_NAME" \
    --query 'TranscriptionJob.{Name:TranscriptionJobName,Status:TranscriptionJobStatus}' --output table

# Step 4: Wait for completion
echo "Step 4: Waiting for transcription to complete..."
for i in $(seq 1 30); do
    STATUS=$(aws transcribe get-transcription-job --transcription-job-name "$JOB_NAME" \
        --query 'TranscriptionJob.TranscriptionJobStatus' --output text)
    echo "  Status: $STATUS"
    [ "$STATUS" = "COMPLETED" ] || [ "$STATUS" = "FAILED" ] && break
    sleep 5
done

# Step 5: Get results
echo "Step 5: Transcription results"
if [ "$STATUS" = "COMPLETED" ]; then
    RESULT_URI=$(aws transcribe get-transcription-job --transcription-job-name "$JOB_NAME" \
        --query 'TranscriptionJob.Transcript.TranscriptFileUri' --output text)
    echo "  Result URI: $RESULT_URI"
    echo "  (Audio was silence, so transcript will be empty or minimal)"
else
    echo "  Job status: $STATUS"
fi

# Step 6: List jobs
echo "Step 6: Listing transcription jobs"
aws transcribe list-transcription-jobs --status COMPLETED \
    --query 'TranscriptionJobSummaries[:3].{Name:TranscriptionJobName,Status:TranscriptionJobStatus,Created:CreationTime}' --output table 2>/dev/null || \
    echo "  No completed jobs"

echo ""
echo "Tutorial complete."
echo "Do you want to clean up all resources? (y/n): "
read -r CHOICE
if [[ "$CHOICE" =~ ^[Yy]$ ]]; then
    cleanup
else
    echo "Manual cleanup:"
    echo "  aws transcribe delete-transcription-job --transcription-job-name $JOB_NAME"
    echo "  aws s3 rm s3://$BUCKET_NAME --recursive && aws s3 rb s3://$BUCKET_NAME"
fi
