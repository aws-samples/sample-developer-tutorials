#!/bin/bash

# Amazon Textract Getting Started Tutorial Script
# This script demonstrates how to use Amazon Textract to analyze document text


# Set up logging
LOG_FILE="textract-tutorial.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "==================================================="
echo "Amazon Textract Getting Started Tutorial"
echo "==================================================="
echo "This script will guide you through using Amazon Textract to analyze document text."
echo ""

# Function to check for errors in command output and exit code
check_error() {
    local exit_code=$1
    local output=$2
    local cmd=$3
    
    if [ $exit_code -ne 0 ] || echo "$output" | grep -i "error" > /dev/null; then
        echo "ERROR: Command failed: $cmd"
        echo "$output"
        cleanup_on_error
        exit 1
    fi
}

# Function to clean up resources on error
cleanup_on_error() {
    echo "Error encountered. Cleaning up resources..."
    
    # Clean up temporary JSON files
    if [ -f "document.json" ]; then
        rm -f document.json
    fi
    
    if [ -f "features.json" ]; then
        rm -f features.json
    fi
    
    if [ -n "$DOCUMENT_NAME" ] && [ -n "$BUCKET_NAME" ]; then
        echo "Deleting document from S3..."
        aws s3 rm "s3://$BUCKET_NAME/$DOCUMENT_NAME" || echo "Failed to delete document"
    fi
    
    if [ -n "$BUCKET_NAME" ]; then
        echo "Deleting S3 bucket..."
        aws s3 rb "s3://$BUCKET_NAME" --force || echo "Failed to delete bucket"
    fi
}

# Verify AWS CLI is installed and configured
echo "Verifying AWS CLI configuration..."
AWS_CONFIG_OUTPUT=$(aws configure list 2>&1)
AWS_CONFIG_STATUS=$?
if [ $AWS_CONFIG_STATUS -ne 0 ]; then
    echo "ERROR: AWS CLI is not properly configured."
    echo "$AWS_CONFIG_OUTPUT"
    exit 1
fi

# Verify AWS region is configured and supports Textract
AWS_REGION=$(aws configure get region)
if [ -z "$AWS_REGION" ]; then
    echo "ERROR: No AWS region configured. Please run 'aws configure' to set a default region."
    exit 1
fi

# Check if Textract is available in the configured region
echo "Checking if Amazon Textract is available in region $AWS_REGION..."
TEXTRACT_CHECK=$(aws textract help 2>&1)
TEXTRACT_CHECK_STATUS=$?
if [ $TEXTRACT_CHECK_STATUS -ne 0 ]; then
    echo "ERROR: Amazon Textract may not be available in region $AWS_REGION."
    echo "$TEXTRACT_CHECK"
    exit 1
fi

# Generate a random identifier for S3 bucket
RANDOM_ID=$(openssl rand -hex 6)
BUCKET_NAME="textract-${RANDOM_ID}"
DOCUMENT_NAME="document.png"
RESOURCES_CREATED=()

# Step 1: Create S3 bucket
echo "Creating S3 bucket: $BUCKET_NAME"
CREATE_BUCKET_OUTPUT=$(aws s3 mb "s3://$BUCKET_NAME" 2>&1)
CREATE_BUCKET_STATUS=$?
echo "$CREATE_BUCKET_OUTPUT"
check_error $CREATE_BUCKET_STATUS "$CREATE_BUCKET_OUTPUT" "aws s3 mb s3://$BUCKET_NAME"
RESOURCES_CREATED+=("S3 Bucket: $BUCKET_NAME")

# Step 2: Check if sample document exists, if not create a simple one
if [ ! -f "$DOCUMENT_NAME" ]; then
    echo "Sample document not found. Please provide a document to analyze."
    echo "Enter the path to your document (must be an image file like PNG or JPEG):"
    read -r DOCUMENT_PATH
    
    if [ ! -f "$DOCUMENT_PATH" ]; then
        echo "File not found: $DOCUMENT_PATH"
        cleanup_on_error
        exit 1
    fi
    
    DOCUMENT_NAME=$(basename "$DOCUMENT_PATH")
    echo "Using document: $DOCUMENT_PATH as $DOCUMENT_NAME"
    
    # Copy the document to the current directory
    cp "$DOCUMENT_PATH" "./$DOCUMENT_NAME"
fi

# Step 3: Upload document to S3
echo "Uploading document to S3..."
UPLOAD_OUTPUT=$(aws s3 cp "./$DOCUMENT_NAME" "s3://$BUCKET_NAME/" 2>&1)
UPLOAD_STATUS=$?
echo "$UPLOAD_OUTPUT"
check_error $UPLOAD_STATUS "$UPLOAD_OUTPUT" "aws s3 cp ./$DOCUMENT_NAME s3://$BUCKET_NAME/"
RESOURCES_CREATED+=("S3 Object: s3://$BUCKET_NAME/$DOCUMENT_NAME")

# Step 4: Analyze document with Amazon Textract
echo "Analyzing document with Amazon Textract..."
echo "This may take a few seconds..."

# Create a JSON file for the document parameter to avoid shell escaping issues
cat > document.json << EOF
{
  "S3Object": {
    "Bucket": "$BUCKET_NAME",
    "Name": "$DOCUMENT_NAME"
  }
}
EOF

# Create a JSON file for the feature types parameter
cat > features.json << EOF
["TABLES","FORMS","SIGNATURES"]
EOF

ANALYZE_OUTPUT=$(aws textract analyze-document --document file://document.json --feature-types file://features.json 2>&1)
ANALYZE_STATUS=$?

echo "Analysis complete."
if [ $ANALYZE_STATUS -ne 0 ]; then
    echo "ERROR: Document analysis failed"
    echo "$ANALYZE_OUTPUT"
    cleanup_on_error
    exit 1
fi

# Save the analysis results to a file
echo "$ANALYZE_OUTPUT" > textract-analysis-results.json
echo "Analysis results saved to textract-analysis-results.json"
RESOURCES_CREATED+=("Local file: textract-analysis-results.json")

# Display a summary of the analysis
echo ""
echo "==================================================="
echo "Analysis Summary"
echo "==================================================="
PAGES=$(echo "$ANALYZE_OUTPUT" | grep -o '"Pages": [0-9]*' | awk '{print $2}')
echo "Document pages: $PAGES"

BLOCKS_COUNT=$(echo "$ANALYZE_OUTPUT" | grep -o '"BlockType":' | wc -l)
echo "Total blocks detected: $BLOCKS_COUNT"

# Count different block types
PAGE_COUNT=$(echo "$ANALYZE_OUTPUT" | grep -o '"BlockType": "PAGE"' | wc -l)
LINE_COUNT=$(echo "$ANALYZE_OUTPUT" | grep -o '"BlockType": "LINE"' | wc -l)
WORD_COUNT=$(echo "$ANALYZE_OUTPUT" | grep -o '"BlockType": "WORD"' | wc -l)
TABLE_COUNT=$(echo "$ANALYZE_OUTPUT" | grep -o '"BlockType": "TABLE"' | wc -l)
CELL_COUNT=$(echo "$ANALYZE_OUTPUT" | grep -o '"BlockType": "CELL"' | wc -l)
KEY_VALUE_COUNT=$(echo "$ANALYZE_OUTPUT" | grep -o '"BlockType": "KEY_VALUE_SET"' | wc -l)
SIGNATURE_COUNT=$(echo "$ANALYZE_OUTPUT" | grep -o '"BlockType": "SIGNATURE"' | wc -l)

echo "Pages: $PAGE_COUNT"
echo "Lines of text: $LINE_COUNT"
echo "Words: $WORD_COUNT"
echo "Tables: $TABLE_COUNT"
echo "Table cells: $CELL_COUNT"
echo "Key-value pairs: $KEY_VALUE_COUNT"
echo "Signatures: $SIGNATURE_COUNT"
echo ""

# Cleanup confirmation
echo ""
echo "==================================================="
echo "RESOURCES CREATED"
echo "==================================================="
for resource in "${RESOURCES_CREATED[@]}"; do
    echo "- $resource"
done
echo ""
echo "==================================================="
echo "CLEANUP CONFIRMATION"
echo "==================================================="
echo "Do you want to clean up all created resources? (y/n): "
read -r CLEANUP_CHOICE

if [[ "$CLEANUP_CHOICE" =~ ^[Yy] ]]; then
    echo "Cleaning up resources..."
    
    # Delete document from S3
    echo "Deleting document from S3..."
    DELETE_DOC_OUTPUT=$(aws s3 rm "s3://$BUCKET_NAME/$DOCUMENT_NAME" 2>&1)
    DELETE_DOC_STATUS=$?
    echo "$DELETE_DOC_OUTPUT"
    check_error $DELETE_DOC_STATUS "$DELETE_DOC_OUTPUT" "aws s3 rm s3://$BUCKET_NAME/$DOCUMENT_NAME"
    
    # Delete S3 bucket
    echo "Deleting S3 bucket..."
    DELETE_BUCKET_OUTPUT=$(aws s3 rb "s3://$BUCKET_NAME" --force 2>&1)
    DELETE_BUCKET_STATUS=$?
    echo "$DELETE_BUCKET_OUTPUT"
    check_error $DELETE_BUCKET_STATUS "$DELETE_BUCKET_OUTPUT" "aws s3 rb s3://$BUCKET_NAME --force"
    
    # Delete local JSON files
    rm -f document.json features.json
    
    echo "Cleanup complete. The analysis results file (textract-analysis-results.json) has been kept."
else
    echo "Resources have been preserved."
fi

echo ""
echo "==================================================="
echo "Tutorial complete!"
echo "==================================================="
echo "You have successfully analyzed a document using Amazon Textract."
echo "The analysis results are available in textract-analysis-results.json"
echo ""
