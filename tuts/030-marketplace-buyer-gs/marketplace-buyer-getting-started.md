# Getting started with AWS Marketplace using the AWS CLI

This tutorial guides you through common AWS Marketplace buyer operations using the AWS Command Line Interface (AWS CLI). You'll learn how to search for products, launch an EC2 instance with a product AMI, and manage your subscriptions.

**Alternative title:** Using the AWS CLI to find and deploy AWS Marketplace products

## Topics

* [Prerequisites](#prerequisites)
* [Searching for products](#searching-for-products)
* [Creating resources for your instance](#creating-resources-for-your-instance)
* [Launching an instance](#launching-an-instance)
* [Managing your software](#managing-your-software)
* [Cleaning up resources](#cleaning-up-resources)
* [Going to production](#going-to-production)
* [Next steps](#next-steps)

## Prerequisites

Before you begin this tutorial, make sure you have the following.

1. The AWS CLI. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html). You can also [use AWS CloudShell](https://docs.aws.amazon.com/cloudshell/latest/userguide/welcome.html), which includes the AWS CLI.
2. Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
3. Basic familiarity with command line interfaces and SSH concepts.
4. [Sufficient permissions](https://docs.aws.amazon.com/marketplace/latest/buyerguide/buyer-security-iam-awsmanpol.html) to access AWS Marketplace and create EC2 resources in your AWS account.
5. Estimated time to complete: 30-45 minutes.
6. Estimated cost: Approximately $0.0116 for running a t2.micro EC2 instance for one hour. If you choose a paid AWS Marketplace product, additional charges may apply based on the product's pricing model.

Let's get started with exploring AWS Marketplace and launching software using the CLI.

## Searching for products

AWS Marketplace offers a wide range of software products that you can deploy on AWS. In this section, you'll learn how to search for products using the AWS CLI.

**List available AMI products**

The following command lists available AMI products in AWS Marketplace.

```
aws marketplace-catalog list-entities \
  --catalog "AWSMarketplace" \
  --entity-type "AmiProduct"
```

This command returns a list of AMI products available in AWS Marketplace. The response includes details such as product IDs, names, and descriptions.

**Search for specific products**

If you're looking for a specific type of product, you can use the list-entities command with a query string.

```
aws marketplace-catalog list-entities \
  --catalog "AWSMarketplace" \
  --entity-type "AmiProduct" \
  --query "WordPress"
```

This command searches for WordPress-related AMI products in AWS Marketplace. You can replace `WordPress` with any keyword relevant to your needs.

**Get details about a specific product**

Once you've found a product you're interested in, you can get more details about it using the describe-entity command.

```
aws marketplace-catalog describe-entity \
  --catalog "AWSMarketplace" \
  --entity-id "entity-id"
```

Replace `entity-id` with the actual entity ID of the product you want to learn more about. This command provides comprehensive information about the product, including its features, pricing, and usage instructions.

## Creating resources for your instance

Before launching an instance with your chosen AWS Marketplace product, you need to create some supporting resources. This section guides you through creating a key pair and security group.

**Create a key pair for SSH access**

The following command creates a new SSH key pair and saves the private key to your local machine.

```
aws ec2 create-key-pair \
  --key-name marketplace-tutorial-key \
  --query 'KeyMaterial' \
  --output text > marketplace-tutorial-key.pem
```

After running this command, the private key is saved to your current directory. Next, set the appropriate permissions for the key file.

```
chmod 400 marketplace-tutorial-key.pem
```

This ensures that only you can read the private key file, which is a security requirement for SSH. Store this key file securely and never share it or check it into version control systems.

**Get your default VPC ID**

For better resource organization, we'll get your default VPC ID to use when creating the security group.

```
aws ec2 describe-vpcs \
  --filters "Name=isDefault,Values=true" \
  --query "Vpcs[0].VpcId" \
  --output text
```

Note the VPC ID from the output for the next step.

**Create a security group**

The following command creates a new security group for your instance in your default VPC.

```
aws ec2 create-security-group \
  --group-name marketplace-tutorial-sg \
  --description "Security group for AWS Marketplace tutorial" \
  --vpc-id vpc-id
```

Replace `vpc-id` with the VPC ID you obtained in the previous step. The response includes the security group ID, which you'll need for the next steps.

**Configure security group rules**

For this tutorial, we'll restrict SSH access to your current IP address for better security.

```
aws ec2 authorize-security-group-ingress \
  --group-name marketplace-tutorial-sg \
  --protocol tcp \
  --port 22 \
  --cidr $(curl -s https://checkip.amazonaws.com)/32
```

This command allows SSH access only from your current IP address, which is more secure than allowing access from anywhere.

For HTTP access, which might be needed depending on the product you're deploying:

```
aws ec2 authorize-security-group-ingress \
  --group-name marketplace-tutorial-sg \
  --protocol tcp \
  --port 80 \
  --cidr $(curl -s https://checkip.amazonaws.com)/32
```

This restricts HTTP access to your current IP address as well. For a production environment, you would configure these rules differently based on your specific requirements.

## Launching an instance

Now that you have the necessary resources in place, you can launch an EC2 instance with your chosen AWS Marketplace product. This section shows you how to launch and connect to your instance.

**Get the AMI ID**

For this tutorial, we'll use an Amazon Linux 2 AMI as an example. In a real scenario, you would use the AMI ID from your chosen AWS Marketplace product.

```
aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=amzn2-ami-hvm-2.0.*-x86_64-gp2" "Name=state,Values=available" \
  --query "sort_by(Images, &CreationDate)[-1].ImageId" \
  --output text
```

This command retrieves the latest Amazon Linux 2 AMI ID. Note the AMI ID from the output for the next step.

**Launch an EC2 instance**

The following command launches an EC2 instance using the AMI ID, key pair, and security group you created earlier.

```
aws ec2 run-instances \
  --image-id ami-abcd1234 \
  --instance-type t2.micro \
  --key-name marketplace-tutorial-key \
  --security-group-ids sg-abcd1234 \
  --count 1
```

Replace `ami-abcd1234` with the actual AMI ID you obtained in the previous step and `sg-abcd1234` with your security group ID. The response includes details about your new instance, including its instance ID.

**Check instance status**

You can check the status of your instance using the describe-instances command.

```
aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" \
  --query "Reservations[*].Instances[*].[InstanceId,State.Name,PublicDnsName]" \
  --output table
```

This command lists all your running instances along with their IDs, states, and public DNS names. Wait until your instance is in the "running" state before proceeding.

**Connect to your instance**

Once your instance is running, you can connect to it via SSH using the key pair you created earlier.

```
ssh -i marketplace-tutorial-key.pem ec2-user@your-instance-public-dns
```

Replace `your-instance-public-dns` with the actual public DNS name of your instance from the previous command's output. The username might be different depending on the AMI you're using.

## Managing your instances

After launching your instance, you can monitor it. 

**Monitor your EC2 instances**

You can monitor your running instances with the following command.

```
aws ec2 describe-instances \
  --filters "Name=image-id,Values=ami-abcd1234" \
  --query "Reservations[*].Instances[*].[InstanceId,State.Name,PublicDnsName]" \
  --output table
```

Replace `ami-abcd1234` with the actual AMI ID of your instance. This command shows all instances launched with that specific AMI.

## Cleaning up resources

When you're finished with your AWS Marketplace resources, you should clean them up to avoid incurring additional charges. This section shows you how to terminate your instance and delete associated resources.

**Terminate your instance**

The following command terminates your EC2 instance.

```
aws ec2 terminate-instances \
  --instance-ids i-1234abcd
```

Replace `i-1234abcd` with the actual instance ID of your instance. The response confirms that the termination process has started.

**Wait for instance termination**

Before deleting the security group, wait for the instance to fully terminate.

```
aws ec2 wait instance-terminated --instance-ids i-1234abcd
```

Replace `i-1234abcd` with your actual instance ID. This command will wait until the instance is fully terminated.

**Delete your security group**

After your instance is terminated, you can delete the security group.

```
aws ec2 delete-security-group \
  --group-name marketplace-tutorial-sg
```

This command deletes the security group you created earlier. Make sure all instances using this security group are terminated before attempting to delete it.

**Delete your key pair**

Finally, delete the key pair you created.

```
aws ec2 delete-key-pair \
  --key-name marketplace-tutorial-key
```

This command deletes the key pair from AWS. You can also delete the local copy of your private key if you no longer need it.

```
rm marketplace-tutorial-key.pem
```

## Going to production

This tutorial is designed to help you learn how to use AWS Marketplace and EC2 via the AWS CLI. For production environments, consider the following additional best practices:

### Security considerations

1. **Network segmentation**: Create a custom VPC with public and private subnets, placing your instances in private subnets when possible.
2. **IAM roles**: Use IAM roles instead of access keys for EC2 instances to access AWS services.
3. **Security groups**: Implement the principle of least privilege by only opening necessary ports to specific IP ranges.
4. **HTTPS**: Configure HTTPS with proper certificates for any web applications.
5. **Security monitoring**: Implement AWS Security Hub, GuardDuty, and CloudTrail for comprehensive security monitoring.

### Architecture best practices

1. **High availability**: Deploy across multiple Availability Zones for resilience.
2. **Auto Scaling**: Implement Auto Scaling groups to handle varying loads.
3. **Infrastructure as Code**: Use AWS CloudFormation or AWS CDK to define and provision resources.
4. **Monitoring and observability**: Set up CloudWatch metrics, logs, and alarms.
5. **Cost optimization**: Use resource tagging, consider reserved instances or Savings Plans, and implement automated resource cleanup.

For more information on building production-ready systems on AWS, refer to:
- [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html)
- [AWS Security Best Practices](https://docs.aws.amazon.com/whitepapers/latest/aws-security-best-practices/welcome.html)
- [AWS Architecture Center](https://aws.amazon.com/architecture/)

## Troubleshooting

Here are solutions to common issues you might encounter during this tutorial:

**Permission errors with marketplace-catalog commands**

If you receive permission errors when running marketplace-catalog commands, ensure your IAM user or role has the appropriate permissions. You may need to attach the `AWSMarketplaceFullAccess` managed policy or create a custom policy with specific marketplace-catalog permissions.

**Security group deletion fails**

If you can't delete a security group because it's still associated with an instance, ensure all instances using the security group are fully terminated. You can check this with:

```
aws ec2 describe-instances \
  --filters "Name=instance.group-name,Values=marketplace-tutorial-sg" \
  --query "Reservations[*].Instances[*].[InstanceId,State.Name]" \
  --output table
```

**SSH connection issues**

If you can't connect to your instance via SSH, check:
1. The instance is in the "running" state
2. You're using the correct key file and username
3. Your security group allows SSH access from your current IP address
4. The instance has a public IP address

## Next steps

Now that you've learned the basics of using AWS Marketplace with the AWS CLI, explore these additional features:

1. [Private marketplace](https://docs.aws.amazon.com/marketplace/latest/buyerguide/private-marketplace.html) - Create a curated digital catalog of pre-approved products for your organization.
2. [Procurement systems integration](https://docs.aws.amazon.com/marketplace/latest/buyerguide/procurement-systems-integration.html) - Connect AWS Marketplace to your procurement systems.
3. [License management](https://docs.aws.amazon.com/marketplace/latest/buyerguide/license-management.html) - Manage licenses for your AWS Marketplace software.
4. [Container products](https://docs.aws.amazon.com/marketplace/latest/buyerguide/container-products.html) - Deploy container-based applications from AWS Marketplace.
5. [SaaS products](https://docs.aws.amazon.com/marketplace/latest/buyerguide/saas-products.html) - Subscribe to and use Software as a Service products from AWS Marketplace.
