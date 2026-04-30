#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/rds-snap.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null))}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
echo "Step 1: Listing RDS instances"
aws rds describe-db-instances --query 'DBInstances[:5].{Id:DBInstanceIdentifier,Engine:Engine,Status:DBInstanceStatus,Class:DBInstanceClass}' --output table 2>/dev/null || echo "  No RDS instances"
echo "Step 2: Listing automated snapshots"
aws rds describe-db-snapshots --snapshot-type automated --query 'DBSnapshots[:5].{Id:DBSnapshotIdentifier,Instance:DBInstanceIdentifier,Status:Status,Engine:Engine}' --output table 2>/dev/null || echo "  No automated snapshots"
echo "Step 3: Listing manual snapshots"
aws rds describe-db-snapshots --snapshot-type manual --query 'DBSnapshots[:5].{Id:DBSnapshotIdentifier,Status:Status,Size:AllocatedStorage}' --output table 2>/dev/null || echo "  No manual snapshots"
echo "Step 4: Listing cluster snapshots"
aws rds describe-db-cluster-snapshots --query 'DBClusterSnapshots[:3].{Id:DBClusterSnapshotIdentifier,Cluster:DBClusterIdentifier,Status:Status}' --output table 2>/dev/null || echo "  No cluster snapshots"
echo ""; echo "Tutorial complete. No resources created — read-only."
rm -rf "$WORK_DIR"
