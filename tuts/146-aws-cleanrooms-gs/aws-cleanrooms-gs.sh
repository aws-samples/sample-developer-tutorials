#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/cr.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null))}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; ACCOUNT=$(aws sts get-caller-identity --query 'Account' --output text); echo "Region: $REGION"
RANDOM_ID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1); COLLAB_NAME="tut-collab-${RANDOM_ID}"
handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }; trap 'handle_error $LINENO' ERR
cleanup() { echo ""; echo "Cleaning up..."; [ -n "$MEMBERSHIP_ID" ] && aws cleanrooms delete-membership --membership-identifier "$MEMBERSHIP_ID" 2>/dev/null && echo "  Deleted membership"; [ -n "$COLLAB_ID" ] && aws cleanrooms delete-collaboration --collaboration-identifier "$COLLAB_ID" 2>/dev/null && echo "  Deleted collaboration"; rm -rf "$WORK_DIR"; echo "Done."; }
echo "Step 1: Creating collaboration: $COLLAB_NAME"
RESULT=$(aws cleanrooms create-collaboration --name "$COLLAB_NAME" --description "Tutorial collaboration" --creator-member-abilities '["CAN_QUERY","CAN_RECEIVE_RESULTS"]' --creator-display-name "TutorialCreator" --query-log-status DISABLED --members '[]')
COLLAB_ID=$(echo "$RESULT" | python3 -c "import sys,json;print(json.load(sys.stdin)['collaboration']['id'])")
echo "  Collaboration ID: $COLLAB_ID"
echo "Step 2: Creating membership"
MEMBERSHIP_ID=$(aws cleanrooms create-membership --collaboration-identifier "$COLLAB_ID" --query-log-status DISABLED --query 'membership.id' --output text)
echo "  Membership ID: $MEMBERSHIP_ID"
echo "Step 3: Describing collaboration"
aws cleanrooms get-collaboration --collaboration-identifier "$COLLAB_ID" --query 'collaboration.{Name:name,Id:id,Status:memberStatus}' --output table
echo "Step 4: Listing collaborations"
aws cleanrooms list-collaborations --query 'collaborationList[?starts_with(name, `tut-`)].{Name:name,Id:id}' --output table
echo ""; echo "Tutorial complete."
echo "Do you want to clean up? (y/n): "; read -r CHOICE; [[ "$CHOICE" =~ ^[Yy]$ ]] && cleanup
