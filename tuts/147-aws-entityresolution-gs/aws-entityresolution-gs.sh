#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/er.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null))}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
RANDOM_ID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1); SCHEMA_NAME="tut-schema-${RANDOM_ID}"
handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }; trap 'handle_error $LINENO' ERR
cleanup() { echo ""; echo "Cleaning up..."; aws entityresolution delete-schema-mapping --schema-name "$SCHEMA_NAME" 2>/dev/null && echo "  Deleted schema"; rm -rf "$WORK_DIR"; echo "Done."; }
echo "Step 1: Creating schema mapping: $SCHEMA_NAME"
aws entityresolution create-schema-mapping --schema-name "$SCHEMA_NAME" --mapped-input-fields '[{"fieldName":"id","type":"UNIQUE_ID"},{"fieldName":"name","type":"NAME"},{"fieldName":"email","type":"EMAIL_ADDRESS"}]' --query 'schemaArn' --output text
echo "Step 2: Describing schema"
aws entityresolution get-schema-mapping --schema-name "$SCHEMA_NAME" --query '{Name:schemaName,Fields:mappedInputFields|length(@)}' --output table
echo "Step 3: Listing schemas"
aws entityresolution list-schema-mappings --query 'schemaList[?starts_with(schemaName, `tut-`)].{Name:schemaName}' --output table
echo ""; echo "Tutorial complete."
echo "Do you want to clean up? (y/n): "; read -r CHOICE; [[ "$CHOICE" =~ ^[Yy]$ ]] && cleanup
