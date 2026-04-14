#!/bin/bash
WORK_DIR=$(mktemp -d)
exec > >(tee -a "$WORK_DIR/detective-$(date +%Y%m%d-%H%M%S).log") 2>&1
REGION=${AWS_DEFAULT_REGION:-$(aws configure get region 2>/dev/null)}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
PREEXISTING=false
handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }; trap 'handle_error $LINENO' ERR
cleanup() { echo ""; echo "Cleaning up..."; [ "$PREEXISTING" != true ] && [ -n "$GRAPH_ARN" ] && aws detective delete-graph --graph-arn "$GRAPH_ARN" 2>/dev/null && echo "  Deleted graph" || echo "  Pre-existing — not deleting"; rm -rf "$WORK_DIR"; echo "Done."; }
echo "Step 1: Enabling Detective"
GRAPHS=$(aws detective list-graphs --query 'GraphList[0].Arn' --output text 2>/dev/null)
if [ -n "$GRAPHS" ] && [ "$GRAPHS" != "None" ]; then echo "  Already enabled"; GRAPH_ARN="$GRAPHS"; PREEXISTING=true; else GRAPH_ARN=$(aws detective create-graph --query 'GraphArn' --output text); echo "  Graph: $GRAPH_ARN"; fi
echo "Step 2: Listing graphs"
aws detective list-graphs --query 'GraphList[].{Arn:Arn,Created:CreatedTime}' --output table
echo "Step 3: Listing members"
aws detective list-members --graph-arn "$GRAPH_ARN" --query 'MemberDetails[:5].{Account:AccountId,Status:Status}' --output table 2>/dev/null || echo "  No members"
echo ""; echo "Tutorial complete."
[ "$PREEXISTING" = true ] && echo "Detective was already enabled." || { echo "Do you want to clean up? (y/n): "; read -r CHOICE; [[ "$CHOICE" =~ ^[Yy]$ ]] && cleanup; }
