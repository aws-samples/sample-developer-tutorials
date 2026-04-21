#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/tut.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null))}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
echo "Step 1: Listing service-linked roles"; aws iam list-roles --query 'Roles[?starts_with(Path, `/aws-service-role/`)][:10].{Name:RoleName,Service:Path}' --output table
echo "Step 2: Counting roles by type"; echo "  Service-linked: $(aws iam list-roles --query 'Roles[?starts_with(Path, `/aws-service-role/`)] | length(@)' --output text)"
echo "  Custom: $(aws iam list-roles --query 'Roles[?Path==`/`] | length(@)' --output text)"
echo ""; echo "Tutorial complete. Read-only."; rm -rf "$WORK_DIR"
