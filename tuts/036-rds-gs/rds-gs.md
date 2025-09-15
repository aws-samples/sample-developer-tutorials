# Creating an Amazon RDS DB instance using the AWS CLI

This tutorial guides you through the process of creating and managing an Amazon RDS database instance using the AWS Command Line Interface (AWS CLI). You'll learn how to set up the necessary networking components, create a MySQL database instance, connect to it, and clean up resources when you're done.

## Topics

- [Prerequisites](#prerequisites)
- [Set up networking components](#set-up-networking-components)
- [Create a DB subnet group](#create-a-db-subnet-group)
- [Create a DB instance](#create-a-db-instance)
- [Connect to your DB instance](#connect-to-your-db-instance)
- [Clean up resources](#clean-up-resources)
- [Going to production](#going-to-production)
- [Next steps](#next-steps)

## Prerequisites

Before you begin this tutorial, make sure you have the following:

1. The AWS CLI. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
2. Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
3. Basic familiarity with relational databases and MySQL.
4. Sufficient permissions to create and manage RDS resources in your AWS account.
5. A default VPC in your AWS account, or an existing VPC with at least two subnets in different Availability Zones.

**Time to complete:** Approximately 45 minutes

**Cost:** The resources created in this tutorial will cost approximately $0.04 per hour ($30 per month) if left running. The db.t3.micro instance used in this tutorial is eligible for the AWS Free Tier for 12 months for new AWS accounts. Following the cleanup instructions at the end of the tutorial will help you avoid ongoing charges.

## Set up networking components

Amazon RDS requires specific networking components to ensure your database is secure and accessible. In this section, you'll check for a default VPC and create security groups for your database and bastion host.

**Check for a default VPC**

First, check if you have a default VPC available in your AWS account. The default VPC comes with subnets across multiple Availability Zones, which is required for RDS.

```bash
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text)
echo "Default VPC ID: $VPC_ID"
```

If this command returns a VPC ID, you have a default VPC and can proceed. If it returns "None" or an error, you'll need to create a VPC with subnets in at least two Availability Zones before continuing.

**Create security groups for database and bastion host access**

Create two security groups: one for the RDS database and one for the EC2 bastion host that will be used to connect to the database.

```bash
# Create security group for RDS database
RDS_SECURITY_GROUP_NAME="rds-db-sg"
RDS_SECURITY_GROUP_ID=$(aws ec2 create-security-group \
    --group-name $RDS_SECURITY_GROUP_NAME \
    --description "Security group for RDS database access" \
    --vpc-id $VPC_ID \
    --query "GroupId" --output text)
echo "Created RDS security group: $RDS_SECURITY_GROUP_ID"

# Create security group for EC2 bastion host
EC2_SECURITY_GROUP_NAME="ec2-bastion-sg"
EC2_SECURITY_GROUP_ID=$(aws ec2 create-security-group \
    --group-name $EC2_SECURITY_GROUP_NAME \
    --description "Security group for EC2 bastion host" \
    --vpc-id $VPC_ID \
    --query "GroupId" --output text)
echo "Created EC2 security group: $EC2_SECURITY_GROUP_ID"
```

**Configure security group rules**

Add rules to allow SSH access to the bastion host from your IP and MySQL access from the bastion host to the database.

```bash
# Get your current IP address
MY_IP=$(curl -s https://checkip.amazonaws.com)
echo "Your current IP address: $MY_IP"

# Allow SSH access to bastion host from your IP
aws ec2 authorize-security-group-ingress \
    --group-id $EC2_SECURITY_GROUP_ID \
    --protocol tcp \
    --port 22 \
    --cidr "${MY_IP}/32"
echo "Added SSH rule to EC2 security group from ${MY_IP}/32"
```

The SSH rule above allows access only from your current IP address (${MY_IP}). If your IP address changes (common
with home internet connections), you won't be able to SSH to the bastion host.

If you encounter SSH connection timeouts later, check your current IP and update the security group:

```bash
# Check your current IP
CURRENT_IP=$(curl -s https://checkip.amazonaws.com)
echo "Current IP: $CURRENT_IP"

# Add your current IP to the security group if it changed
aws ec2 authorize-security-group-ingress \
    --group-id $EC2_SECURITY_GROUP_ID \
    --protocol tcp \
    --port 22 \
    --cidr "${CURRENT_IP}/32"
echo "Added SSH rule for current IP: ${CURRENT_IP}/32"
```

```bash
# Allow MySQL access from bastion host to RDS
aws ec2 authorize-security-group-ingress \
    --group-id $RDS_SECURITY_GROUP_ID \
    --protocol tcp \
    --port 3306 \
    --source-group $EC2_SECURITY_GROUP_ID
echo "Added MySQL rule to RDS security group from EC2 security group"

# Verify security group rules were created correctly
echo "Verifying security group configuration..."
aws ec2 describe-security-groups --group-ids $RDS_SECURITY_GROUP_ID --query "SecurityGroups[0].IpPermissions" --output table
aws ec2 describe-security-groups --group-ids $EC2_SECURITY_GROUP_ID --query "SecurityGroups[0].IpPermissions" --output table
```

## Create a DB subnet group

A DB subnet group is a collection of subnets that you can use for your RDS database. The subnet group must include subnets in at least two different Availability Zones.

**Get subnet IDs from your VPC**

First, retrieve the subnet IDs from your VPC:

```bash
SUBNET_IDS=$(aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query "Subnets[*].SubnetId" \
    --output text)
echo "Available subnets: $SUBNET_IDS"
```

**Create the DB subnet group**

Now, create a DB subnet group using at least two of the subnets:

```bash
DB_SUBNET_GROUP_NAME="mydbsubnetgroup"
# Extract individual subnet IDs from the tab-separated output
SUBNET1=$(echo "$SUBNET_IDS" | awk '{print $1}')
SUBNET2=$(echo "$SUBNET_IDS" | awk '{print $2}')

# Verify the subnet IDs were extracted correctly
echo "SUBNET1: $SUBNET1"
echo "SUBNET2: $SUBNET2"

# Create the DB subnet group
aws rds create-db-subnet-group \
    --db-subnet-group-name $DB_SUBNET_GROUP_NAME \
    --db-subnet-group-description "Subnet group for RDS tutorial" \
    --subnet-ids $SUBNET1 $SUBNET2
echo "Created DB subnet group: $DB_SUBNET_GROUP_NAME"
```

## Create a DB instance

Now that you have set up the networking components, you can create your RDS DB instance. In this tutorial, we'll create a MySQL database instance.

**Create the DB instance**

The following command creates a MySQL database instance with the specified configuration. This process typically takes 5-10 minutes to complete.

```bash
DB_INSTANCE_ID="mydb-tutorial"
aws rds create-db-instance \
    --db-instance-identifier $DB_INSTANCE_ID \
    --db-instance-class db.t3.micro \
    --engine mysql \
    --master-username adminuser \
    --manage-master-user-password \
    --allocated-storage 20 \
    --vpc-security-group-ids $RDS_SECURITY_GROUP_ID \
    --db-subnet-group-name $DB_SUBNET_GROUP_NAME \
    --backup-retention-period 7 \
    --no-publicly-accessible \
    --no-multi-az
echo "DB instance creation initiated: $DB_INSTANCE_ID"
```

The `--manage-master-user-password` parameter tells RDS to generate a secure password and store it in AWS Secrets Manager. This is more secure than specifying a password directly in the command.

**Wait for the DB instance to become available**

Creating an RDS instance takes several minutes. You can use the following command to wait until the instance is available:

```bash
echo "Waiting for DB instance to become available (this may take 5-10 minutes)..."
aws rds wait db-instance-available --db-instance-identifier $DB_INSTANCE_ID
echo 'DB instance is now available!'
```

## Connect to your DB instance

Since this tutorial creates a private RDS instance (using `--no-publicly-accessible`), you can't connect directly from your local machine. You'll need to create an EC2 bastion host within the same VPC to connect to the database.

**Create an SSH key pair**

First, create a new SSH key pair for connecting to the bastion host:

```bash
KEY_NAME="rds-tutorial-key"
aws ec2 create-key-pair --key-name $KEY_NAME --query 'KeyMaterial' --output text > ${KEY_NAME}.pem
chmod 400 ${KEY_NAME}.pem
echo "Created SSH key pair: $KEY_NAME"
```

**Launch an EC2 bastion host**

Create an EC2 instance that will serve as a bastion host to connect to your RDS instance:

```bash
# Get the first subnet ID for launching the EC2 instance
SUBNET_ID=$(echo "$SUBNET_IDS" | awk '{print $1}')
echo "Using subnet: $SUBNET_ID for EC2 instance"

# Get the latest Amazon Linux 2 AMI
AMI_ID=$(aws ec2 describe-images \
    --owners amazon \
    --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" \
    --query "Images | sort_by(@, &CreationDate) | [-1].ImageId" \
    --output text)
echo "Using AMI: $AMI_ID"

# Create user data script to install MySQL client
USER_DATA=$(cat << 'EOF'
#!/bin/bash
yum update -y
yum install mysql -y
echo "MySQL client installation completed" > /tmp/mysql-install.log
EOF
)

# Launch the EC2 instance
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --count 1 \
    --instance-type t2.micro \
    --key-name $KEY_NAME \
    --security-group-ids $EC2_SECURITY_GROUP_ID \
    --subnet-id $SUBNET_ID \
    --associate-public-ip-address \
    --user-data "$USER_DATA" \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=RDS-Bastion-Host}]' \
    --query "Instances[0].InstanceId" \
    --output text)
echo "Launched EC2 bastion host: $INSTANCE_ID"
```

**Wait for the bastion host to be ready**

Wait for the EC2 instance to be running and get its public IP address:

```bash
echo "Waiting for EC2 instance to be running..."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --query "Reservations[0].Instances[0].PublicIpAddress" \
    --output text)
echo "EC2 bastion host public IP: $PUBLIC_IP"

echo "Waiting for MySQL client installation to complete (120 seconds)..."
sleep 120
```

**Get RDS connection information**

Retrieve the endpoint, port, and username for your DB instance:

```bash
CONNECTION_INFO=$(aws rds describe-db-instances \
    --db-instance-identifier $DB_INSTANCE_ID \
    --query 'DBInstances[0].[Endpoint.Address,Endpoint.Port,MasterUsername]' \
    --output text)

DB_ENDPOINT=$(echo "$CONNECTION_INFO" | awk '{print $1}')
DB_PORT=$(echo "$CONNECTION_INFO" | awk '{print $2}')
DB_USER=$(echo "$CONNECTION_INFO" | awk '{print $3}')

echo "DB Endpoint: $DB_ENDPOINT"
echo "DB Port: $DB_PORT"
echo "DB Username: $DB_USER"
```

**Retrieve the auto-generated password**

Get the password from AWS Secrets Manager:

```bash
SECRET_ARN=$(aws rds describe-db-instances \
    --db-instance-identifier $DB_INSTANCE_ID \
    --query 'DBInstances[0].MasterUserSecret.SecretArn' \
    --output text)

DB_PASSWORD=$(aws secretsmanager get-secret-value \
    --secret-id $SECRET_ARN \
    --query 'SecretString' \
    --output text | python3 -c "import sys, json; print(json.load(sys.stdin)['password'])")

echo "Password retrieved from Secrets Manager"
echo "Database password: $DB_PASSWORD"
```

**Resource Verification**
```bash
DB_PASSWORD=$(aws secretsmanager get-secret-value --secret-id $(aws rds describe-db-instances --db-instance-identifier mydb-tutorial --query 'DBInstances[0].MasterUserSecret.SecretArn' --output text) --query 'SecretString' --output text | python3 -c "import sys, json; print(json.load(sys.stdin)['password'])")

echo "Password retrieved from Secrets Manager"
echo "Database password: $DB_PASSWORD"

# ADD RESOURCE VERIFICATION HERE
echo ""
echo "=== Verifying All Resources Are Ready ==="
echo "✓ VPC: $VPC_ID"
echo "✓ RDS Security Group: $RDS_SECURITY_GROUP_ID"
echo "✓ EC2 Security Group: $EC2_SECURITY_GROUP_ID"
echo "✓ DB Subnet Group: $DB_SUBNET_GROUP_NAME"
echo "✓ RDS Instance: $DB_INSTANCE_ID"
echo "✓ EC2 Instance: $INSTANCE_ID"
echo "✓ Bastion Host IP: $PUBLIC_IP"
echo "✓ DB Endpoint: $DB_ENDPOINT"
echo ""
```

**Connect to the database**

Follow these steps to connect to your RDS instance:

**Step 1: Connect to the bastion host**
```bash
ssh -i ${KEY_NAME}.pem ec2-user@$PUBLIC_IP
```

**Step 2: From the bastion host, connect to MySQL**
```bash
mysql -h $DB_ENDPOINT -P $DB_PORT -u $DB_USER -p
```

**Step 3: Enter the password when prompted**

```
Enter password: [paste the password from $DB_PASSWORD]
```

You should see the MySQL prompt:

```
mysql>
```

**Step 4: Test the connection with sample commands**
```sql
   -- Show available databases
   SHOW DATABASES;

   -- Create a test database
   CREATE DATABASE testdb;

   -- Use the test database
   USE testdb;

   -- Create a test table
   CREATE TABLE users (
       id INT AUTO_INCREMENT PRIMARY KEY,
       name VARCHAR(50) NOT NULL,
       email VARCHAR(100),
       created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
   );

   -- Insert some test data
   INSERT INTO users (name, email) VALUES
       ('Alice Johnson', 'alice@example.com'),
       ('Bob Smith', 'bob@example.com'),
       ('Carol Davis', 'carol@example.com');

   -- Query the data
   SELECT * FROM users;

   -- Show table structure
   DESCRIBE users;

   -- Exit MySQL
   EXIT;
```

**Step 5: Exit the SSH session**
```bash
exit
```

## Troubleshooting Connection Issues

If you encounter connection errors like "ERROR 2003 (HY000): Can't connect to MySQL server", check the following:

1. **Verify security group rules**:
 ```bash
  # Check if RDS security group allows MySQL access from EC2 security group
  aws ec2 describe-security-groups --group-ids $RDS_SECURITY_GROUP_ID --query "SecurityGroups[0].IpPermissions"
```

2. **If the rule is missing, add it**:
```bash
  aws ec2 authorize-security-group-ingress \
      --group-id $RDS_SECURITY_GROUP_ID \
      --protocol tcp \
      --port 3306 \
      --source-group $EC2_SECURITY_GROUP_ID
```

3. **Verify RDS instance is available**:
```bash
  aws rds describe-db-instances --db-instance-identifier $DB_INSTANCE_ID --query "DBInstances[0].DBInstanceStatus"
```

## Clean up resources

When you're done with the tutorial, you should clean up all resources to avoid incurring charges. Make sure to clean up resources in the correct order due to dependencies.

**Terminate the EC2 bastion host**

First, terminate the EC2 instance:

```bash
echo "Terminating EC2 instance $INSTANCE_ID..."
aws ec2 terminate-instances --instance-ids $INSTANCE_ID
aws ec2 wait instance-terminated --instance-ids $INSTANCE_ID
echo "EC2 instance terminated"
```

**Delete the SSH key pair**

Delete the SSH key pair and local key file:

```bash
echo "Deleting SSH key pair $KEY_NAME..."
aws ec2 delete-key-pair --key-name $KEY_NAME
rm -f ${KEY_NAME}.pem
echo "SSH key pair deleted"
```

**Delete the DB instance**

Delete the RDS DB instance:

```bash
echo "Deleting DB instance $DB_INSTANCE_ID..."
aws rds delete-db-instance \
    --db-instance-identifier $DB_INSTANCE_ID \
    --skip-final-snapshot
echo "Waiting for DB instance to be deleted (this may take several minutes)..."
aws rds wait db-instance-deleted --db-instance-identifier $DB_INSTANCE_ID
echo "DB instance deleted"
```

**Delete the DB subnet group**

After the DB instance is deleted, delete the DB subnet group:

```bash
echo "Deleting DB subnet group $DB_SUBNET_GROUP_NAME..."
aws rds delete-db-subnet-group --db-subnet-group-name $DB_SUBNET_GROUP_NAME
echo "DB subnet group deleted"
```

**Delete the security groups**

Finally, delete both security groups:

```bash
echo "Deleting RDS security group $RDS_SECURITY_GROUP_ID..."
aws ec2 delete-security-group --group-id $RDS_SECURITY_GROUP_ID

echo "Deleting EC2 security group $EC2_SECURITY_GROUP_ID..."
aws ec2 delete-security-group --group-id $EC2_SECURITY_GROUP_ID

echo "Security groups deleted"
```

**Verify cleanup**

You can verify that all resources have been cleaned up:

```bash
echo "Verifying cleanup..."

# Check if DB instance is gone
aws rds describe-db-instances --db-instance-identifier $DB_INSTANCE_ID 2>/dev/null || echo "✓ DB instance deleted"

# Check if EC2 instance is terminated
INSTANCE_STATE=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[0].Instances[0].State.Name" --output text 2>/dev/null)
if [ "$INSTANCE_STATE" = "terminated" ]; then
    echo "✓ EC2 instance terminated"
fi

# Check if security groups are gone
aws ec2 describe-security-groups --group-ids $RDS_SECURITY_GROUP_ID 2>/dev/null || echo "✓ RDS security group deleted"
aws ec2 describe-security-groups --group-ids $EC2_SECURITY_GROUP_ID 2>/dev/null || echo "✓ EC2 security group deleted"

echo "Cleanup completed successfully!"
```

## Going to production

This tutorial demonstrates how to create a basic RDS instance for learning purposes. For production environments, consider the following additional configurations:

### Security Enhancements

1. **Enable encryption at rest**:
   ```bash
   --storage-encrypted
   ```

2. **Enable IAM database authentication**:
   ```bash
   --enable-iam-database-authentication
   ```

3. **Use VPC endpoints** for Secrets Manager to keep traffic within the AWS network.

4. **Implement least privilege access** with specific IAM roles and policies.

5. **Use AWS Systems Manager Session Manager** instead of SSH for bastion host access.

### High Availability and Reliability

1. **Enable Multi-AZ deployment** for automatic failover:
   ```bash
   --multi-az
   ```

2. **Create read replicas** for scaling read operations:
   ```bash
   aws rds create-db-instance-read-replica \
       --db-instance-identifier mydb-replica \
       --source-db-instance-identifier mydb
   ```

3. **Implement automated backups** with appropriate retention periods.

### Performance and Scaling

1. **Choose an appropriate instance class** based on your workload requirements.

2. **Enable storage autoscaling**:
   ```bash
   --max-allocated-storage 1000
   ```

3. **Create custom parameter groups** optimized for your workload.

4. **Use connection pooling** to manage database connections efficiently.

### Monitoring and Operations

1. **Set up CloudWatch alarms** for key metrics like CPU, memory, and storage.

2. **Configure maintenance windows** to minimize impact on your application.

3. **Implement comprehensive logging** with CloudWatch Logs.

4. **Set up automated patching** during maintenance windows.

### Network Security

1. **Use private subnets** for RDS instances (as demonstrated in this tutorial).

2. **Implement network ACLs** for additional network-level security.

3. **Use AWS PrivateLink** for secure connections to AWS services.

For more information on building production-ready database environments, refer to:
- [Amazon RDS Best Practices](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_BestPractices.html)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [AWS Security Best Practices](https://aws.amazon.com/architecture/security-identity-compliance/)

## Next steps

Now that you've learned how to create and manage an RDS DB instance using the AWS CLI, you might want to explore these related topics:

- [Working with automated backups](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_WorkingWithAutomatedBackups.html)
- [Creating a DB snapshot](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_CreateSnapshot.html)
- [Setting up Multi-AZ deployments](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.MultiAZ.html)
- [Monitoring RDS metrics with CloudWatch](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/MonitoringOverview.html)
- [Using parameter groups](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_WorkingWithParamGroups.html)
- [Implementing connection pooling](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/rds-proxy.html)
- [Setting up read replicas](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_ReadRepl.html)
