#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/sc.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null))}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
RANDOM_ID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1); PORTFOLIO="tut-portfolio-${RANDOM_ID}"
handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }; trap 'handle_error $LINENO' ERR
cleanup() { echo ""; echo "Cleaning up..."; [ -n "$PORT_ID" ] && aws servicecatalog delete-portfolio --id "$PORT_ID" 2>/dev/null && echo "  Deleted portfolio"; rm -rf "$WORK_DIR"; echo "Done."; }
echo "Step 1: Creating portfolio: $PORTFOLIO"
PORT_ID=$(aws servicecatalog create-portfolio --display-name "$PORTFOLIO" --provider-name "Tutorial" --query 'PortfolioDetail.Id' --output text)
echo "  Portfolio ID: $PORT_ID"
echo "Step 2: Describing portfolio"
aws servicecatalog describe-portfolio --id "$PORT_ID" --query 'PortfolioDetail.{Name:DisplayName,Id:Id,Provider:ProviderName,Created:CreatedTime}' --output table
echo "Step 3: Listing portfolios"
aws servicecatalog list-portfolios --query 'PortfolioDetails[?starts_with(DisplayName, `tut-`)].{Name:DisplayName,Id:Id}' --output table
echo ""; echo "Tutorial complete."
echo "Do you want to clean up? (y/n): "; read -r CHOICE; [[ "$CHOICE" =~ ^[Yy]$ ]] && cleanup
