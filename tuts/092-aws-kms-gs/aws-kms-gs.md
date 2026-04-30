# Create a key and encrypt data with AWS KMS

This tutorial shows you how to create a customer managed KMS key, assign it an alias, encrypt and decrypt data, and generate a data key for client-side encryption.

## Prerequisites

- AWS CLI configured with credentials and a default region
- Permissions for `kms:CreateKey`, `kms:CreateAlias`, `kms:DescribeKey`, `kms:Encrypt`, `kms:Decrypt`, `kms:GenerateDataKey`, `kms:ListAliases`, `kms:ScheduleKeyDeletion`, `kms:DeleteAlias`

## Step 1: Create a customer managed key

```bash
KEY_ID=$(aws kms create-key --description "Tutorial key" \
    --query 'KeyMetadata.KeyId' --output text)
echo "Key ID: $KEY_ID"
```

KMS returns the key metadata including the key ID, ARN, and state. The key is enabled immediately.

## Step 2: Create an alias

An alias is a friendly name for your key. Alias names must start with `alias/`.

```bash
aws kms create-alias --alias-name "alias/tutorial-key" --target-key-id "$KEY_ID"
```

## Step 3: Describe the key

```bash
aws kms describe-key --key-id "$KEY_ID" \
    --query 'KeyMetadata.{KeyId:KeyId,State:KeyState,Created:CreationDate,Description:Description}' \
    --output table
```

## Step 4: Encrypt data

Write plaintext to a file and encrypt it using `fileb://` to pass raw bytes:

```bash
echo "Hello from the KMS tutorial" > plaintext.txt
aws kms encrypt --key-id "$KEY_ID" \
    --plaintext "fileb://plaintext.txt" \
    --output text --query 'CiphertextBlob' > ciphertext.b64
```

The `fileb://` prefix tells the CLI to read the file as raw binary. The output is base64-encoded ciphertext.

## Step 5: Decrypt data

Decode the base64 ciphertext to binary, then decrypt:

```bash
base64 --decode ciphertext.b64 > ciphertext.bin
aws kms decrypt --ciphertext-blob "fileb://ciphertext.bin" \
    --output text --query 'Plaintext' | base64 --decode
```

KMS identifies the correct key from metadata embedded in the ciphertext.

## Step 6: Generate a data key

A data key lets you encrypt data locally. KMS returns both a plaintext key (for immediate use) and an encrypted copy (to store alongside your data).

```bash
aws kms generate-data-key --key-id "$KEY_ID" --key-spec AES_256 \
    --query '{KeyId:KeyId}' --output table
```

## Step 7: List keys

```bash
aws kms list-aliases \
    --query 'Aliases[?starts_with(AliasName, `alias/tutorial`)].{Alias:AliasName,KeyId:TargetKeyId}' \
    --output table
```

## Cleanup

Schedule the key for deletion (minimum 7-day waiting period) and delete the alias:

```bash
aws kms schedule-key-deletion --key-id "$KEY_ID" --pending-window-in-days 7
aws kms delete-alias --alias-name "alias/tutorial-key"
```

The key incurs $1/month until the scheduled deletion completes. The script automates all steps including cleanup:

```bash
bash aws-kms-gs.sh
```
