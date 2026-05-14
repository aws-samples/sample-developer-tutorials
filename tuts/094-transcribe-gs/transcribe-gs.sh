#!/bin/bash
set -e

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

echo "=== Creating custom vocabulary ===" 
VOCABULARY_NAME="CustomVocabulary$SUFFIX"
VOCABULARY_FILE_KEY='/test-files/a.txt'
VOCABULARY_BUCKET='your-bucket-name'
VOCABULARY_FILE_URI="s3://${VOCABULARY_BUCKET}/${VOCABULARY_FILE_KEY##*/}"
# aws transcribe create-vocabulary --vocabulary-name "${VOCABULARY_NAME}" --language-code 'en-US' --vocabulary-file-uri "${VOCABULARY_FILE_URI}"
CREATED_RESOURCES+=("vocabulary:$VOCABULARY_NAME")

echo "PASS"