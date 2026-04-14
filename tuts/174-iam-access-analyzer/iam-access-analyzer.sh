#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/aa.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-$(aws configure get region 2>/dev/null)}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
RANDOM_ID=$(openssl rand -hex 4); ANALYZER="tut-analyzer-${RANDOM_ID}"
handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }; trap 'handle_error $LINENO' ERR
cleanup() { echo ""; echo "Cleaning up..."; [ -n "$ANALYZER_ARN" ] && aws accessanalyzer delete-analyzer --analyzer-name "$ANALYZER" 2>/dev/null && echo "  Deleted analyzer"; rm -rf "$WORK_DIR"; echo "Done."; }
echo "Step 1: Creating analyzer: $ANALYZER"
ANALYZER_ARN=$(aws accessanalyzer create-analyzer --analyzer-name "$ANALYZER" --type ACCOUNT --query 'arn' --output text)
echo "  ARN: $ANALYZER_ARN"
echo "Step 2: Listing findings"
aws accessanalyzer list-findings --analyzer-arn "$ANALYZER_ARN" --query 'findings[:5].{Resource:resource,Type:resourceType,Status:status}' --output table 2>/dev/null || echo "  No findings yet (analysis takes a few minutes)"
echo "Step 3: Getting analyzer details"
aws accessanalyzer get-analyzer --analyzer-name "$ANALYZER" --query 'analyzer.{Name:name,Type:type,Status:status}' --output table
echo "Step 4: Listing analyzers"
aws accessanalyzer list-analyzers --query 'analyzers[?starts_with(name, `tut-`)].{Name:name,Status:status}' --output table
echo ""; echo "Tutorial complete."
echo "Do you want to clean up? (y/n): "; read -r CHOICE; [[ "$CHOICE" =~ ^[Yy]$ ]] && cleanup
