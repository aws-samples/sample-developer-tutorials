#!/bin/bash
# Tutorial: Create a KMS key and encrypt data
# Source: https://docs.aws.amazon.com/kms/latest/developerguide/getting-started.html

WORK_DIR=$(mktemp -d)
LOG_FILE="$WORK_DIR/kms-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null)}}
if [ -z "$REGION" ]; then
    echo "ERROR: No AWS region configured. Set one with: export AWS_DEFAULT_REGION=us-east-1"
    exit 1
fi
export AWS_DEFAULT_REGION="$REGION"
echo "Region: $REGION"

RANDOM_ID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
ALIAS_NAME="alias/tutorial-key-${RANDOM_ID}"

handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }
trap 'handle_error $LINENO' ERR

cleanup() {
    echo ""
    echo "Cleaning up resources..."
    if [ -n "$KEY_ID" ]; then
        aws kms schedule-key-deletion --key-id "$KEY_ID" --pending-window-in-days 7 > /dev/null 2>&1 && \
            echo "  Scheduled key $KEY_ID for deletion in 7 days"
    fi
    aws kms delete-alias --alias-name "$ALIAS_NAME" 2>/dev/null && echo "  Deleted alias $ALIAS_NAME"
    rm -rf "$WORK_DIR"
    echo "Cleanup complete."
}

# Step 1: Create a customer managed key
echo "Step 1: Creating a customer managed KMS key"
KEY_ID=$(aws kms create-key --description "Tutorial key ${RANDOM_ID}" \
    --query 'KeyMetadata.KeyId' --output text)
echo "  Key ID: $KEY_ID"

# Step 2: Create an alias
echo "Step 2: Creating alias: $ALIAS_NAME"
aws kms create-alias --alias-name "$ALIAS_NAME" --target-key-id "$KEY_ID"
echo "  Alias created"

# Step 3: Describe the key
echo "Step 3: Describing the key"
aws kms describe-key --key-id "$KEY_ID" \
    --query 'KeyMetadata.{KeyId:KeyId,State:KeyState,Created:CreationDate,Description:Description}' --output table

# Step 4: Encrypt data
echo "Step 4: Encrypting data"
echo "Hello from the KMS tutorial" > "$WORK_DIR/plaintext.txt"
aws kms encrypt --key-id "$KEY_ID" \
    --plaintext "fileb://$WORK_DIR/plaintext.txt" \
    --output text --query 'CiphertextBlob' > "$WORK_DIR/ciphertext.b64"
echo "  Plaintext: $(cat "$WORK_DIR/plaintext.txt")"
echo "  Ciphertext (base64, first 40 chars): $(head -c 40 "$WORK_DIR/ciphertext.b64")..."

# Step 5: Decrypt data
echo "Step 5: Decrypting data"
cat "$WORK_DIR/ciphertext.b64" | base64 --decode > "$WORK_DIR/ciphertext.bin"
aws kms decrypt --ciphertext-blob "fileb://$WORK_DIR/ciphertext.bin" \
    --output text --query 'Plaintext' | base64 --decode > "$WORK_DIR/decrypted.txt"
echo "  Decrypted: $(cat "$WORK_DIR/decrypted.txt")"

# Step 6: Generate a data key
echo "Step 6: Generating a data key"
aws kms generate-data-key --key-id "$KEY_ID" --key-spec AES_256 \
    --query '{KeyId:KeyId}' --output table
echo "  Data key generated (plaintext + encrypted copy returned)"

# Step 7: List keys
echo "Step 7: Listing KMS keys (first 5)"
aws kms list-aliases --query 'Aliases[?starts_with(AliasName, `alias/tutorial`)].{Alias:AliasName,KeyId:TargetKeyId}' --output table

echo ""
echo "Tutorial complete."
echo "Do you want to clean up all resources? (y/n): "
read -r CHOICE
if [[ "$CHOICE" =~ ^[Yy]$ ]]; then
    cleanup
else
    echo "Resources left running. The key will incur $1/month until deleted."
    echo "Manual cleanup:"
    echo "  aws kms schedule-key-deletion --key-id $KEY_ID --pending-window-in-days 7"
    echo "  aws kms delete-alias --alias-name $ALIAS_NAME"
fi
