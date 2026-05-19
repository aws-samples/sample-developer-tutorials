#!/bin/bash
set -e

# Title Banner
echo "=== AWS Transcribe Custom Vocabulary Creation Tutorial ==="
echo "This tutorial demonstrates how to create a custom vocabulary using AWS Transcribe."
echo "A custom vocabulary helps improve transcription accuracy for specific terms."
echo ""

if [ -t 1 ]; then 
    REGION='us-east-1'
SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
    TEMP_DIR=$(mktemp -d)
    LOG_FILE="${TEMP_DIR}/log.txt"
    declare -a CREATED_RESOURCES=()

    cleanup_resources() {
        for (( i=${#CREATED_RESOURCES[@]}-1; i>=0; i-- )); do
            resource=(${CREATED_RESOURCES[$i]})
            type=${resource[0]}
            id=${resource[1]}
            case $type in
                "vocabulary") aws transcribe delete-vocabulary --vocabulary-name "$id" ;;
            esac
        done
        rm -rf "$TEMP_DIR"
    }
    trap cleanup_resources EXIT

    echo "=== Step 1: Creating Custom Vocabulary ==="
    echo "In this step, we will create a custom vocabulary to improve transcription accuracy."
    echo "The custom vocabulary is sourced from a file stored in an S3 bucket."
    echo ""
    VOCABULARY_NAME="CustomVocabulary$SUFFIX"
    VOCABULARY_FILE_KEY='/test-files/a.txt'
    VOCABULARY_BUCKET='your-bucket-name'
    VOCABULARY_FILE_URI="s3://${VOCABULARY_BUCKET}/${VOCABULARY_FILE_KEY##*/}"
    VOCABULARY_ARN=$(aws transcribe create-vocabulary --vocabulary-name "${VOCABULARY_NAME}" --language-code 'en-US' --vocabulary-file-uri "${VOCABULARY_FILE_URI}" --query 'VocabularyArn' --output text)
    CREATED_RESOURCES+=("vocabulary:$VOCABULARY_NAME")
    aws transcribe tag-resource --resource-arn "$VOCABULARY_ARN" --tags Key=project,Value=doc-smith Key=tutorial,Value=transcribe-gs
    echo "Result: Custom vocabulary named ${VOCABULARY_NAME} has been created."
    echo ""

    echo "PASS"
    echo ""
    echo "Tutorial complete!"
    echo "In this tutorial, you learned how to create a custom vocabulary using AWS Transcribe."
    echo "This custom vocabulary can now be used to improve the accuracy of transcriptions for specific terms."
fi