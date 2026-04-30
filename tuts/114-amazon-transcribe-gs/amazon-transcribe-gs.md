# Transcribe audio to text with Amazon Transcribe

This tutorial shows you how to create a sample audio file, upload it to Amazon S3, start a transcription job with Amazon Transcribe, wait for the job to complete, retrieve the results, and list recent transcription jobs.

## Prerequisites

- AWS CLI configured with credentials and a default region
- Python 3 installed (used to generate a WAV file)
- Permissions for `transcribe:StartTranscriptionJob`, `transcribe:GetTranscriptionJob`, `transcribe:ListTranscriptionJobs`, `transcribe:DeleteTranscriptionJob`, `s3:CreateBucket`, `s3:PutObject`, `s3:DeleteObject`, `s3:DeleteBucket`

## Step 1: Create a sample audio file

Generate a 1-second WAV file containing silence using Python. This gives Transcribe a valid audio file to process without needing an external recording.

```bash
python3 -c "
import struct, wave
with wave.open('/tmp/sample.wav', 'w') as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(16000)
    w.writeframes(struct.pack('<' + 'h' * 16000, *([0] * 16000)))
"
```

The file is 16 kHz mono PCM, which is the recommended format for Amazon Transcribe. One second of silence produces a ~32 KB file.

## Step 2: Upload to S3

Create an S3 bucket and upload the audio file. Transcribe reads input from S3.

```bash
BUCKET_NAME="transcribe-tut-$(openssl rand -hex 4)-$(aws sts get-caller-identity --query 'Account' --output text)"

aws s3api create-bucket --bucket "$BUCKET_NAME"
aws s3 cp /tmp/sample.wav "s3://$BUCKET_NAME/sample.wav" --quiet
```

For regions other than `us-east-1`, the script adds `--create-bucket-configuration LocationConstraint=$REGION`.

## Step 3: Start a transcription job

Start an asynchronous transcription job pointing to the uploaded audio.

```bash
JOB_NAME="tut-job-$(openssl rand -hex 4)"

aws transcribe start-transcription-job \
    --transcription-job-name "$JOB_NAME" \
    --language-code en-US \
    --media "MediaFileUri=s3://$BUCKET_NAME/sample.wav" \
    --output-bucket-name "$BUCKET_NAME" \
    --query 'TranscriptionJob.{Name:TranscriptionJobName,Status:TranscriptionJobStatus}' \
    --output table
```

`--language-code` specifies the language of the audio. `--output-bucket-name` tells Transcribe where to write the JSON result file. Without it, Transcribe uses a service-managed bucket.

## Step 4: Wait for completion

Poll the job status until it reaches `COMPLETED` or `FAILED`.

```bash
for i in $(seq 1 30); do
    STATUS=$(aws transcribe get-transcription-job \
        --transcription-job-name "$JOB_NAME" \
        --query 'TranscriptionJob.TranscriptionJobStatus' --output text)
    echo "  Status: $STATUS"
    [ "$STATUS" = "COMPLETED" ] || [ "$STATUS" = "FAILED" ] && break
    sleep 5
done
```

Most short audio files complete within 15–30 seconds. The script polls every 5 seconds with a 150-second timeout.

## Step 5: Get results

Retrieve the transcript URI from the completed job.

```bash
aws transcribe get-transcription-job \
    --transcription-job-name "$JOB_NAME" \
    --query 'TranscriptionJob.Transcript.TranscriptFileUri' --output text
```

The result is a JSON file in your S3 bucket containing the transcript text, confidence scores, and word-level timestamps. Since the input was silence, the transcript will be empty or minimal.

## Step 6: List transcription jobs

List recent completed transcription jobs.

```bash
aws transcribe list-transcription-jobs --status COMPLETED \
    --query 'TranscriptionJobSummaries[:3].{Name:TranscriptionJobName,Status:TranscriptionJobStatus,Created:CreationTime}' \
    --output table
```

You can filter by `--status` (`QUEUED`, `IN_PROGRESS`, `COMPLETED`, `FAILED`) and by `--job-name-contains` to find specific jobs.

## Cleanup

Delete the transcription job and the S3 bucket:

```bash
aws transcribe delete-transcription-job --transcription-job-name "$JOB_NAME"
aws s3 rm "s3://$BUCKET_NAME" --recursive
aws s3 rb "s3://$BUCKET_NAME"
```

Amazon Transcribe charges per second of audio transcribed. This tutorial transcribes 1 second of audio, costing a fraction of a cent. The S3 bucket is also deleted during cleanup.

The script automates all steps including cleanup:

```bash
bash amazon-transcribe-gs.sh
```

## Related resources

- [Getting started with Amazon Transcribe](https://docs.aws.amazon.com/transcribe/latest/dg/getting-started.html)
- [Amazon Transcribe API reference](https://docs.aws.amazon.com/transcribe/latest/APIReference/Welcome.html)
- [Supported languages](https://docs.aws.amazon.com/transcribe/latest/dg/supported-languages.html)
- [Amazon Transcribe pricing](https://aws.amazon.com/transcribe/pricing/)
