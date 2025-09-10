# Getting started with Amazon Lightsail using the AWS CLI

This tutorial guides you through creating and managing a virtual private server (instance) in Amazon Lightsail using the AWS Command Line Interface (AWS CLI). You'll learn how to create an instance, connect to it, add storage, create snapshots, and clean up resources.

## Prerequisites

Before you begin this tutorial, make sure you have the following:

1. The AWS CLI. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html). You can also [use AWS CloudShell](https://docs.aws.amazon.com/lightsail/latest/userguide/amazon-lightsail-cloudshell.html), which includes the AWS CLI.
2. Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
3. Basic familiarity with command line interfaces and SSH concepts.
4. [Sufficient permissions](https://docs.aws.amazon.com/lightsail/latest/userguide/security_iam_service-with-iam.html) to create and manage Lightsail resources in your AWS account.

### Cost considerations

The resources you create in this tutorial will incur the following approximate costs if left running:
- Lightsail nano instance: $5.00 USD per month (approximately $0.0068 per hour)
- 8 GB additional storage: $0.80 USD per month (approximately $0.0011 per hour)
- Instance snapshot: approximately $1.00 USD per month for a 20 GB snapshot (approximately $0.0014 per hour)

The total cost for running this tutorial for one hour is approximately $0.0093 USD. The tutorial includes cleanup instructions to help you avoid ongoing charges. New Lightsail customers may be eligible for the free tier, which includes the $5 USD plan free for one month (up to 750 hours).

You can verify your AWS CLI configuration with the following command:

```
aws configure list
```

This command displays your current configuration settings, including the default region where resources will be created.

## Explore available options

Before creating an instance, it's helpful to explore the available options for instance images (blueprints) and sizes (bundles).

**View available blueprints**

Blueprints are templates that include an operating system and pre-installed applications.

```
aws lightsail get-blueprints --query 'blueprints[0:5].[blueprintId,name]' --output table
```

The output shows the first five available blueprints with their IDs and names. You can remove the query parameter to see all available blueprints.

**View available bundles**

Bundles define the hardware specifications and pricing for your instance.

```
aws lightsail get-bundles --query 'bundles[0:5].[bundleId,name,price]' --output table
```

The output displays the first five available bundles with their IDs, names, and monthly prices. The smallest bundle (nano) is sufficient for this tutorial.

## Create an instance

Now that you've explored the available options, you can create a Lightsail instance.

**Create a Lightsail instance**

The following command creates a new Amazon Linux 2023 instance using the smallest bundle size:

```
aws lightsail create-instances \
  --instance-names MyLightsailInstance \
  --availability-zone us-west-2a \
  --blueprint-id amazon_linux_2023 \
  --bundle-id nano_3_0
```

The response includes an operation ID and details about the instance creation process. Instance creation typically takes a few minutes to complete.

**Check instance status**

You can monitor the status of your instance with the following command:

```
aws lightsail get-instance-state --instance-name MyLightsailInstance
```

Wait until the state shows "running" before proceeding to the next step.

**Get instance details**

Once your instance is running, retrieve its details:

```
aws lightsail get-instance --instance-name MyLightsailInstance
```

The output includes important information such as the public IP address, which you'll need to connect to your instance.

## Connect to your instance

To connect to your instance using SSH, you need to download the default key pair and use it to establish a connection.

**Download the default key pair**

```
aws lightsail download-default-key-pair --output text > lightsail_key.pem
chmod 400 lightsail_key.pem
```

The first command downloads the private key and saves it to a file. The second command sets the appropriate permissions so that only you can read the file, which is required for SSH.

**Connect to your instance**

Use the following command to connect to your instance, replacing PUBLIC_IP with your instance's public IP address:

```
ssh -i lightsail_key.pem ec2-user@PUBLIC_IP
```

Once connected, you can run commands on your instance and manage it as needed.

## Add storage to your instance

As your application grows, you might need additional storage space. Lightsail allows you to create and attach additional disks to your instances.

**Create a disk**

The following command creates a new 8GB disk:

```
aws lightsail create-disk \
  --disk-name MyDataDisk \
  --availability-zone us-west-2a \
  --size-in-gb 8
```

Wait for the disk to become available before proceeding to the next step. You can check the disk status with:

```
aws lightsail get-disk --disk-name MyDataDisk --query 'disk.state' --output text
```

Wait until the state shows "available" before proceeding.

**Attach the disk to your instance**

Once the disk is created, attach it to your instance:

```
aws lightsail attach-disk \
  --disk-name MyDataDisk \
  --instance-name MyLightsailInstance \
  --disk-path /dev/xvdf
```

The disk-path parameter specifies where the disk will be attached in the Linux file system.

**Format and mount the disk**

After attaching the disk, you need to connect to your instance via SSH and run the following commands to format and mount it:

```
# Check if the disk is visible
lsblk

# Format the disk (be careful - this erases all data on the disk)
sudo mkfs -t ext4 /dev/xvdf

# Create a mount point
sudo mkdir -p /mnt/my-data

# Mount the disk
sudo mount /dev/xvdf /mnt/my-data

# Set permissions
sudo chown ec2-user:ec2-user /mnt/my-data

# To mount automatically after reboot, add to fstab
echo '/dev/xvdf /mnt/my-data ext4 defaults,nofail 0 2' | sudo tee -a /etc/fstab
```

These commands format the disk with the ext4 file system, create a mount point, mount the disk, and configure it to mount automatically when the instance reboots.

## Create a snapshot

Snapshots provide a way to back up your instance and create new instances from the backup. This is useful for disaster recovery, testing, or creating duplicate environments.

**Create an instance snapshot**

The following command creates a snapshot of your instance:

```
aws lightsail create-instance-snapshot \
  --instance-name MyLightsailInstance \
  --instance-snapshot-name MyInstanceSnapshot
```

The snapshot process may take several minutes to complete, depending on the size of your instance and attached disks.

**View snapshot details**

You can check the status of your snapshot with the following command:

```
aws lightsail get-instance-snapshot --instance-snapshot-name MyInstanceSnapshot
```

The output includes details about the snapshot, including its state and creation time. Wait until the state shows "available" before proceeding.

## Clean up resources

When you're finished with this tutorial, you should clean up your resources to avoid incurring additional charges.

**Delete the snapshot**

```
aws lightsail delete-instance-snapshot --instance-snapshot-name MyInstanceSnapshot
```

**Detach and delete the disk**

```
aws lightsail detach-disk --disk-name MyDataDisk
```

Wait for the disk to be fully detached before deleting it:

```
aws lightsail get-disk --disk-name MyDataDisk --query 'disk.attachmentState' --output text
```

Once the disk shows as "detached", you can delete it:

```
aws lightsail delete-disk --disk-name MyDataDisk
```

**Delete the instance**

```
aws lightsail delete-instance --instance-name MyLightsailInstance
```

These commands remove all the resources created during this tutorial, ensuring you won't be charged for them in the future.

## Going to production

This tutorial is designed to help you learn how to use the Amazon Lightsail API through the AWS CLI. For production environments, consider the following additional considerations:

### Security best practices

1. **Restrict SSH access**: Limit SSH access to specific IP addresses using the `close-instance-public-ports` and `open-instance-public-ports` commands with specific CIDR ranges.

2. **Use encryption**: Enable disk encryption for sensitive data.

3. **Implement IAM best practices**: Follow the principle of least privilege when assigning permissions to IAM users and roles.

For more information on security best practices, see the [AWS Security Best Practices](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html).

### Architecture considerations

1. **High availability**: For production workloads, consider using multiple instances across different availability zones with a load balancer.

2. **Monitoring**: Set up CloudWatch monitoring and alarms to track instance performance and health.

3. **Automated backups**: Configure automatic snapshots instead of manual ones.

4. **Right-sizing**: Choose appropriate instance sizes based on your workload requirements.

For more information on architectural best practices, see the [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html).

## Next steps

Now that you've learned the basics of managing Lightsail resources using the AWS CLI, explore other Lightsail features:

1. [Create and manage static IPs](https://docs.aws.amazon.com/lightsail/latest/userguide/lightsail-create-static-ip.html) to maintain a consistent public IP address.
2. [Set up DNS zones and records](https://docs.aws.amazon.com/lightsail/latest/userguide/lightsail-how-to-create-dns-entry.html) to route domain traffic to your instance.
3. [Configure automatic snapshots](https://docs.aws.amazon.com/lightsail/latest/userguide/amazon-lightsail-configuring-automatic-snapshots.html) to regularly back up your instance.
4. [Create a load balancer](https://docs.aws.amazon.com/lightsail/latest/userguide/create-lightsail-load-balancer-and-attach-lightsail-instances.html) to distribute traffic across multiple instances.
5. [Set up a database](https://docs.aws.amazon.com/lightsail/latest/userguide/amazon-lightsail-creating-a-database.html) to store and manage your application data.

For more information about available AWS CLI commands for Lightsail, see the [AWS CLI Command Reference for Lightsail](https://docs.aws.amazon.com/cli/latest/reference/lightsail/).

## Security Considerations

This tutorial demonstrates basic AWS CLI usage for educational purposes. For production environments:
- Follow the [AWS Well-Architected Security Pillar](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/)
- Implement least privilege access principles
- Enable appropriate logging and monitoring
- Review and apply security best practices specific to each service used

**Important:** This tutorial does not provide security guidance. Consult AWS security documentation and your security team for production deployments.