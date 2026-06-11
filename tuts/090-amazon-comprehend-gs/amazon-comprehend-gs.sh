#!/bin/bash
# Tutorial: Detect sentiment, entities, and key phrases with Amazon Comprehend
# Source: https://docs.aws.amazon.com/comprehend/latest/dg/get-started-api.html

WORK_DIR=$(mktemp -d)
LOG_FILE="$WORK_DIR/comprehend-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null)}}
if [ -z "$REGION" ]; then
    echo "ERROR: No AWS region configured. Set one with: export AWS_DEFAULT_REGION=us-east-1"
    exit 1
fi
export AWS_DEFAULT_REGION="$REGION"
echo "Region: $REGION"

TEXT="Amazon Comprehend is a natural language processing service that uses machine learning to find insights and relationships in text. The service can identify the language of the text, extract key phrases, places, people, brands, or events, and understand how positive or negative the text is."

echo ""
echo "Sample text:"
echo "  $TEXT"
echo ""

# Step 1: Detect dominant language
echo "Step 1: Detecting dominant language"
aws comprehend detect-dominant-language --text "$TEXT" \
    --query 'Languages[0].{Language:LanguageCode,Confidence:Score}' --output table

# Step 2: Detect sentiment
echo ""
echo "Step 2: Detecting sentiment"
aws comprehend detect-sentiment --text "$TEXT" --language-code en \
    --query '{Sentiment:Sentiment,Positive:SentimentScore.Positive,Negative:SentimentScore.Negative,Neutral:SentimentScore.Neutral}' --output table

# Step 3: Detect entities
echo ""
echo "Step 3: Detecting entities"
aws comprehend detect-entities --text "$TEXT" --language-code en \
    --query 'Entities[].{Text:Text,Type:Type,Score:Score}' --output table

# Step 4: Detect key phrases
echo ""
echo "Step 4: Detecting key phrases"
aws comprehend detect-key-phrases --text "$TEXT" --language-code en \
    --query 'KeyPhrases[].{Text:Text,Score:Score}' --output table

# Step 5: Detect PII entities
echo ""
echo "Step 5: Detecting PII entities"
PII_TEXT="Please contact Jane Smith at jane.smith@example.com or call 555-0123. Her account number is 1234567890."
echo "  PII sample: $PII_TEXT"
aws comprehend detect-pii-entities --text "$PII_TEXT" --language-code en \
    --query 'Entities[].{Type:Type,Score:Score}' --output table

echo ""
echo "Tutorial complete. No resources were created — Comprehend is a stateless API."
rm -rf "$WORK_DIR"
