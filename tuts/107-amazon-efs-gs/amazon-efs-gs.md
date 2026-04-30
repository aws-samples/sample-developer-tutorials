# Create a file system with Amazon EFS

This tutorial shows you how to create an encrypted Amazon EFS file system, create a mount target in your default VPC, configure a lifecycle policy, and clean up all resources.

## Prerequisites

- AWS CLI configured with credentials and a default region
- A default VPC with at least one subnet in the configured region
- Permissions for `elasticfilesystem:CreateFileSystem`, `elasticfilesystem:DescribeFileSystems`, `elasticfilesystem:CreateMountTarget`, `elasticfilesystem:DescribeMountTargets`, `elasticfilesystem:PutLifecycleConfiguration`, `elasticfilesystem:DescribeLifecycleConfiguration`, `elasticfilesystem:DeleteMountTarget`, `elasticfilesystem:DeleteFileSystem`, `ec2:DescribeVpcs`, `ec2:DescribeSubnets`

## Step 1: Create an encrypted file system

```bash
RANDOM_ID=$(openssl rand -hex 4)
FS_TOKEN="tut-efs-${RANDOM_ID}"

FS_ID=$(aws efs create-file-system --creation-token "$FS_TOKEN" \
    --performance-mode generalPurpose \
    --throughput-mode bursting \
    --encrypted \
    --tags Key=Name,Value="tutorial-efs-${RANDOM_ID}" \
    --query 'FileSystemId' --output text)
echo "File system ID: $FS_ID"
```

The creation token is an idempotency key — calling `create-file-system` again with the same token returns the existing file system instead of creating a duplicate.

## Step 2: Wait for the file system to be available

```bash
for i in $(seq 1 15); do
    STATE=$(aws efs describe-file-systems --file-system-id "$FS_ID" \
        --query 'FileSystems[0].LifeCycleState' --output text)
    echo "State: $STATE"
    [ "$STATE" = "available" ] && break
    sleep 5
done
```

## Step 3: Describe the file system

```bash
aws efs describe-file-systems --file-system-id "$FS_ID" \
    --query 'FileSystems[0].{Id:FileSystemId,State:LifeCycleState,Encrypted:Encrypted,Performance:PerformanceMode,Size:SizeInBytes.Value}' \
    --output table
```

## Step 4: Create a mount target

A mount target provides a network endpoint for mounting the file system. Create one in a subnet of your default VPC.

```bash
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" \
    --query 'Vpcs[0].VpcId' --output text)
SUBNET_ID=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" \
    --query 'Subnets[0].SubnetId' --output text)

MT_ID=$(aws efs create-mount-target --file-system-id "$FS_ID" \
    --subnet-id "$SUBNET_ID" \
    --query 'MountTargetId' --output text)
echo "Mount target: $MT_ID"
```

You need one mount target per Availability Zone. This tutorial creates one for demonstration.

## Step 5: Wait for the mount target

Mount target creation typically takes 60–90 seconds.

```bash
for i in $(seq 1 15); do
    MT_STATE=$(aws efs describe-mount-targets --mount-target-id "$MT_ID" \
        --query 'MountTargets[0].LifeCycleState' --output text)
    echo "State: $MT_STATE"
    [ "$MT_STATE" = "available" ] && break
    sleep 10
done
```

## Step 6: Describe mount targets

```bash
aws efs describe-mount-targets --file-system-id "$FS_ID" \
    --query 'MountTargets[].{Id:MountTargetId,Subnet:SubnetId,State:LifeCycleState,IP:IpAddress}' \
    --output table
```

## Step 7: Set a lifecycle policy

Move files not accessed for 30 days to the Infrequent Access (IA) storage class to reduce costs.

```bash
aws efs put-lifecycle-configuration --file-system-id "$FS_ID" \
    --lifecycle-policies '[{"TransitionToIA":"AFTER_30_DAYS"}]'

aws efs describe-lifecycle-configuration --file-system-id "$FS_ID" \
    --query 'LifecyclePolicies' --output table
```

## Cleanup

Delete mount targets first, then the file system. You must wait for mount targets to finish deleting before the file system can be removed.

```bash
aws efs delete-mount-target --mount-target-id "$MT_ID"

# Wait for mount target deletion
for i in $(seq 1 12); do
    MT_COUNT=$(aws efs describe-mount-targets --file-system-id "$FS_ID" \
        --query 'MountTargets | length(@)' --output text 2>/dev/null || echo "0")
    [ "$MT_COUNT" = "0" ] && break
    sleep 10
done

aws efs delete-file-system --file-system-id "$FS_ID"
```

EFS charges per GB stored ($0.30/GB-month for Standard, $0.025/GB-month for IA). An empty file system has no storage cost. The script automates all steps including cleanup:

```bash
bash amazon-efs-gs.sh
```

## Related resources

- [Getting started with Amazon EFS](https://docs.aws.amazon.com/efs/latest/ug/getting-started.html)
- [Creating file systems](https://docs.aws.amazon.com/efs/latest/ug/creating-using-create-fs.html)
- [Creating mount targets](https://docs.aws.amazon.com/efs/latest/ug/accessing-fs.html)
- [EFS lifecycle management](https://docs.aws.amazon.com/efs/latest/ug/lifecycle-management-efs.html)
