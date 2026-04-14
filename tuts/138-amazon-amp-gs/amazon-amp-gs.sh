#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/amp.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-$(aws configure get region 2>/dev/null)}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
RANDOM_ID=$(openssl rand -hex 4); WS_ALIAS="tut-ws-${RANDOM_ID}"
handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }; trap 'handle_error $LINENO' ERR
cleanup() { echo ""; echo "Cleaning up..."; [ -n "$WS_ID" ] && aws amp delete-workspace --workspace-id "$WS_ID" 2>/dev/null && echo "  Deleted workspace"; rm -rf "$WORK_DIR"; echo "Done."; }
echo "Step 1: Creating workspace: $WS_ALIAS"
WS_ID=$(aws amp create-workspace --alias "$WS_ALIAS" --query 'workspaceId' --output text)
echo "  Workspace ID: $WS_ID"
echo "Step 2: Waiting for workspace..."
for i in $(seq 1 15); do STATUS=$(aws amp describe-workspace --workspace-id "$WS_ID" --query 'workspace.status.statusCode' --output text); echo "  $STATUS"; [ "$STATUS" = "ACTIVE" ] && break; sleep 3; done
echo "Step 3: Workspace details"
aws amp describe-workspace --workspace-id "$WS_ID" --query 'workspace.{Id:workspaceId,Alias:alias,Status:status.statusCode,Endpoint:prometheusEndpoint}' --output table
echo "Step 4: Listing workspaces"
aws amp list-workspaces --alias "$WS_ALIAS" --query 'workspaces[].{Id:workspaceId,Alias:alias,Status:status.statusCode}' --output table
echo ""; echo "Tutorial complete."
echo "Do you want to clean up? (y/n): "; read -r CHOICE; [[ "$CHOICE" =~ ^[Yy]$ ]] && cleanup
