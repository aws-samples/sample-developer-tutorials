#!/bin/bash
# Tutorial: Translate text between languages with Amazon Translate
# Source: https://docs.aws.amazon.com/translate/latest/dg/get-started.html

WORK_DIR=$(mktemp -d)
LOG_FILE="$WORK_DIR/translate-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null)}}
if [ -z "$REGION" ]; then
    echo "ERROR: No AWS region configured. Set one with: export AWS_DEFAULT_REGION=us-east-1"
    exit 1
fi
export AWS_DEFAULT_REGION="$REGION"
echo "Region: $REGION"

TEXT="Amazon Translate is a neural machine translation service that delivers fast, high-quality, affordable, and customizable language translation."

echo ""
echo "Source text (English):"
echo "  $TEXT"
echo ""

# Step 1: Translate English to Spanish
echo "Step 1: English → Spanish"
aws translate translate-text --text "$TEXT" \
    --source-language-code en --target-language-code es \
    --query 'TranslatedText' --output text
echo ""

# Step 2: Translate English to French
echo "Step 2: English → French"
aws translate translate-text --text "$TEXT" \
    --source-language-code en --target-language-code fr \
    --query 'TranslatedText' --output text
echo ""

# Step 3: Translate English to Japanese
echo "Step 3: English → Japanese"
aws translate translate-text --text "$TEXT" \
    --source-language-code en --target-language-code ja \
    --query 'TranslatedText' --output text
echo ""

# Step 4: Auto-detect source language
echo "Step 4: Auto-detect source language (German input)"
GERMAN="Amazon Translate ist ein neuronaler maschineller Übersetzungsdienst."
echo "  Input: $GERMAN"
aws translate translate-text --text "$GERMAN" \
    --source-language-code auto --target-language-code en \
    --query '{Translation:TranslatedText,DetectedLanguage:SourceLanguageCode}' --output table
echo ""

# Step 5: List supported languages
echo "Step 5: Listing supported languages (first 10)"
aws translate list-languages --query 'Languages[:10].{Name:LanguageName,Code:LanguageCode}' --output table

echo ""
echo "Tutorial complete. No resources were created — Translate is a stateless API."
rm -rf "$WORK_DIR"
