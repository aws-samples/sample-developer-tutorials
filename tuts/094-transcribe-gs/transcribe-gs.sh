#!/bin/bash
set -e
SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
VOCAB="vocab-${SUFFIX}"

echo "Creating vocabulary: $VOCAB"
aws transcribe create-vocabulary   --vocabulary-name "$VOCAB"   --language-code en-US   --phrases "AWS" "DynamoDB" "CloudFormation" "Kubernetes" "Bedrock"

echo "Waiting for vocabulary to be ready..."
for i in $(seq 1 20); do
  STATE=$(aws transcribe get-vocabulary --vocabulary-name "$VOCAB" --query 'VocabularyState' --output text)
  if [ "$STATE" = "READY" ] || [ "$STATE" = "FAILED" ]; then break; fi
  sleep 3
done
echo "State: $STATE"

echo "Listing vocabularies..."
aws transcribe list-vocabularies --query 'Vocabularies[].VocabularyName' --output text

echo "Deleting vocabulary..."
aws transcribe delete-vocabulary --vocabulary-name "$VOCAB"
echo "PASS"
