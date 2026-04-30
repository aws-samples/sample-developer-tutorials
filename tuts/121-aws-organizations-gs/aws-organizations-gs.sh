#!/bin/bash
WORK_DIR=$(mktemp -d)
exec > >(tee -a "$WORK_DIR/orgs-$(date +%Y%m%d-%H%M%S).log") 2>&1
REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null))}
[ -z "$REGION" ] && echo "ERROR: No region" && exit 1
export AWS_DEFAULT_REGION="$REGION"
echo "Region: $REGION"
echo "Step 1: Describing organization"
aws organizations describe-organization --query 'Organization.{Id:Id,MasterAccount:MasterAccountId,FeatureSet:FeatureSet}' --output table 2>/dev/null || echo "  No organization found (this account may not be part of an organization)"
echo "Step 2: Listing accounts"
aws organizations list-accounts --query 'Accounts[:5].{Id:Id,Name:Name,Status:Status,Email:Email}' --output table 2>/dev/null || echo "  Cannot list accounts (requires management account access)"
echo "Step 3: Listing organizational units"
ROOT_ID=$(aws organizations list-roots --query 'Roots[0].Id' --output text 2>/dev/null)
[ -n "$ROOT_ID" ] && [ "$ROOT_ID" != "None" ] && aws organizations list-organizational-units-for-parent --parent-id "$ROOT_ID" --query 'OrganizationalUnits[].{Id:Id,Name:Name}' --output table 2>/dev/null || echo "  No OUs found"
echo "Step 4: Listing policies"
aws organizations list-policies --filter SERVICE_CONTROL_POLICY --query 'Policies[].{Id:Id,Name:Name,Type:Type}' --output table 2>/dev/null || echo "  Cannot list policies"
echo ""
echo "Tutorial complete. No resources were created — this tutorial is read-only."
rm -rf "$WORK_DIR"
