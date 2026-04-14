#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/tut.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-$(aws configure get region 2>/dev/null)}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
echo "Step 1: Listing volumes"; aws ec2 describe-volumes --query 'Volumes[:10].{Id:VolumeId,Type:VolumeType,Size:Size,State:State,AZ:AvailabilityZone}' --output table
echo "Step 2: Volume summary"; echo "  Total: $(aws ec2 describe-volumes --query 'Volumes | length(@)' --output text) volumes"
echo ""; echo "Tutorial complete. Read-only."; rm -rf "$WORK_DIR"
