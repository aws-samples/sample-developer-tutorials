#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/tut.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null))}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
echo "Step 1: Finding stopped instances (still incurring EBS charges)"
aws ec2 describe-instances --filters "Name=instance-state-name,Values=stopped" --query 'Reservations[].Instances[].{Id:InstanceId,Type:InstanceType,Stopped:StateTransitionReason}' --output table 2>/dev/null || echo "  No stopped instances"
echo "Step 2: Finding unattached EBS volumes"
aws ec2 describe-volumes --filters "Name=status,Values=available" --query 'Volumes[].{Id:VolumeId,Size:Size,Type:VolumeType,Created:CreateTime}' --output table 2>/dev/null || echo "  No unattached volumes"
echo "Step 3: Finding unattached Elastic IPs"
aws ec2 describe-addresses --query 'Addresses[?AssociationId==null].{IP:PublicIp,AllocId:AllocationId}' --output table 2>/dev/null || echo "  No unattached EIPs"
echo "Step 4: Finding old snapshots (>90 days)"
CUTOFF=$(date -u -d '90 days ago' +%Y-%m-%dT%H:%M:%SZ)
aws ec2 describe-snapshots --owner-ids self --query "Snapshots[?StartTime<'$CUTOFF'][:5].{Id:SnapshotId,Size:VolumeSize,Created:StartTime}" --output table 2>/dev/null || echo "  No old snapshots"
echo ""; echo "Tutorial complete. Read-only — identifies cost optimization opportunities."; rm -rf "$WORK_DIR"
