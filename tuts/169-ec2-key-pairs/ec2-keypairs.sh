#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/kp.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null))}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
RANDOM_ID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1); KEY1="tut-key-${RANDOM_ID}-rsa"; KEY2="tut-key-${RANDOM_ID}-ed25519"
handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }; trap 'handle_error $LINENO' ERR
cleanup() { echo ""; echo "Cleaning up..."; aws ec2 delete-key-pair --key-name "$KEY1" 2>/dev/null && echo "  Deleted $KEY1"; aws ec2 delete-key-pair --key-name "$KEY2" 2>/dev/null && echo "  Deleted $KEY2"; rm -rf "$WORK_DIR"; echo "Done."; }
echo "Step 1: Creating RSA key pair"
aws ec2 create-key-pair --key-name "$KEY1" --key-type rsa --query 'KeyFingerprint' --output text > /dev/null
echo "  Created $KEY1 (RSA)"
echo "Step 2: Creating ED25519 key pair"
aws ec2 create-key-pair --key-name "$KEY2" --key-type ed25519 --query 'KeyFingerprint' --output text > /dev/null
echo "  Created $KEY2 (ED25519)"
echo "Step 3: Describing key pairs"
aws ec2 describe-key-pairs --key-names "$KEY1" "$KEY2" --query 'KeyPairs[].{Name:KeyName,Type:KeyType,Fingerprint:KeyFingerprint}' --output table
echo "Step 4: Listing all tutorial key pairs"
aws ec2 describe-key-pairs --filters "Name=key-name,Values=tut-key-*" --query 'KeyPairs[].{Name:KeyName,Type:KeyType}' --output table
echo ""; echo "Tutorial complete."
echo "Do you want to clean up? (y/n): "; read -r CHOICE; [[ "$CHOICE" =~ ^[Yy]$ ]] && cleanup
