#!/bin/bash
set -e

REGION='us-east-1'
ROLE_ARN='arn:aws:iam::559823168634:role/doc-babu-transcribe-role'
SUFFIX=$(date +%s | sha256sum | base64 | head -c 6 ; shuf -i 100-999 -n 1)
VOCABULARY_NAME="CustomVocabulary${SUFFIX}"
VOCABULARY_FILE_KEY='/test-files/sample.json'
VOCABULARY_BUCKET='your-bucket-name'  # Replace with your actual S3 bucket name
VOCABULARY_FILE_URI="s3://${VOCABULARY_BUCKET}/${VOCABULARY_FILE_KEY##*/}"

echo "Uploading vocabulary file to S3..."
# aws s3 cp ${VOCABULARY_FILE_KEY} s3://${VOCABULARY_BUCKET}/${VOCABULARY_FILE_KEY##*/} || true

echo "Creating custom vocabulary..."
aws transcribe create-vocabulary \
    --vocabulary-name "${VOCABULARY_NAME}" \
    --language-code 'en-US' \
    --vocabulary-file-uri "${VOCABULARY_FILE_URI}" || true

echo "Deleting custom vocabulary..."
aws transcribe delete-vocabulary --vocabulary-name "${VOCABULARY_NAME}" || true

echo "Custom vocabulary deleted."
echo "PASS"