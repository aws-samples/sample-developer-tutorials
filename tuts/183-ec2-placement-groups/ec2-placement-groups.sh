#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/pg.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-$(aws configure get region 2>/dev/null)}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
RANDOM_ID=$(openssl rand -hex 4); PG1="tut-cluster-${RANDOM_ID}"; PG2="tut-spread-${RANDOM_ID}"
handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }; trap 'handle_error $LINENO' ERR
cleanup() { echo ""; echo "Cleaning up..."; aws ec2 delete-placement-group --group-name "$PG1" 2>/dev/null && echo "  Deleted $PG1"; aws ec2 delete-placement-group --group-name "$PG2" 2>/dev/null && echo "  Deleted $PG2"; rm -rf "$WORK_DIR"; echo "Done."; }
echo "Step 1: Creating cluster placement group"
aws ec2 create-placement-group --group-name "$PG1" --strategy cluster --query 'PlacementGroup.{Name:GroupName,Strategy:Strategy,State:State}' --output table
echo "Step 2: Creating spread placement group"
aws ec2 create-placement-group --group-name "$PG2" --strategy spread --query 'PlacementGroup.{Name:GroupName,Strategy:Strategy,State:State}' --output table
echo "Step 3: Describing placement groups"
aws ec2 describe-placement-groups --group-names "$PG1" "$PG2" --query 'PlacementGroups[].{Name:GroupName,Strategy:Strategy,State:State}' --output table
echo ""; echo "Tutorial complete."
echo "Do you want to clean up? (y/n): "; read -r CHOICE; [[ "$CHOICE" =~ ^[Yy]$ ]] && cleanup
