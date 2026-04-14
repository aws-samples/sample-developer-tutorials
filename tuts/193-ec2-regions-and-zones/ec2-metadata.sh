#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/tut.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-$(aws configure get region 2>/dev/null)}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
echo "Step 1: Describing your running instances"
aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" --query 'Reservations[].Instances[:3].{Id:InstanceId,Type:InstanceType,State:State.Name,AZ:Placement.AvailabilityZone}' --output table 2>/dev/null || echo "  No running instances"
echo "Step 2: Describing instance status"
aws ec2 describe-instance-status --query 'InstanceStatuses[:3].{Id:InstanceId,System:SystemStatus.Status,Instance:InstanceStatus.Status}' --output table 2>/dev/null || echo "  No instance status"
echo "Step 3: Listing regions"
aws ec2 describe-regions --query 'Regions[:10].{Name:RegionName,Endpoint:Endpoint}' --output table
echo "Step 4: Listing availability zones"
aws ec2 describe-availability-zones --query 'AvailabilityZones[:5].{Zone:ZoneName,State:State,Type:ZoneType}' --output table
echo ""; echo "Tutorial complete. No resources created — read-only."
rm -rf "$WORK_DIR"
