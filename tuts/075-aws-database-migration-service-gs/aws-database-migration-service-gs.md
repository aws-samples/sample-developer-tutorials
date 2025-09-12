# Getting started with AWS Database Migration Service using the AWS CLI

This tutorial guides you through the process of migrating data from a MariaDB database to a PostgreSQL database using AWS Database Migration Service (AWS DMS) with the AWS Command Line Interface (AWS CLI). You'll learn how to set up the necessary infrastructure, create and configure a replication instance, and perform a database migration.

## Prerequisites

Before you begin this tutorial, make sure you have the following:

1. The AWS CLI. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
2. Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
3. Basic familiarity with command line interfaces and database concepts.
4. Sufficient permissions to create and manage AWS resources including VPC, EC2, RDS, and DMS resources.

This tutorial creates resources that incur costs in your AWS account. The estimated cost for running this tutorial for one hour is approximately $0.67 USD, depending on the AWS Region you use. If you complete the entire tutorial including the 45-minute database population step, the total cost may be around $2-3 USD. Make sure to follow the cleanup steps at the end of the tutorial to avoid ongoing charges.

Before you start, set the AWS_REGION environment variable if it's not already set:

```
[ -z "$AWS_REGION" ] && AWS_REGION=$(aws configure get region)
echo "Using AWS region: $AWS_REGION"
```

## Tutorial Options

This tutorial can be completed in two ways:

### Option 1: Automated Script (Recommended for Quick Setup)

For a faster setup experience, you can use the provided automated script that handles all the steps in this tutorial:

```bash
chmod +x 2-cli-script-v5.sh
./2-cli-script-v5.sh
```

> **Note**: The v5 script includes important fixes for instance type selection and VPC limit handling that were identified during testing. It automatically handles common issues like VPC limits and instance type availability that might cause the manual steps to fail.

The automated script includes several enhancements:
- **VPC limit handling**: Automatically checks your VPC limits and offers to use an existing VPC if you've reached the limit
- **Instance type validation**: Automatically selects an appropriate EC2 instance type based on availability in your chosen availability zone
- **Interactive prompts**: Guides you through optional steps like data population and migration testing
- **Comprehensive cleanup**: Properly cleans up all resources at the end
- **Error handling**: Includes robust error checking and status validation
- **Logging**: Creates detailed logs of all operations for troubleshooting

### Option 2: Manual Step-by-Step (Recommended for Learning)

Follow the detailed steps below to understand each component of the migration process. This approach is better for learning how AWS DMS works and understanding each step.

## Create a VPC for your migration resources

First, you'll create a Virtual Private Cloud (VPC) to contain all the resources needed for the database migration. This provides a secure, isolated environment for your databases and migration components.

> **Note**: AWS accounts have a default limit of 5 VPCs per region. If you've reached this limit, you can either use an existing VPC or request a limit increase through the AWS Service Quotas console. The automated script handles this scenario automatically by offering to use an existing VPC.

**Create a VPC with subnets**

The following command creates a VPC with a CIDR block of 10.0.1.0/24:

```
aws ec2 create-vpc --cidr-block 10.0.1.0/24 --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=DMSVPC}]'
```

The output will include the VPC ID, which you'll need for subsequent commands. Store it in a variable for easy reference:

```
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=DMSVPC" --query "Vpcs[0].VpcId" --output text)
echo "VPC ID: $VPC_ID"
```

Now, enable DNS hostnames for the VPC:

```
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames '{"Value":true}'
```

Next, create subnets in two availability zones to ensure high availability:

```
# Create public subnets
aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.1.0/26 --availability-zone ${AWS_REGION}a --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=DMSVPC-public-subnet-1}]'
aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.1.64/26 --availability-zone ${AWS_REGION}b --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=DMSVPC-public-subnet-2}]'

# Create private subnets
aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.1.128/26 --availability-zone ${AWS_REGION}a --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=DMSVPC-private-subnet-1}]'
aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.1.192/26 --availability-zone ${AWS_REGION}b --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=DMSVPC-private-subnet-2}]'
```

Store the subnet IDs in variables:

```
PUBLIC_SUBNET_1_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=DMSVPC-public-subnet-1" --query "Subnets[0].SubnetId" --output text)
PUBLIC_SUBNET_2_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=DMSVPC-public-subnet-2" --query "Subnets[0].SubnetId" --output text)
echo "Public Subnet 1: $PUBLIC_SUBNET_1_ID"
echo "Public Subnet 2: $PUBLIC_SUBNET_2_ID"
```

**Create an internet gateway and configure routing**

To allow your resources to access the internet, create and attach an internet gateway:

```
aws ec2 create-internet-gateway --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=DMSVPC-igw}]'
IGW_ID=$(aws ec2 describe-internet-gateways --filters "Name=tag:Name,Values=DMSVPC-igw" --query "InternetGateways[0].InternetGatewayId" --output text)
aws ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
echo "Internet Gateway: $IGW_ID"
```

Create a route table and add a route to the internet gateway:

```
aws ec2 create-route-table --vpc-id $VPC_ID --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=DMSVPC-public-rt}]'
PUBLIC_RT_ID=$(aws ec2 describe-route-tables --filters "Name=tag:Name,Values=DMSVPC-public-rt" --query "RouteTables[0].RouteTableId" --output text)
aws ec2 create-route --route-table-id $PUBLIC_RT_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID
echo "Route Table: $PUBLIC_RT_ID"
```

Associate the public subnets with the route table:

```
aws ec2 associate-route-table --route-table-id $PUBLIC_RT_ID --subnet-id $PUBLIC_SUBNET_1_ID
aws ec2 associate-route-table --route-table-id $PUBLIC_RT_ID --subnet-id $PUBLIC_SUBNET_2_ID
```

**Configure security groups**

Configure the default security group to allow database traffic:

```
SG_ID=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" "Name=group-name,Values=default" --query "SecurityGroups[0].GroupId" --output text)
echo "Security Group: $SG_ID"

# Get your current IP address for more secure SSH access
MY_IP=$(curl -s https://checkip.amazonaws.com)
echo "Your IP address: $MY_IP"

# Add security group rules
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 3306 --cidr 10.0.1.0/24
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 5432 --cidr 10.0.1.0/24
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 22 --cidr $MY_IP/32
```

## Create database parameter groups

Before creating your source and target databases, you need to create parameter groups to configure them properly for replication.

**Create a MariaDB parameter group**

```
aws rds create-db-parameter-group \
    --db-parameter-group-name dms-mariadb-parameters \
    --db-parameter-group-family mariadb10.6 \
    --description "Group for specifying binary log settings for replication"
```

Configure the MariaDB parameters for binary logging:

```
aws rds modify-db-parameter-group \
    --db-parameter-group-name dms-mariadb-parameters \
    --parameters "ParameterName=binlog_checksum,ParameterValue=NONE,ApplyMethod=immediate" \
                 "ParameterName=binlog_format,ParameterValue=ROW,ApplyMethod=immediate"
```

**Create a PostgreSQL parameter group**

```
aws rds create-db-parameter-group \
    --db-parameter-group-name dms-postgresql-parameters \
    --db-parameter-group-family postgres16 \
    --description "Group for specifying role setting for replication"
```

Configure the PostgreSQL parameters for replication:

```
aws rds modify-db-parameter-group \
    --db-parameter-group-name dms-postgresql-parameters \
    --parameters "ParameterName=session_replication_role,ParameterValue=replica,ApplyMethod=immediate"
```

**Create a DB subnet group**

Create a DB subnet group that includes subnets from your VPC:

```
aws rds create-db-subnet-group \
    --db-subnet-group-name dms-db-subnet-group \
    --db-subnet-group-description "DB subnet group for DMS tutorial" \
    --subnet-ids "$PUBLIC_SUBNET_1_ID" "$PUBLIC_SUBNET_2_ID"
```

Verify the DB subnet group was created successfully:

```
aws rds describe-db-subnet-groups --db-subnet-group-name dms-db-subnet-group
```
## Create source and target databases

Now you'll create the source MariaDB database and the target PostgreSQL database.

**Generate a secure password**

First, let's generate a secure password and store it in AWS Secrets Manager:

```
# Generate a secure password
DB_PASSWORD=$(openssl rand -base64 16)
echo "Generated a secure password for database access"

# Store the password in Secrets Manager
SECRET_NAME="dms-tutorial-db-password"
aws secretsmanager create-secret --name $SECRET_NAME --secret-string $DB_PASSWORD
echo "Password stored in Secrets Manager with name: $SECRET_NAME"
```

**Create the source MariaDB database**

```
aws rds create-db-instance \
    --db-instance-identifier dms-mariadb \
    --engine mariadb \
    --engine-version 10.6.14 \
    --db-instance-class db.t3.medium \
    --allocated-storage 20 \
    --master-username admin \
    --master-user-password $DB_PASSWORD \
    --vpc-security-group-ids $SG_ID \
    --availability-zone ${AWS_REGION}a \
    --db-subnet-group-name dms-db-subnet-group \
    --db-parameter-group-name dms-mariadb-parameters \
    --db-name dms_sample \
    --backup-retention-period 1 \
    --no-auto-minor-version-upgrade \
    --storage-encrypted \
    --no-publicly-accessible
```

The output will show details about the database instance being created. Wait for the MariaDB instance to become available:

```
echo "Waiting for MariaDB instance to become available. This may take several minutes..."
aws rds wait db-instance-available --db-instance-identifier dms-mariadb
echo "MariaDB instance is now available"
```

**Create the target PostgreSQL database**

```
aws rds create-db-instance \
    --db-instance-identifier dms-postgresql \
    --engine postgres \
    --engine-version 16.1 \
    --db-instance-class db.t3.medium \
    --allocated-storage 20 \
    --master-username postgres \
    --master-user-password $DB_PASSWORD \
    --vpc-security-group-ids $SG_ID \
    --availability-zone ${AWS_REGION}a \
    --db-subnet-group-name dms-db-subnet-group \
    --db-parameter-group-name dms-postgresql-parameters \
    --db-name dms_sample \
    --backup-retention-period 0 \
    --no-auto-minor-version-upgrade \
    --storage-encrypted \
    --no-publicly-accessible
```

Wait for the PostgreSQL instance to become available:

```
echo "Waiting for PostgreSQL instance to become available. This may take several minutes..."
aws rds wait db-instance-available --db-instance-identifier dms-postgresql
echo "PostgreSQL instance is now available"
```

## Create an EC2 client instance

You'll need an EC2 instance to populate your source database and test the migration.

**Launch an EC2 instance**

First, create a key pair to securely connect to your instance:

```
KEY_NAME="DMSKeyPair"
aws ec2 create-key-pair --key-name $KEY_NAME --query 'KeyMaterial' --output text > ${KEY_NAME}.pem
chmod 400 ${KEY_NAME}.pem
echo "Key pair created and saved to ${KEY_NAME}.pem"
```

Now, find the latest Amazon Linux 2023 AMI:

```
AMI_ID=$(aws ec2 describe-images \
    --owners amazon \
    --filters "Name=name,Values=al2023-ami-2023*-x86_64" "Name=state,Values=available" \
    --query "sort_by(Images, &CreationDate)[-1].ImageId" \
    --output text)
echo "Using AMI: $AMI_ID"
```

Launch an EC2 instance:

> **Note**: This tutorial uses t3.medium as the instance type. If this instance type is not available in your chosen availability zone, you may need to try alternative types like t3.large, t2.medium, t2.large, m5.large, or m5.xlarge. The automated script handles this automatically by checking availability and selecting an appropriate type.

```
aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type t3.medium \
    --key-name $KEY_NAME \
    --subnet-id $PUBLIC_SUBNET_1_ID \
    --security-group-ids $SG_ID \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=DMSClient}]' \
    --associate-public-ip-address
```

Wait for the instance to be running:

```
EC2_INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=DMSClient" --query 'Reservations[0].Instances[0].InstanceId' --output text)
echo "EC2 instance ID: $EC2_INSTANCE_ID"
echo "Waiting for EC2 instance to be running..."
aws ec2 wait instance-running --instance-ids $EC2_INSTANCE_ID
echo "EC2 instance is now running"
```

## Populate the source database

Now you'll populate your source database with sample data.

**Get database endpoints**

First, retrieve the endpoints for your databases:

```
MARIADB_ENDPOINT=$(aws rds describe-db-instances \
    --db-instance-identifier dms-mariadb \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text)
echo "MariaDB endpoint: $MARIADB_ENDPOINT"

POSTGRES_ENDPOINT=$(aws rds describe-db-instances \
    --db-instance-identifier dms-postgresql \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text)
echo "PostgreSQL endpoint: $POSTGRES_ENDPOINT"
```

**Connect to the EC2 instance**

Get the public IP address of your EC2 instance:

```
EC2_PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids $EC2_INSTANCE_ID \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)
echo "EC2 public IP: $EC2_PUBLIC_IP"
```

Now you need to connect to your EC2 instance using SSH. Open a new terminal window and run:

```
ssh -i DMSKeyPair.pem ec2-user@$EC2_PUBLIC_IP
```

Once connected, install the required software and download the sample database scripts:

```
sudo yum install -y git
sudo dnf install -y mariadb105
sudo dnf install -y postgresql15
git clone https://github.com/aws-samples/aws-database-migration-samples.git
cd aws-database-migration-samples/mysql/sampledb/v1/
```

Retrieve the database password from Secrets Manager:

```
DB_PASSWORD=$(aws secretsmanager get-secret-value --secret-id dms-tutorial-db-password --query 'SecretString' --output text)
```

Populate the source database with the sample data:

```
mysql -h $MARIADB_ENDPOINT -P 3306 -u admin -p dms_sample < ~/aws-database-migration-samples/mysql/sampledb/v1/install-rds.sql
```

When prompted, enter the password you retrieved from Secrets Manager.

This script will take approximately 45 minutes to complete. During this time, you can proceed with setting up the DMS replication infrastructure in parallel (next steps). Just make sure the database population is complete before starting the migration task.
## Create a replication instance

While the source database is being populated, you can set up the AWS DMS replication infrastructure.

**Create a replication subnet group**

```
aws dms create-replication-subnet-group \
    --replication-subnet-group-identifier dms-subnet-group \
    --replication-subnet-group-description "DMS subnet group" \
    --subnet-ids "$PUBLIC_SUBNET_1_ID" "$PUBLIC_SUBNET_2_ID"
```

The output will confirm that the replication subnet group was created:

```
{
    "ReplicationSubnetGroup": {
        "ReplicationSubnetGroupIdentifier": "dms-subnet-group",
        "ReplicationSubnetGroupDescription": "DMS subnet group",
        "VpcId": "vpc-abcd1234",
        "SubnetGroupStatus": "Complete",
        "Subnets": [
            {
                "SubnetIdentifier": "subnet-abcd1234",
                "SubnetAvailabilityZone": {
                    "Name": "us-east-1a"
                },
                "SubnetStatus": "Active"
            },
            {
                "SubnetIdentifier": "subnet-efgh5678",
                "SubnetAvailabilityZone": {
                    "Name": "us-east-1b"
                },
                "SubnetStatus": "Active"
            }
        ]
    }
}
```

**Create a replication instance**

```
aws dms create-replication-instance \
    --replication-instance-identifier DMS-instance \
    --replication-instance-class dms.t3.medium \
    --allocated-storage 50 \
    --vpc-security-group-ids $SG_ID \
    --replication-subnet-group-identifier dms-subnet-group \
    --availability-zone ${AWS_REGION}a \
    --no-publicly-accessible \
    --kms-key-id alias/aws/dms
```

Wait for the replication instance to be available:

```
echo "Waiting for DMS replication instance to be available. This may take several minutes..."
while true; do
    STATUS=$(aws dms describe-replication-instances \
        --filters Name=replication-instance-id,Values="DMS-instance" \
        --query 'ReplicationInstances[0].Status' \
        --output text)

    if [ "$STATUS" = "available" ]; then
        echo "DMS replication instance is now available"
        break
    fi

    echo "Current status: $STATUS. Waiting 30 seconds..."
    sleep 30
done
```

Get the replication instance ARN:

```
DMS_INSTANCE_ARN=$(aws dms describe-replication-instances \
    --filters Name=replication-instance-id,Values="DMS-instance" \
    --query 'ReplicationInstances[0].ReplicationInstanceArn' \
    --output text)
echo "DMS replication instance ARN: $DMS_INSTANCE_ARN"
```

## Create source and target endpoints

Now, create endpoints that connect to your source and target databases.

**Create the source endpoint**

```
aws dms create-endpoint \
    --endpoint-identifier dms-mysql-source \
    --endpoint-type source \
    --engine-name mysql \
    --username admin \
    --password $DB_PASSWORD \
    --server-name $MARIADB_ENDPOINT \
    --port 3306 \
    --database-name dms_sample
```

The output will include details about the endpoint:

```
{
    "Endpoint": {
        "EndpointIdentifier": "dms-mysql-source",
        "EndpointType": "source",
        "EngineName": "mysql",
        "Username": "admin",
        "ServerName": "dms-mariadb.abcdefg12345.us-east-1.rds.amazonaws.com",
        "Port": 3306,
        "DatabaseName": "dms_sample",
        "Status": "active",
        "KmsKeyId": "arn:aws:kms:us-east-1:123456789012:key/abcd1234-abcd-1234-abcd-1234abcd1234",
        "EndpointArn": "arn:aws:dms:us-east-1:123456789012:endpoint:ABCDEFGHIJKLMNOPQRSTUVWXYZ",
        "SslMode": "none"
    }
}
```

Store the source endpoint ARN:

```
SOURCE_ENDPOINT_ARN=$(aws dms describe-endpoints --filters Name=endpoint-id,Values=dms-mysql-source --query 'Endpoints[0].EndpointArn' --output text)
echo "Source endpoint ARN: $SOURCE_ENDPOINT_ARN"
```

**Create the target endpoint**

```
aws dms create-endpoint \
    --endpoint-identifier dms-postgresql-target \
    --endpoint-type target \
    --engine-name postgres \
    --username postgres \
    --password $DB_PASSWORD \
    --server-name $POSTGRES_ENDPOINT \
    --port 5432 \
    --database-name dms_sample
```

Store the target endpoint ARN:

```
TARGET_ENDPOINT_ARN=$(aws dms describe-endpoints --filters Name=endpoint-id,Values=dms-postgresql-target --query 'Endpoints[0].EndpointArn' --output text)
echo "Target endpoint ARN: $TARGET_ENDPOINT_ARN"
```

**Test the endpoint connections**

Test the connection to the source endpoint:

```
aws dms test-connection \
    --replication-instance-arn $DMS_INSTANCE_ARN \
    --endpoint-arn $SOURCE_ENDPOINT_ARN
```

Wait for the test connection to complete:

```
echo "Waiting for source endpoint connection test to complete..."
while true; do
    STATUS=$(aws dms describe-connections \
        --filters Name=endpoint-arn,Values=$SOURCE_ENDPOINT_ARN \
        --query 'Connections[0].Status' \
        --output text)

    if [ "$STATUS" = "successful" ]; then
        echo "Source endpoint connection test successful"
        break
    elif [ "$STATUS" = "failed" ]; then
        echo "Source endpoint connection test failed"
        exit 1
    fi

    echo "Current status: $STATUS. Waiting 10 seconds..."
    sleep 10
done
```

Test the connection to the target endpoint:

```
aws dms test-connection \
    --replication-instance-arn $DMS_INSTANCE_ARN \
    --endpoint-arn $TARGET_ENDPOINT_ARN
```

Wait for the test connection to complete:

```
echo "Waiting for target endpoint connection test to complete..."
while true; do
    STATUS=$(aws dms describe-connections \
        --filters Name=endpoint-arn,Values=$TARGET_ENDPOINT_ARN \
        --query 'Connections[0].Status' \
        --output text)

    if [ "$STATUS" = "successful" ]; then
        echo "Target endpoint connection test successful"
        break
    elif [ "$STATUS" = "failed" ]; then
        echo "Target endpoint connection test failed"
        exit 1
    fi

    echo "Current status: $STATUS. Waiting 10 seconds..."
    sleep 10
done
```
## Create and start a migration task

Now that you have set up the replication instance and endpoints, you can create a migration task. Before proceeding, make sure the source database population is complete.

**Create a migration task**

First, create the table mappings JSON:

```
cat > table-mappings.json << EOF
{
  "rules": [
    {
      "rule-type": "selection",
      "rule-id": "1",
      "rule-name": "1",
      "object-locator": {
        "schema-name": "dms_sample",
        "table-name": "%"
      },
      "rule-action": "include"
    }
  ]
}
EOF
```

Then, create the task settings JSON:

```
cat > task-settings.json << EOF
{
  "TargetMetadata": {
    "TargetSchema": "",
    "SupportLobs": true,
    "FullLobMode": false,
    "LobChunkSize": 64,
    "LimitedSizeLobMode": true,
    "LobMaxSize": 32
  },
  "FullLoadSettings": {
    "TargetTablePrepMode": "DO_NOTHING",
    "CreatePkAfterFullLoad": false,
    "StopTaskCachedChangesApplied": false,
    "StopTaskCachedChangesNotApplied": false,
    "MaxFullLoadSubTasks": 8,
    "TransactionConsistencyTimeout": 600,
    "CommitRate": 10000
  },
  "Logging": {
    "EnableLogging": true
  }
}
EOF
```

Create the migration task:

```
aws dms create-replication-task \
    --replication-task-identifier dms-task \
    --source-endpoint-arn $SOURCE_ENDPOINT_ARN \
    --target-endpoint-arn $TARGET_ENDPOINT_ARN \
    --replication-instance-arn $DMS_INSTANCE_ARN \
    --migration-type full-load-and-cdc \
    --table-mappings file://table-mappings.json \
    --replication-task-settings file://task-settings.json
```

The output will include details about the replication task:

```
{
    "ReplicationTask": {
        "ReplicationTaskIdentifier": "dms-task",
        "SourceEndpointArn": "arn:aws:dms:us-east-1:123456789012:endpoint:ABCDEFGHIJKLMNOPQRSTUVWXYZ",
        "TargetEndpointArn": "arn:aws:dms:us-east-1:123456789012:endpoint:ABCDEFGHIJKLMNOPQRSTUVWXYZ",
        "ReplicationInstanceArn": "arn:aws:dms:us-east-1:123456789012:rep:ABCDEFGHIJKLMNOPQRSTUVWXYZ",
        "MigrationType": "full-load-and-cdc",
        "Status": "creating",
        "ReplicationTaskCreationDate": 1673596800.000,
        "ReplicationTaskArn": "arn:aws:dms:us-east-1:123456789012:task:ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    }
}
```

Store the task ARN:

```
TASK_ARN=$(aws dms describe-replication-tasks --filters Name=replication-task-id,Values=dms-task --query 'ReplicationTasks[0].ReplicationTaskArn' --output text)
echo "Task ARN: $TASK_ARN"
```

Wait for the task to be ready:

```
echo "Waiting for migration task to be ready..."
while true; do
    STATUS=$(aws dms describe-replication-tasks \
        --filters Name=replication-task-arn,Values=$TASK_ARN \
        --query 'ReplicationTasks[0].Status' \
        --output text)

    if [ "$STATUS" = "ready" ]; then
        echo "Migration task is now ready"
        break
    fi

    echo "Current status: $STATUS. Waiting 30 seconds..."
    sleep 30
done
```

**Start the migration task**

```
aws dms start-replication-task \
    --replication-task-arn $TASK_ARN \
    --start-replication-task-type start-replication
```

The output will confirm that the task has started:

```
{
    "ReplicationTask": {
        "ReplicationTaskIdentifier": "dms-task",
        "SourceEndpointArn": "arn:aws:dms:us-east-1:123456789012:endpoint:ABCDEFGHIJKLMNOPQRSTUVWXYZ",
        "TargetEndpointArn": "arn:aws:dms:us-east-1:123456789012:endpoint:ABCDEFGHIJKLMNOPQRSTUVWXYZ",
        "ReplicationInstanceArn": "arn:aws:dms:us-east-1:123456789012:rep:ABCDEFGHIJKLMNOPQRSTUVWXYZ",
        "MigrationType": "full-load-and-cdc",
        "Status": "starting",
        "ReplicationTaskCreationDate": 1673596800.000,
        "ReplicationTaskArn": "arn:aws:dms:us-east-1:123456789012:task:ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    }
}
```

## Test the replication

Now you'll test the replication by inserting data into the source database and verifying that it appears in the target database.

**Insert data into the source database**

Connect to your EC2 instance and run the following commands:

```
mysql -h $MARIADB_ENDPOINT -P 3306 -u admin -p dms_sample
```

When prompted, enter the password you retrieved from Secrets Manager.

Once connected to the MariaDB database, insert a test record:

```
insert person (full_name, last_name, first_name) VALUES ('Test User1', 'User1', 'Test');
exit
```

**Verify replication to the target database**

Connect to the PostgreSQL database:

```
psql --host=$POSTGRES_ENDPOINT --port=5432 --username=postgres --password --dbname=dms_sample
```

When prompted, enter the password from Secrets Manager.

Query the target database to verify the replicated data:

```
select * from dms_sample.person where first_name = 'Test';
```

You should see the record you inserted into the source database. This confirms that the replication is working correctly.

**Monitor the migration task**

You can monitor the status of your migration task using the following command:

```
aws dms describe-replication-tasks \
    --filters Name=replication-task-id,Values=dms-task \
    --query 'ReplicationTasks[0].Status'
```

To view detailed statistics about the tables being migrated:

```
aws dms describe-table-statistics \
    --replication-task-arn $TASK_ARN
```

The output will show statistics for each table being migrated, including the number of inserts, updates, and deletes.

## Going to production

This tutorial is designed to demonstrate the basic functionality of AWS DMS using the AWS CLI. For a production environment, consider the following best practices:

### Security best practices

1. **Network isolation**: Place your databases in private subnets and use a bastion host or AWS Systems Manager Session Manager for access.
2. **Least privilege access**: Use IAM roles with minimal permissions for DMS and other services.
3. **Encryption**: Enable encryption for all data at rest and in transit.
4. **Secure credential management**: Use AWS Secrets Manager for all database credentials.
5. **VPC endpoints**: Use VPC endpoints for AWS services to keep traffic within the AWS network.

### Architecture best practices

1. **High availability**: Use Multi-AZ deployments for databases and replication instances.
2. **Monitoring and alerting**: Set up CloudWatch alarms for key metrics and events.
3. **Backup strategy**: Implement regular backups and test restoration procedures.
4. **Scaling**: Plan for database growth and consider using read replicas for read-heavy workloads.
5. **Infrastructure as Code**: Use AWS CloudFormation or Terraform to manage your infrastructure.

For more information on AWS best practices, see:
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [AWS Security Best Practices](https://aws.amazon.com/architecture/security-identity-compliance/)
- [Database Migration Guide](https://docs.aws.amazon.com/prescriptive-guidance/latest/database-migration-guide/welcome.html)

## Clean up resources

When you're finished with this tutorial, you should clean up all the resources to avoid incurring additional charges.

**Delete DMS resources**

Delete the migration task:

```
aws dms delete-replication-task --replication-task-arn $TASK_ARN
echo "Waiting for task deletion to complete..."
sleep 30
```

Delete the endpoints:

```
aws dms delete-endpoint --endpoint-arn $SOURCE_ENDPOINT_ARN
aws dms delete-endpoint --endpoint-arn $TARGET_ENDPOINT_ARN
```

Delete the replication instance:

```
aws dms delete-replication-instance --replication-instance-arn $DMS_INSTANCE_ARN
echo "Waiting for replication instance deletion to complete..."
sleep 60
```

Delete the replication subnet group:

```
aws dms delete-replication-subnet-group --replication-subnet-group-identifier dms-subnet-group
```

**Delete RDS resources**

Delete the RDS instances:

```
aws rds delete-db-instance --db-instance-identifier dms-mariadb --skip-final-snapshot
aws rds delete-db-instance --db-instance-identifier dms-postgresql --skip-final-snapshot

echo "Waiting for database instances to be deleted. This may take several minutes..."
aws rds wait db-instance-deleted --db-instance-identifier dms-mariadb
aws rds wait db-instance-deleted --db-instance-identifier dms-postgresql
echo "Database instances deleted"
```

Delete the parameter groups and subnet group:

```
aws rds delete-db-parameter-group --db-parameter-group-name dms-mariadb-parameters
aws rds delete-db-parameter-group --db-parameter-group-name dms-postgresql-parameters
aws rds delete-db-subnet-group --db-subnet-group-name dms-db-subnet-group
```

**Delete EC2 resources**

Terminate the EC2 instance:

```
aws ec2 terminate-instances --instance-ids $EC2_INSTANCE_ID
echo "Waiting for EC2 instance to terminate..."
aws ec2 wait instance-terminated --instance-ids $EC2_INSTANCE_ID
echo "EC2 instance terminated"
```

Delete the key pair:

```
aws ec2 delete-key-pair --key-name $KEY_NAME
rm ${KEY_NAME}.pem
```

**Delete VPC resources**

Detach and delete the internet gateway:

```
aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID
```

Delete the subnets:

```
aws ec2 delete-subnet --subnet-id $PUBLIC_SUBNET_1_ID
aws ec2 delete-subnet --subnet-id $PUBLIC_SUBNET_2_ID
aws ec2 delete-subnet --subnet-id $(aws ec2 describe-subnets --filters "Name=tag:Name,Values=DMSVPC-private-subnet-1" --query "Subnets[0].SubnetId" --output text)
aws ec2 delete-subnet --subnet-id $(aws ec2 describe-subnets --filters "Name=tag:Name,Values=DMSVPC-private-subnet-2" --query "Subnets[0].SubnetId" --output text)
```

Delete the route table:

```
aws ec2 delete-route-table --route-table-id $PUBLIC_RT_ID
```

Finally, delete the VPC:

```
aws ec2 delete-vpc --vpc-id $VPC_ID
```

Delete the secret:

```
aws secretsmanager delete-secret --secret-id $SECRET_NAME --force-delete-without-recovery
```

## Troubleshooting

### Common Issues and Solutions

**VPC Limit Reached**
If you encounter an error about reaching your VPC limit:
- Check your current VPC usage: `aws ec2 describe-vpcs --query 'length(Vpcs)'`
- Use an existing VPC instead of creating a new one
- Request a VPC limit increase through the AWS Service Quotas console

**EC2 Instance Type Not Available**
If your preferred instance type isn't available in your chosen availability zone:
- The automated script automatically tries multiple instance types (t3.medium, t3.large, t2.medium, t2.large, m5.large, m5.xlarge)
- You can manually check availability: `aws ec2 describe-instance-type-offerings --location-type availability-zone --filters "Name=location,Values=YOUR-AZ"`
- Try a different availability zone in your region

**Database Connection Issues**
If you can't connect to your databases:
- Verify security group rules allow connections on ports 3306 (MariaDB) and 5432 (PostgreSQL)
- Ensure your EC2 instance is in the same VPC as your databases
- Check that your databases are publicly accessible if connecting from outside the VPC

**Migration Task Failures**
If your migration task fails:
- Check the task logs in the DMS console for specific error messages
- Verify that your source database has binary logging enabled (for MariaDB)
- Ensure your target database has the necessary permissions
- Check that both endpoints can be successfully tested

**Resource Cleanup Issues**
If cleanup fails:
- Some resources may have dependencies that prevent deletion
- Wait for dependent resources to be fully deleted before deleting parent resources
- Use the AWS console to manually delete any remaining resources
- Check for any resources that might have been created outside the expected naming convention

## Next steps

Now that you've learned how to migrate a database using AWS DMS, you can explore more advanced features:

1. [Ongoing replication](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Task.CDC.html) - Learn how to keep your source and target databases in sync with continuous replication.
2. [Data validation](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Validating.html) - Validate that your data was migrated correctly.
3. [Custom transformations](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Tasks.CustomizingTasks.TableMapping.html) - Transform your data during migration.
4. [Event notifications](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Events.html) - Set up notifications for migration events.
5. [Monitoring](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Monitoring.html) - Monitor your migration tasks using CloudWatch.
