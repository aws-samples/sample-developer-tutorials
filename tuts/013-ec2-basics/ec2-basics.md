# Getting started with Amazon EC2 using the AWS CLI

This tutorial guides you through the process of creating and managing Amazon EC2 instances using the AWS Command Line Interface (AWS CLI). You'll learn how to create key pairs, set up security groups, launch instances, and manage Elastic IP addresses.

## Prerequisites

Before you begin this tutorial, make sure you have the following:

1. The AWS CLI installed and configured with appropriate credentials. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
2. Basic familiarity with command line interfaces and SSH concepts.
3. [Sufficient permissions](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_examples_ec2_instances.html) to create and manage EC2 resources in your AWS account.

**Cost Information**: Completing this tutorial will incur minimal costs (approximately $0.01-$0.02) if you follow all steps including cleanup. The tutorial uses t2.micro instances which are Free Tier eligible (750 hours/month). Elastic IP addresses are free when associated with running instances but cost $0.005/hour when not associated. Following the cleanup instructions will help you avoid ongoing charges.

## Create a key pair

SSH key pairs allow you to securely connect to your EC2 instances without using passwords. In this section, you'll create a new key pair and save the private key to your local machine.

**Create a new key pair**

The following command creates a new SSH key pair named "my-ec2-key" and saves the private key to your local machine.

```bash
aws ec2 create-key-pair \
  --key-name "my-ec2-key" \
  --query 'KeyMaterial' \
  --output text > my-ec2-key.pem
```

After running this command, the private key is saved to a file named `my-ec2-key.pem` in your current directory.

**Set proper permissions on the key file**

SSH requires that private key files are not readable by others. Use the following command to set the correct permissions:

```bash
chmod 400 my-ec2-key.pem
```

This command ensures that only you can read the private key file, which is a security requirement for SSH.

**Verify your key pair**

You can list your key pairs to verify that the new key pair was created successfully:

```bash
aws ec2 describe-key-pairs

{
    "KeyPairs": [
        {
            "KeyPairId": "key-abcd1234",
            "KeyFingerprint": "1a:2b:3c:4d:5e:6f:7g:8h:9i:0j:1k:2l:3m:4n:5o:6p",
            "KeyName": "my-ec2-key",
            "Tags": []
        }
    ]
}
```

The output shows details about your key pair, including its name, ID, and fingerprint.

## Create a security group

Security groups act as virtual firewalls for your EC2 instances to control inbound and outbound traffic. In this section, you'll create a security group and configure it to allow SSH access from your IP address.

**Create a security group**

The following command creates a new security group:

```bash
aws ec2 create-security-group \
  --group-name "my-ec2-sg" \
  --description "Security group for EC2 tutorial" \
  --query "GroupId" \
  --output text

sg-abcd1234
```

The output is the ID of your new security group. Make note of this ID as you'll need it in subsequent commands.

**Add a rule to allow SSH access**

To connect to your instance via SSH, you need to add an inbound rule to your security group. For security reasons, it's best to restrict SSH access to your current IP address:

```bash
# Get your current public IP address
MY_IP=$(curl -s http://checkip.amazonaws.com)

# Add a rule to allow SSH access only from your IP address
aws ec2 authorize-security-group-ingress \
  --group-id "sg-abcd1234" \
  --protocol tcp \
  --port 22 \
  --cidr "$MY_IP/32"

{
    "Return": true,
    "SecurityGroupRules": [
        {
            "SecurityGroupRuleId": "sgr-abcd1234",
            "GroupId": "sg-abcd1234",
            "IpProtocol": "tcp",
            "FromPort": 22,
            "ToPort": 22,
            "CidrIpv4": "203.0.113.75/32",
            "Description": ""
        }
    ]
}
```

The response confirms that the rule was added successfully. This rule allows SSH connections (port 22) only from your current IP address.

**Verify security group configuration**

You can check the security group's configuration with the following command:

```bash
aws ec2 describe-security-groups \
  --group-ids "sg-abcd1234"

{
    "SecurityGroups": [
        {
            "Description": "Security group for EC2 tutorial",
            "GroupName": "my-ec2-sg",
            "IpPermissions": [
                {
                    "FromPort": 22,
                    "IpProtocol": "tcp",
                    "IpRanges": [
                        {
                            "CidrIp": "203.0.113.75/32"
                        }
                    ],
                    "ToPort": 22
                }
            ],
            "OwnerId": "123456789012",
            "GroupId": "sg-abcd1234",
            "IpPermissionsEgress": [
                {
                    "IpProtocol": "-1",
                    "IpRanges": [
                        {
                            "CidrIp": "0.0.0.0/0"
                        }
                    ]
                }
            ],
            "VpcId": "vpc-abcd1234"
        }
    ]
}
```

The output shows the security group's inbound rules (IpPermissions), which include the SSH rule you just added.

## Launch an EC2 instance

Now that you have a key pair and security group, you can launch an EC2 instance. In this section, you'll find a suitable Amazon Machine Image (AMI) and launch an instance.

**Find an Amazon Linux 2023 AMI**

Amazon Linux 2023 is the recommended Linux distribution for EC2. You can find the latest Amazon Linux 2023 AMI using the AWS Systems Manager Parameter Store:

```bash
aws ssm get-parameters-by-path \
  --path "/aws/service/ami-amazon-linux-latest" \
  --query "Parameters[?contains(Name, 'al2023-ami-kernel-default-x86_64')].Value" \
  --output text | head -1

ami-abcd1234
```

The output is the ID of the latest Amazon Linux 2023 AMI. Make note of this ID as you'll need it to launch your instance.

**Launch an instance with IMDSv2 and encryption enabled**

Now you can launch an EC2 instance using the AMI ID, key pair, and security group you created earlier:

```bash
aws ec2 run-instances \
  --image-id "ami-abcd1234" \
  --instance-type "t2.micro" \
  --key-name "my-ec2-key" \
  --security-group-ids "sg-abcd1234" \
  --metadata-options "HttpTokens=required,HttpEndpoint=enabled" \
  --block-device-mappings "DeviceName=/dev/xvda,Ebs={Encrypted=true}" \
  --count 1 \
  --query 'Instances[0].InstanceId' \
  --output text

i-abcd1234
```

This command includes two important security enhancements:
- `--metadata-options "HttpTokens=required"` enforces IMDSv2, which provides additional protection against SSRF attacks
- `--block-device-mappings "DeviceName=/dev/xvda,Ebs={Encrypted=true}"` ensures that the EBS volume is encrypted

The output is the ID of your new instance. Make note of this ID as you'll need it in subsequent commands.

**Wait for the instance to be running**

After launching an instance, it takes a few moments to initialize. You can wait for the instance to reach the "running" state:

```bash
aws ec2 wait instance-running --instance-ids "i-abcd1234"
```

This command will wait until the instance is running before returning.

**Get instance details**

Once your instance is running, you can retrieve its details:

```bash
aws ec2 describe-instances \
  --instance-ids "i-abcd1234" \
  --query 'Reservations[0].Instances[0].{ID:InstanceId,Type:InstanceType,State:State.Name,PublicIP:PublicIpAddress}' \
  --output table

---------------------------------------------------------
|                  DescribeInstances                    |
+---------------+------------+----------+---------------+
|       ID      |  PublicIP  |  State   |     Type     |
+---------------+------------+----------+---------------+
|  i-abcd1234   |  203.0.113.75  |  running  |  t2.micro   |
+---------------+------------+----------+---------------+
```

The output shows details about your instance, including its public IP address, which you'll need to connect via SSH.

## Connect to your instance

Now that your instance is running, you can connect to it using SSH with the key pair you created earlier.

**Connect via SSH**

Use the following command to connect to your instance, replacing the IP address with your instance's public IP:

```bash
ssh -i my-ec2-key.pem ec2-user@203.0.113.75
```

If the connection is successful, you'll see a welcome message and a command prompt for your instance:

```
   ,     #_
   ~\_  ####_        Amazon Linux 2023
  ~~  \_#####\
  ~~     \###|
  ~~       \#/ ___   https://aws.amazon.com/linux/amazon-linux-2023
   ~~       V~' '->
    ~~~         /
      ~~._.   _/
         _/ _/
       _/m/'
```

You can now run commands on your instance. When you're done, type `exit` to close the SSH connection.

## Stop and start your instance

You can stop and start your EC2 instance as needed. When you stop an instance, it remains in your account but doesn't incur compute charges. When you start it again, it will have a new public IP address (unless you use an Elastic IP, which we'll cover next).

**Stop your instance**

To stop your instance, use the following command:

```bash
aws ec2 stop-instances --instance-ids "i-abcd1234"

{
    "StoppingInstances": [
        {
            "CurrentState": {
                "Code": 64,
                "Name": "stopping"
            },
            "InstanceId": "i-abcd1234",
            "PreviousState": {
                "Code": 16,
                "Name": "running"
            }
        }
    ]
}
```

The response shows that the instance is transitioning from "running" to "stopping" state.

**Wait for the instance to stop**

You can wait for the instance to reach the "stopped" state:

```bash
aws ec2 wait instance-stopped --instance-ids "i-abcd1234"
```

**Start your instance**

To start your instance again, use the following command:

```bash
aws ec2 start-instances --instance-ids "i-abcd1234"

{
    "StartingInstances": [
        {
            "CurrentState": {
                "Code": 0,
                "Name": "pending"
            },
            "InstanceId": "i-abcd1234",
            "PreviousState": {
                "Code": 80,
                "Name": "stopped"
            }
        }
    ]
}
```

The response shows that the instance is transitioning from "stopped" to "pending" state.

**Wait for the instance to start**

You can wait for the instance to reach the "running" state:

```bash
aws ec2 wait instance-running --instance-ids "i-abcd1234"
```

**Get the new public IP address**

After restarting, your instance will have a new public IP address:

```bash
aws ec2 describe-instances \
  --instance-ids "i-abcd1234" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text

203.0.113.80
```

Note that the IP address has changed. This is normal behavior when stopping and starting an EC2 instance.

## Allocate and associate an Elastic IP address

If you need a consistent IP address for your instance, you can use an Elastic IP address. An Elastic IP is a static IPv4 address that you can associate with your instance, and it remains the same even when you stop and start the instance.

**Allocate an Elastic IP address**

The following command allocates a new Elastic IP address:

```bash
aws ec2 allocate-address \
  --domain vpc \
  --query '[PublicIp,AllocationId]' \
  --output text

203.0.113.85 eipalloc-abcd1234
```

The output shows the Elastic IP address and its allocation ID. Make note of both as you'll need them in subsequent commands.

**Associate the Elastic IP with your instance**

Now you can associate the Elastic IP with your instance:

```bash
aws ec2 associate-address \
  --instance-id "i-abcd1234" \
  --allocation-id "eipalloc-abcd1234" \
  --query "AssociationId" \
  --output text

eipassoc-abcd1234
```

The output is the association ID, which you'll need if you want to disassociate the Elastic IP later.

**Connect using the Elastic IP**

You can now connect to your instance using the Elastic IP:

```bash
ssh -i my-ec2-key.pem ec2-user@203.0.113.85
```

## Test Elastic IP persistence

Let's verify that the Elastic IP remains associated with your instance even after stopping and starting it.

**Stop your instance**

```bash
aws ec2 stop-instances --instance-ids "i-abcd1234"
aws ec2 wait instance-stopped --instance-ids "i-abcd1234"
```

**Start your instance**

```bash
aws ec2 start-instances --instance-ids "i-abcd1234"
aws ec2 wait instance-running --instance-ids "i-abcd1234"
```

**Verify the Elastic IP is still associated**

```bash
aws ec2 describe-instances \
  --instance-ids "i-abcd1234" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text

203.0.113.85
```

The output shows that the instance still has the same Elastic IP address, confirming that the Elastic IP remains associated even after stopping and starting the instance.

## Going to production

This tutorial is designed to teach you the basics of EC2 instance management using the AWS CLI. For production environments, consider these additional best practices:

1. **High Availability**: Deploy instances across multiple Availability Zones to improve resilience.

2. **Auto Scaling**: Use [Auto Scaling groups](https://docs.aws.amazon.com/autoscaling/ec2/userguide/what-is-amazon-ec2-auto-scaling.html) to automatically adjust capacity based on demand.

3. **Load Balancing**: Distribute traffic across multiple instances using [Elastic Load Balancing](https://docs.aws.amazon.com/elasticloadbalancing/latest/userguide/what-is-load-balancing.html).

4. **Infrastructure as Code**: Manage infrastructure using [AWS CloudFormation](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/Welcome.html) or [AWS CDK](https://docs.aws.amazon.com/cdk/latest/guide/home.html).

5. **Security Hardening**:
   - Restrict outbound traffic in security groups
   - Use private subnets for instances that don't need direct internet access
   - Implement [VPC endpoints](https://docs.aws.amazon.com/vpc/latest/privatelink/vpc-endpoints.html) for AWS services
   - Follow the [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html) security pillar

6. **Monitoring and Logging**: Implement [CloudWatch](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/WhatIsCloudWatch.html) monitoring and centralized logging.

7. **Backup and Recovery**: Implement regular [EBS snapshots](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EBSSnapshots.html) and a disaster recovery strategy.

## Clean up resources

When you're finished with this tutorial, you should clean up the resources you created to avoid incurring additional charges.

**Disassociate the Elastic IP**

```bash
aws ec2 disassociate-address --association-id "eipassoc-abcd1234"
```

**Release the Elastic IP**

```bash
aws ec2 release-address --allocation-id "eipalloc-abcd1234"
```

**Terminate the instance**

```bash
aws ec2 terminate-instances --instance-ids "i-abcd1234"

{
    "TerminatingInstances": [
        {
            "CurrentState": {
                "Code": 32,
                "Name": "shutting-down"
            },
            "InstanceId": "i-abcd1234",
            "PreviousState": {
                "Code": 16,
                "Name": "running"
            }
        }
    ]
}
```

**Wait for the instance to terminate**

```bash
aws ec2 wait instance-terminated --instance-ids "i-abcd1234"
```

**Delete the security group**

```bash
aws ec2 delete-security-group --group-id "sg-abcd1234"
```

**Delete the key pair**

```bash
aws ec2 delete-key-pair --key-name "my-ec2-key"
rm -f my-ec2-key.pem
```

## Next steps

Now that you've learned the basics of managing EC2 instances using the AWS CLI, explore other EC2 features:

1. **Auto Scaling** – [Automatically adjust capacity](https://docs.aws.amazon.com/autoscaling/ec2/userguide/what-is-amazon-ec2-auto-scaling.html) based on demand.
2. **Load Balancing** – [Distribute traffic](https://docs.aws.amazon.com/elasticloadbalancing/latest/userguide/what-is-load-balancing.html) across multiple instances.
3. **EBS Volumes** – [Add additional storage](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-volumes.html) to your instances.
4. **AMI Creation** – [Create your own AMIs](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html) with your applications pre-installed.
5. **Instance Metadata** – [Access instance metadata](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instancedata-data-retrieval.html) from within your instances.
