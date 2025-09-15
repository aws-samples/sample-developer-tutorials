# Working with Amazon EBS encryption, snapshots, and volume initialization

This tutorial guides you through essential Amazon EBS operations using the AWS Command Line Interface (AWS CLI). You'll learn how to enable EBS encryption by default, create snapshots, and work with volume initialization.

## Topics

- [Prerequisites](#prerequisites)
- [Enable Amazon EBS encryption by default](#enable-amazon-ebs-encryption-by-default)
- [Create an EBS snapshot](#create-an-ebs-snapshot)
- [Create and initialize a volume from a snapshot](#create-and-initialize-a-volume-from-a-snapshot)
- [Clean up resources](#clean-up-resources)
- [Going to production](#going-to-production)
- [Next steps](#next-steps)

## Prerequisites

Before you begin this tutorial, make sure you have the following:

1. The AWS CLI. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
2. Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
3. Basic familiarity with Amazon EC2 and EBS concepts.
4. Sufficient permissions to create and manage EC2 and EBS resources in your AWS account.

**Cost**: The resources created in this tutorial will cost approximately $0.0003 per hour if left running. This includes a 1 GiB gp3 volume ($0.00011/hour), a snapshot of that volume ($0.00007/hour), and another 1 GiB volume created from the snapshot ($0.00011/hour). The tutorial includes cleanup instructions to delete all resources, so you should incur minimal charges if you follow the cleanup steps.

Before you start, set the `AWS_REGION` environment variable to the same Region that you configured the AWS CLI to use, if it's not already set. This environment variable is used in example commands to specify an availability zone for EBS resources.

```
$ [ -z "${AWS_REGION}" ] && export AWS_REGION=$(aws configure get region)
```

Let's get started with managing Amazon EBS resources using the CLI.

## Enable Amazon EBS encryption by default

Amazon EBS encryption helps protect your data by encrypting your volumes and snapshots. In this section, you'll check the current encryption setting and enable encryption by default for your AWS account.

**Check the current encryption setting**

First, let's check if encryption by default is already enabled in your account:

```
$ aws ec2 get-ebs-encryption-by-default
```

The following output shows that encryption by default is currently disabled.
```
{
    "EbsEncryptionByDefault": false
}
```
**Enable encryption by default**

Now, let's enable encryption by default for all new EBS volumes and snapshot copies:

```
$ aws ec2 enable-ebs-encryption-by-default
```

The following output confirms that encryption by default is now enabled.
```
{
    "EbsEncryptionByDefault": true
}
```

**Verify the encryption setting**

Let's verify that the setting was successfully changed:

```
$ aws ec2 get-ebs-encryption-by-default
```

The following output confirms that encryption by default is now enabled for your account in this Region.

```
{
    "EbsEncryptionByDefault": true
}
```
**Check the default KMS key**

When you enable encryption by default, Amazon EBS uses the AWS managed key with the alias `aws/ebs` by default. Let's check which key is currently set as the default:

```
$ aws ec2 get-ebs-default-kms-key-id
```
The output is as follows:
```
{
    "KmsKeyId": "alias/aws/ebs"
}
```

The output shows that the AWS managed key for EBS is being used. You can use your own customer managed key instead if you prefer.

## Create an EBS snapshot

Snapshots are point-in-time backups of your EBS volumes. In this section, you'll create a volume and then take a snapshot of it.

**Create a test volume**

First, let's get an availability zone in your current Region:

```
$ AVAILABILITY_ZONE=$(aws ec2 describe-availability-zones --query 'AvailabilityZones[0].ZoneName' --output text)
$ echo $AVAILABILITY_ZONE
```
An example response is as follows:
```
us-east-1a
```

Now, let's create a small test volume:

```
$ VOLUME_ID=$(aws ec2 create-volume --availability-zone $AVAILABILITY_ZONE --size 1 --volume-type gp3 --query 'VolumeId' --output text)
$ echo $VOLUME_ID
```

An example response is as follows:
```
vol-abcd1234
```
The command creates a 1 GiB gp3 volume in the specified availability zone. Since we enabled encryption by default earlier, this volume will be encrypted automatically.

**Wait for the volume to become available**

Before we can create a snapshot, we need to wait for the volume to become available:

```
$ aws ec2 wait volume-available --volume-ids $VOLUME_ID
```

This command will wait until the volume is in the "available" state before proceeding.

**Create a snapshot of the volume**

Now, let's create a snapshot of our volume:

```
$ SNAPSHOT_ID=$(aws ec2 create-snapshot --volume-id $VOLUME_ID --description "Snapshot for EBS tutorial" --query 'SnapshotId' --output text)
$ echo $SNAPSHOT_ID
```
An example response is as follows:
```
snap-abcd1234
```

The command creates a snapshot of the specified volume with a description.

**Check the snapshot status**

Creating a snapshot is an asynchronous operation. Let's check the status of our snapshot:

```
$ aws ec2 describe-snapshots --snapshot-ids $SNAPSHOT_ID
```

The following example output shows that the snapshot is in the "pending" state and is encrypted because it was created from an encrypted volume.
```
{
    "Snapshots": [
        {
            "Description": "Snapshot for EBS tutorial",
            "Encrypted": true,
            "VolumeId": "vol-abcd1234",
            "State": "pending",
            "VolumeSize": 1,
            "StartTime": "2025-01-13T12:00:00.000Z",
            "Progress": "0%",
            "OwnerId": "123456789012",
            "SnapshotId": "snap-abcd1234"
        }
    ]
}
```

**Wait for the snapshot to complete**

Let's wait for the snapshot to complete before proceeding:

```
$ aws ec2 wait snapshot-completed --snapshot-ids $SNAPSHOT_ID
```

This command will wait until the snapshot is in the "completed" state before proceeding.

## Create and initialize a volume from a snapshot

When you create a volume from a snapshot, the data must be loaded from Amazon S3 before you can access it. This process is called volume initialization. In this section, you'll create a new volume from the snapshot and learn about initialization options.

**Create a new volume from the snapshot**

Let's create a new volume from our snapshot:

```
$ NEW_VOLUME_ID=$(aws ec2 create-volume --snapshot-id $SNAPSHOT_ID --availability-zone $AVAILABILITY_ZONE --volume-type gp3 --query 'VolumeId' --output text)
$ echo $NEW_VOLUME_ID
```
An example response is as follows:
```
vol-abcd5678
```

The command creates a new volume from the specified snapshot in the same availability zone as our original volume.

**Wait for the new volume to become available**

Let's wait for the new volume to become available:

```
$ aws ec2 wait volume-available --volume-ids $NEW_VOLUME_ID
```

This command will wait until the volume is in the "available" state before proceeding.

**Understanding volume initialization**

Although the volume is now available, it might not deliver its full performance immediately. When you create a volume from a snapshot, the data blocks are loaded from Amazon S3 only when they are accessed for the first time. This can cause increased latency during initial I/O operations.

To initialize the volume, you would need to read all the blocks on the volume. This can be done by attaching the volume to an EC2 instance and using tools like `dd` or `fio` to read all blocks.

### Step 1: Launch an EC2 instance in the same availability zone

The key requirement is ensuring the instance is created in the same availability zone as the volume:

```
# 1. Get the availability zone of your volume
VOLUME_AZ=$(aws ec2 describe-volumes --volume-ids $NEW_VOLUME_ID --query "Volumes[0].AvailabilityZone" --output text)
echo "Volume is in availability zone: $VOLUME_AZ"

# 2. Get the default VPC
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=is-default,Values=true" --query "Vpcs[0].VpcId" --output text)

# 3. Get a subnet in the same AZ
SUBNET_ID=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=availability-zone,Values=$VOLUME_AZ" --query "Subnets[0].SubnetId" --output text)

# 4. Check if subnet was found
if [ "$SUBNET_ID" = "None" ] || [ -z "$SUBNET_ID" ]; then
    echo "Error: No subnet found in availability zone $VOLUME_AZ"
else
    echo "Using subnet: $SUBNET_ID in AZ: $VOLUME_AZ"
fi

# 5. Get the latest Amazon Linux 2023 AMI
AMI_ID=$(aws ec2 describe-images --owners amazon --filters "Name=name,Values=al2023-ami-*" "Name=architecture,Values=x86_64" "Name=state,Values=available" --query "Images | sort_by(@, &CreationDate) | [-1].ImageId" --output text)

# 6. Create a security group
SG_ID=$(aws ec2 create-security-group --group-name ebs-tutorial-sg-$(date +%s) --description "Security group for EBS tutorial" --vpc-id $VPC_ID --query "GroupId" --output text)

# 7. Allow SSH access
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 22 --cidr 0.0.0.0/0

# 8. Launch the instance
INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --instance-type t3.micro --subnet-id $SUBNET_ID --security-group-ids $SG_ID --query "Instances[0].InstanceId" --output text)

# 9. Display instance ID and wait
echo "Instance ID: $INSTANCE_ID"
echo "Waiting for instance to be running..."

# 10. Wait for instance to be running
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

# 11. Verify both resources are in the same AZ
INSTANCE_AZ=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[0].Instances[0].Placement.AvailabilityZone" --output text)
echo "Instance AZ: $INSTANCE_AZ"
echo "Volume AZ: $VOLUME_AZ"

# 12. Final check
if [ "$INSTANCE_AZ" != "$VOLUME_AZ" ]; then echo 'Error: Instance and volume are in different availability zones!'; else echo 'Success: Instance and volume are in the same AZ'; fi
```

### Step 2: Attach the volume to the instance

Now that both resources are in the same availability zone, attach the volume:

```
# Attach the volume to the instance
aws ec2 attach-volume --volume-id $NEW_VOLUME_ID --instance-id $INSTANCE_ID --device /dev/sdf

echo "Waiting for volume to be attached..."
# Wait for the volume to be attached
aws ec2 wait volume-in-use --volume-ids $NEW_VOLUME_ID

# Verify attachment
aws ec2 describe-volumes --volume-ids $NEW_VOLUME_ID \
    --query 'Volumes[0].Attachments[0].{Device:Device,State:State,InstanceId:InstanceId}'
```

### Step 3: Connect to the instance and find the device name

#### 3.1: Ensure the instance has the required IAM role for Systems Manager
Once the above steps are complete, you can connect using AWS Systems Manager Session Manager (no SSH key required).
First, configure the EC2 instance to have an IAM role with Systems Manager permissions:

```
# Create IAM role for SSM access
cat > trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Create the role
aws iam create-role --role-name EC2-SSM-Role --assume-role-policy-document file://trust-policy.json

# Attach the required policy
aws iam attach-role-policy --role-name EC2-SSM-Role --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore

# Create instance profile
aws iam create-instance-profile --instance-profile-name EC2-SSM-InstanceProfile

# Add role to instance profile
aws iam add-role-to-instance-profile --role-name EC2-SSM-Role --instance-profile-name EC2-SSM-InstanceProfile

# Attach the instance profile to your EC2 instance
aws ec2 associate-iam-instance-profile --instance-id $INSTANCE_ID --iam-instance-profile Name=EC2-SSM-InstanceProfile

# Clean up temporary file
rm trust-policy.json
```

#### 3.2: Restart the instance to ensure SSM agent picks up the new permissions

```
# Reboot the instance
aws ec2 reboot-instances --instance-ids $INSTANCE_ID

# Wait for instance to be running again
echo "Waiting for instance to restart..."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

# Wait additional time for SSM agent to register
sleep 30
```

#### 3.3: Verify the instance is registered with Systems Manager

```
# Check if instance is registered with SSM
aws ssm describe-instance-information --filters "Key=InstanceIds,Values=$INSTANCE_ID" --query "InstanceInformationList[0].PingStatus"
```

The output should show "Online". If it shows nothing or "ConnectionLost", wait a few more minutes and try again.

#### 3.4: Install Session Manager plugin (if not already installed)

For macOS:

```
# Using Homebrew
brew install --cask session-manager-plugin
```


For Linux:
```
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm" -o "session-manager-plugin.rpm"
sudo yum install -y session-manager-plugin.rpm
rm session-manager-plugin.rpm
```


For Windows:
Download and install from: https://s3.amazonaws.com/session-manager-downloads/plugin/latest/windows/SessionManagerPluginSetup.exe

#### 3.5: Connect to the instance

Once the above steps are complete, you should be able to connect using AWS Systems Manager Session Manager (no SSH key required):

```
# Connect using Session Manager
aws ssm start-session --target $INSTANCE_ID
```

### Step 4: Find the actual device name (run on the EC2 instance)
?
Once connected to the instance, find the device name:

```
# For programmatic detection, find device by volume ID
# First try to find it in lsblk output
DEVICE_NAME=$(lsblk -o NAME,SERIAL | grep $(echo $NEW_VOLUME_ID | sed 's/vol-//') | awk '{print "/dev/"$1}' | head -1)

# If that doesn't work, check common device names
if [ -z "$DEVICE_NAME" ]; then
    if [ -b "/dev/xvdf" ]; then
        DEVICE_NAME="/dev/xvdf"
    elif [ -b "/dev/nvme1n1" ]; then
        DEVICE_NAME="/dev/nvme1n1"
    fi
fi

echo "Device name: $DEVICE_NAME"
```

### Step 5: Initialize the volume (run on the EC2 instance)

Once you've identified the correct device name, initialize the volume using one of these methods:

```
# Method 1: Basic initialization with dd
sudo dd if=$DEVICE_NAME of=/dev/null bs=1M status=progress
```

```
# Method 2: Faster initialization with fio (install first if needed)
sudo yum install -y fio
sudo fio --filename=$DEVICE_NAME --rw=read --bs=1M --iodepth=32 --ioengine=libaio --direct=1 --name=volume-initialize --runtime=300
```

```
# Method 3: Background initialization (recommended for large volumes)
# Get the device size first
DEVICE_SIZE=$(sudo blockdev --getsize64 $DEVICE_NAME)
echo "Device size: $DEVICE_SIZE bytes"

# Run fio with the full device size in background
sudo fio --filename=$DEVICE_NAME --rw=read --bs=1M --iodepth=8 --ioengine=libaio --direct=1 --size=$DEVICE_SIZE --name=volume-initialize --output=/tmp/fio-init.log &

# Monitor progress
tail -f /tmp/fio-init.log
```

To exit from the instance session, type the following:
```
exit
```

## Clean up resources

To avoid ongoing charges, let's clean up the resources we created in this tutorial.
**Clean up the test instance and volume**

After initialization, clean up the EC2 resources:

```
# Detach the volume first
aws ec2 detach-volume --volume-id $NEW_VOLUME_ID
aws ec2 wait volume-available --volume-ids $NEW_VOLUME_ID
# Terminate the instance
aws ec2 terminate-instances --instance-ids $INSTANCE_ID
# Delete the security group (after instance is terminated)
aws ec2 wait instance-terminated --instance-ids $INSTANCE_ID
aws ec2 delete-security-group --group-id $SG_ID
```

**Delete the new volume**

Delete the volume we created from the snapshot:

```
$ aws ec2 delete-volume --volume-id $NEW_VOLUME_ID
```

**Delete the original volume**

Now, let's delete our original test volume:

```
$ aws ec2 delete-volume --volume-id $VOLUME_ID
```

**Delete the snapshot**

Next, let's delete the snapshot:

```
$ aws ec2 delete-snapshot --snapshot-id $SNAPSHOT_ID
```
**Clean up IAM resources**
Remove the IAM role and instance profile created for Systems Manager access:
```
# Remove role from instance profile
aws iam remove-role-from-instance-profile --role-name EC2-SSM-Role --instance-profile-name EC2-SSM-InstanceProfile

# Delete the instance profile
aws iam delete-instance-profile --instance-profile-name EC2-SSM-InstanceProfile

# Detach the policy from the role
aws iam detach-role-policy --role-name EC2-SSM-Role --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore

# Delete the IAM role
aws iam delete-role --role-name EC2-SSM-Role
```

**Clean up temporary files**
Remove any temporary files created during the process:
```
# Remove temporary files created during the process
rm -f trust-policy.json
rm -f /tmp/fio-init.log
rm -f sessionmanager-bundle.zip
rm -f session-manager-plugin.rpm
```

**Restore the original encryption setting (optional)**

If you want to restore the original encryption setting:

```
$ aws ec2 disable-ebs-encryption-by-default
```
The response is as follows:
```
{
    "EbsEncryptionByDefault": false
}
```
This command disables encryption by default, returning your account to its original setting.

## Going to production

This tutorial is designed to help you learn how to use the AWS CLI to manage EBS resources. When implementing these operations in a production environment, consider the following best practices:

### Security Best Practices

1. **Use Customer Managed Keys**: For production environments, consider using customer managed keys (CMKs) instead of AWS managed keys for more control over your encryption keys.

2. **Implement Least Privilege IAM Policies**: Create IAM policies that grant only the permissions needed for specific operations rather than using broad permissions.

3. **Implement Snapshot Lifecycle Policies**: Use Amazon Data Lifecycle Manager to automate snapshot creation, retention, and deletion according to your backup requirements.

### Architecture Best Practices

1. **Automation**: Use AWS CloudFormation or Terraform to automate the creation and management of EBS resources instead of manual CLI commands.

2. **Multi-AZ and Multi-Region Strategy**: For critical data, implement a backup strategy that includes copying snapshots across multiple availability zones or regions.

3. **Monitoring and Alerting**: Set up CloudWatch alarms to monitor EBS volume performance and alert on issues.

4. **Resource Tagging**: Implement a comprehensive tagging strategy to organize and track your EBS resources.

For more information on building production-ready solutions, refer to:

- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [AWS Security Best Practices](https://aws.amazon.com/architecture/security-identity-compliance/)
- [Amazon EBS Best Practices](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EBSPerformance.html)

## Next steps

Now that you've learned how to work with Amazon EBS encryption, snapshots, and volume initialization, you might want to explore these related topics:

- [Amazon EBS volume types](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-volume-types.html)
- [Amazon EBS fast snapshot restore](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-fast-snapshot-restore.html)
- [Amazon Data Lifecycle Manager](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/snapshot-lifecycle.html)
- [Amazon EBS encryption](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EBSEncryption.html)
- [Amazon EBS performance](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-optimized.html)
