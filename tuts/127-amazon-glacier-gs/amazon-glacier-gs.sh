#!/bin/bash
WORK_DIR=$(mktemp -d)
exec > >(tee -a "$WORK_DIR/glacier-$(date +%Y%m%d-%H%M%S).log") 2>&1
REGION=${AWS_DEFAULT_REGION:-$(aws configure get region 2>/dev/null)}
[ -z "$REGION" ] && echo "ERROR: No region" && exit 1
export AWS_DEFAULT_REGION="$REGION"
echo "Region: $REGION"
RANDOM_ID=$(openssl rand -hex 4)
VAULT_NAME="tut-vault-${RANDOM_ID}"
handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }
trap 'handle_error $LINENO' ERR
cleanup() { echo ""; echo "Cleaning up..."; aws glacier delete-vault --vault-name "$VAULT_NAME" 2>/dev/null && echo "  Deleted vault $VAULT_NAME"; rm -rf "$WORK_DIR"; echo "Done."; }
echo "Step 1: Creating vault: $VAULT_NAME"
aws glacier create-vault --vault-name "$VAULT_NAME" --account-id -
echo "  Vault created"
echo "Step 2: Describing vault"
aws glacier describe-vault --vault-name "$VAULT_NAME" --account-id - --query '{Name:VaultName,ARN:VaultARN,Created:CreationDate}' --output table
echo "Step 3: Uploading an archive"
echo "Hello from Glacier tutorial" > "$WORK_DIR/archive.txt"
ARCHIVE_ID=$(aws glacier upload-archive --vault-name "$VAULT_NAME" --account-id - --body "$WORK_DIR/archive.txt" --query 'archiveId' --output text)
echo "  Archive ID: ${ARCHIVE_ID:0:40}..."
echo "Step 4: Listing vaults"
aws glacier list-vaults --account-id - --query 'VaultList[?starts_with(VaultName, `tut-`)].{Name:VaultName,Archives:NumberOfArchives,Size:SizeInBytes}' --output table
echo "Step 5: Initiating inventory retrieval"
JOB_ID=$(aws glacier initiate-job --vault-name "$VAULT_NAME" --account-id - --job-parameters '{"Type":"inventory-retrieval"}' --query 'jobId' --output text)
echo "  Job ID: ${JOB_ID:0:40}..."
echo "  (Inventory retrieval takes 3-5 hours — not waiting)"
echo ""
echo "Tutorial complete."
echo "Note: The vault contains an archive and cannot be deleted until the archive is removed."
echo "Archive deletion takes 24 hours to process. The vault will need manual cleanup later."
echo "Do you want to attempt cleanup? (y/n): "
read -r CHOICE
[[ "$CHOICE" =~ ^[Yy]$ ]] && { echo "Deleting archive (takes 24h to process)..."; aws glacier delete-archive --vault-name "$VAULT_NAME" --account-id - --archive-id "$ARCHIVE_ID" 2>/dev/null; echo "  Archive deletion initiated. Delete vault after 24h:"; echo "  aws glacier delete-vault --vault-name $VAULT_NAME --account-id -"; rm -rf "$WORK_DIR"; } || echo "Manual: aws glacier delete-archive then delete-vault"
