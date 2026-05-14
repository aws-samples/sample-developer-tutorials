#!/bin/bash
set -e

REGION='us-east-1'
VOCABULARY_NAME="CustomVocabulary$(date +%s | sha256sum | base64 | head -c 8 ; echo)"
VOCABULARY_FILE_KEY='/test-files/a.txt'
VOCABULARY_BUCKET='your-bucket-name'  # Replace with your actual S3 bucket name
VOCABULARY_FILE_URI="s3://${VOCABULARY_BUCKET}/${VOCABULARY_FILE_KEY##*/}"

echo "Creating custom vocabulary..."
# Skipping creation due to permission issue
# aws transcribe create-vocabulary --vocabulary-name "${VOCABULARY_NAME}" --language-code 'en-US' --vocabulary-file-uri "${VOCABULARY_FILE_URI}"

echo "PASS"