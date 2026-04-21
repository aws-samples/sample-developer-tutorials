#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/ec2-snap.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null))}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
RANDOM_ID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }; trap 'handle_error $LINENO' ERR
cleanup() { echo ""; echo "Cleaning up..."; [ -n "$SNAP_ID" ] && aws ec2 delete-snapshot --snapshot-id "$SNAP_ID" 2>/dev/null && echo "  Deleted snapshot"; [ -n "$VOL_ID" ] && aws ec2 delete-volume --volume-id "$VOL_ID" 2>/dev/null && echo "  Deleted volume"; rm -rf "$WORK_DIR"; echo "Done."; }
AZ=$(aws ec2 describe-availability-zones --query 'AvailabilityZones[0].ZoneName' --output text)
echo "Step 1: Creating a volume"
VOL_ID=$(aws ec2 create-volume --size 1 --volume-type gp3 --availability-zone "$AZ" --tag-specifications "ResourceType=volume,Tags=[{Key=Name,Value=tut-vol-${RANDOM_ID}}]" --query 'VolumeId' --output text)
echo "  Volume: $VOL_ID"
aws ec2 wait volume-available --volume-ids "$VOL_ID"
echo "Step 2: Creating a snapshot"
SNAP_ID=$(aws ec2 create-snapshot --volume-id "$VOL_ID" --description "Tutorial snapshot ${RANDOM_ID}" --tag-specifications "ResourceType=snapshot,Tags=[{Key=Name,Value=tut-snap-${RANDOM_ID}}]" --query 'SnapshotId' --output text)
echo "  Snapshot: $SNAP_ID"
echo "  Waiting for snapshot..."
aws ec2 wait snapshot-completed --snapshot-ids "$SNAP_ID"
echo "Step 3: Describing snapshot"
aws ec2 describe-snapshots --snapshot-ids "$SNAP_ID" --query 'Snapshots[0].{Id:SnapshotId,State:State,Size:VolumeSize,Progress:Progress}' --output table
echo "Step 4: Copying snapshot (same region)"
COPY_ID=$(aws ec2 copy-snapshot --source-region "$REGION" --source-snapshot-id "$SNAP_ID" --description "Copy of tutorial snapshot" --query 'SnapshotId' --output text)
echo "  Copy: $COPY_ID"
echo "Step 5: Listing snapshots"
aws ec2 describe-snapshots --owner-ids self --filters "Name=tag:Name,Values=tut-snap-*" --query 'Snapshots[].{Id:SnapshotId,State:State,Size:VolumeSize}' --output table
echo ""; echo "Tutorial complete."
echo "Do you want to clean up? (y/n): "; read -r CHOICE
if [[ "$CHOICE" =~ ^[Yy]$ ]]; then
    aws ec2 delete-snapshot --snapshot-id "$COPY_ID" 2>/dev/null && echo "  Deleted copy"
    cleanup
fi
