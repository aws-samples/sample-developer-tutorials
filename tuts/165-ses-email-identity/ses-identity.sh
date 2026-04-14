#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/ses.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-$(aws configure get region 2>/dev/null)}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
RANDOM_ID=$(openssl rand -hex 4); DOMAIN="tutorial-${RANDOM_ID}.example.com"
handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }; trap 'handle_error $LINENO' ERR
cleanup() { echo ""; echo "Cleaning up..."; aws sesv2 delete-email-identity --email-identity "$DOMAIN" 2>/dev/null && echo "  Deleted identity"; rm -rf "$WORK_DIR"; echo "Done."; }
echo "Step 1: Creating email identity (domain): $DOMAIN"
aws sesv2 create-email-identity --email-identity "$DOMAIN" --query 'IdentityType' --output text
echo "Step 2: Getting DKIM tokens"
aws sesv2 get-email-identity --email-identity "$DOMAIN" --query 'DkimAttributes.{Status:SigningAttributesOrigin,Tokens:Tokens}' --output table 2>/dev/null || echo "  DKIM tokens not available"
echo "Step 3: Getting sending quota"
aws sesv2 get-account --query 'SendQuota.{Max24Hr:Max24HourSend,MaxPerSec:MaxSendRate,SentLast24Hr:SentLast24Hours}' --output table
echo "Step 4: Listing identities"
aws sesv2 list-email-identities --query 'EmailIdentities[?starts_with(IdentityName, `tutorial-`)].{Name:IdentityName,Type:IdentityType}' --output table
echo ""; echo "Tutorial complete."
echo "Note: The domain identity will remain in PENDING status (example.com cannot be verified)."
echo "Do you want to clean up? (y/n): "; read -r CHOICE; [[ "$CHOICE" =~ ^[Yy]$ ]] && cleanup
