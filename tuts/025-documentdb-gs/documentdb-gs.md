# Getting started with Amazon DocumentDB using the AWS CLI

This tutorial guides you through the process of creating and using an Amazon DocumentDB cluster with the AWS Command Line Interface (AWS CLI). You'll learn how to create a cluster, connect to it, and perform basic database operations.

## Topics

- [Prerequisites](#prerequisites)
- [Store credentials in Secrets Manager](#store-credentials-in-secrets-manager)
- [Create a DB subnet group](#create-a-db-subnet-group)
- [Create a DocumentDB cluster](#create-a-documentdb-cluster)
- [Create a DocumentDB instance](#create-a-documentdb-instance)
- [Configure security and connectivity](#configure-security-and-connectivity)
- [Connect to your cluster](#connect-to-your-cluster)
- [Perform database operations](#perform-database-operations)
- [Clean up resources](#clean-up-resources)
- [Going to production](#going-to-production)
- [Next steps](#next-steps)

## Prerequisites

Before you begin this tutorial, make sure you have the following:

- The AWS CLI. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
- Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
- MongoDB Shell (`mongosh`) installed on your local machine. To install the MongoDB Shell, follow the [Install mongosh](https://www.mongodb.com/docs/mongodb-shell/install/) instructions.
- [Sufficient permissions](https://docs.aws.amazon.com/documentdb/latest/developerguide/security-iam.html) to create and manage Amazon DocumentDB, Secrets Manager, and EC2 resources in your AWS account.
- A default VPC in your AWS account with at least two subnets in different Availability Zones.

**Estimated time to complete:** 30-45 minutes

**Estimated cost:** If you're eligible for the AWS Free Tier, you can run the resources in this tutorial for up to 750 hours per month for the first 6 months at no cost. Outside the Free Tier, the resources in this tutorial cost approximately $0.08 per hour. Remember to follow the cleanup instructions to avoid ongoing charges.

## Store credentials in Secrets Manager

Before creating the cluster, generate a secure password and store it in AWS Secrets Manager. This avoids passing plaintext passwords in CLI commands.

**Generate a password and create a secret**

```bash
DB_PASSWORD=$(openssl rand -base64 16)
aws secretsmanager create-secret \
    --name docdb-tutorial-credentials \
    --description "Credentials for DocumentDB tutorial" \
    --secret-string "{\"username\":\"adminuser\",\"password\":\"${DB_PASSWORD}\"}"
```

This command generates a random password and stores it along with the username in Secrets Manager. You should see output similar to this:

```json
{
    "ARN": "arn:aws:secretsmanager:us-east-1:123456789012:secret:docdb-tutorial-credentials-AbCdEf",
    "Name": "docdb-tutorial-credentials",
    "VersionId": "a1b2c3d4-xmpl-5678-abcd-ee1234567890"
}
```

**Retrieve the password for later use**

When you need the password for subsequent commands, retrieve it from Secrets Manager:

```bash
DB_PASSWORD=$(aws secretsmanager get-secret-value \
    --secret-id docdb-tutorial-credentials \
    --query SecretString --output text | grep -o '"password":"[^"]*"' | cut -d'"' -f4)
```

## Create a DB subnet group

Amazon DocumentDB requires a DB subnet group that includes subnets in at least two different Availability Zones. Let's start by creating a subnet group using subnets from your default VPC.

**Get your default VPC and subnets**

First, identify your default VPC:

```bash
aws ec2 describe-vpcs \
    --filters "Name=isDefault,Values=true" \
    --query "Vpcs[0].VpcId" \
    --output text
```

This command returns the ID of your default VPC. Next, find subnets in this VPC. Replace `vpc-abcd1234` with your actual VPC ID.

```bash
aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=vpc-abcd1234" \
    --query "Subnets[*].[SubnetId,AvailabilityZone]" \
    --output text
```

The output shows subnet IDs and their Availability Zones. You need to select subnets from at least two different Availability Zones.

**Create the DB subnet group**

Create a DB subnet group using subnets from different Availability Zones. Replace `subnet-abcd1234` and `subnet-efgh5678` with actual subnet IDs from different Availability Zones.

```bash
aws docdb create-db-subnet-group \
    --db-subnet-group-name docdb-subnet-group \
    --db-subnet-group-description "Subnet group for DocumentDB tutorial" \
    --subnet-ids subnet-abcd1234 subnet-efgh5678
```

This command creates a subnet group that Amazon DocumentDB uses to deploy your cluster.

You should see output similar to this:

```json
{
    "DBSubnetGroup": {
        "DBSubnetGroupName": "docdb-subnet-group",
        "DBSubnetGroupDescription": "Subnet group for DocumentDB tutorial",
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

## Create a DocumentDB cluster

With the subnet group in place, you can now create your DocumentDB cluster. The following command creates a cluster with engine version 5.0.0 and encryption at rest enabled.

**Create the cluster**

Retrieve the password from Secrets Manager and pass it to the create command:

```bash
DB_PASSWORD=$(aws secretsmanager get-secret-value \
    --secret-id docdb-tutorial-credentials \
    --query SecretString --output text | grep -o '"password":"[^"]*"' | cut -d'"' -f4)

aws docdb create-db-cluster \
    --db-cluster-identifier docdb-cluster \
    --engine docdb \
    --engine-version 5.0.0 \
    --master-username adminuser \
    --master-user-password "$DB_PASSWORD" \
    --db-subnet-group-name docdb-subnet-group \
    --storage-encrypted
```

The `--storage-encrypted` flag enables encryption at rest for the cluster. This is a security best practice for all data stores.

**Wait for the cluster to become available**

Creating a cluster takes a few minutes. Check its status with the following command:

```bash
aws docdb describe-db-clusters \
    --db-cluster-identifier docdb-cluster \
    --query "DBClusters[0].Status" \
    --output text
```

Wait until the status shows `available` before proceeding to the next step. This typically takes 3-5 minutes.

## Create a DocumentDB instance

A DocumentDB cluster requires at least one instance to process requests. Let's create an instance in your cluster.

**Create the instance**

The following command creates a `db.t3.medium` instance in your cluster:

```bash
aws docdb create-db-instance \
    --db-instance-identifier docdb-instance \
    --db-instance-class db.t3.medium \
    --engine docdb \
    --db-cluster-identifier docdb-cluster
```

The `db.t3.medium` instance type is eligible for the AWS Free Tier for new customers.

**Wait for the instance to become available**

Creating an instance also takes a few minutes. Check its status with:

```bash
aws docdb describe-db-instances \
    --db-instance-identifier docdb-instance \
    --query "DBInstances[0].DBInstanceStatus" \
    --output text
```

Wait until the status shows `available` before proceeding. This typically takes 5-10 minutes.

## Configure security and connectivity

Before connecting to your cluster, you need to configure security and download the necessary certificate.

**Get cluster endpoint and security group information**

Retrieve your cluster's endpoint:

```bash
aws docdb describe-db-clusters \
    --db-cluster-identifier docdb-cluster \
    --query "DBClusters[0].Endpoint" \
    --output text
```

This returns the endpoint you'll use to connect to your cluster. Save this value for later use.

Retrieve the security group ID associated with your cluster:

```bash
aws docdb describe-db-clusters \
    --db-cluster-identifier docdb-cluster \
    --query "DBClusters[0].VpcSecurityGroups[0].VpcSecurityGroupId" \
    --output text
```

Save this value as well.

**Update security group to allow MongoDB connections**

To connect to your cluster, allow inbound traffic on port 27017 (the default MongoDB port) from your IP address. Replace `sg-abcd1234` with your security group ID.

```bash
MY_IP=$(curl -s https://checkip.amazonaws.com)
aws ec2 authorize-security-group-ingress \
    --group-id sg-abcd1234 \
    --protocol tcp \
    --port 27017 \
    --cidr ${MY_IP}/32
```

This command detects your current IP address and allows connections only from that address.

> **Note:** If you have a dynamic IP address that changes frequently, you may need to update this security group rule whenever your IP changes. For production environments, consider using AWS VPN or AWS Direct Connect for more stable connectivity.

**Download the CA certificate**

Amazon DocumentDB requires TLS connections. Download the CA certificate:

```bash
mkdir -p ~/certs
curl -sS -o ~/certs/global-bundle.pem \
    https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem
```

Verify the certificate was downloaded:

```bash
ls -la ~/certs/global-bundle.pem
```

You should see the certificate file in the output.

## Connect to your cluster

With the security group configured and the certificate downloaded, you can connect to your cluster using the MongoDB Shell.

**Retrieve your password and connect**

Retrieve the password from Secrets Manager and connect to your cluster. Replace the `--host` value with your actual cluster endpoint from the previous step.

```bash
DB_PASSWORD=$(aws secretsmanager get-secret-value \
    --secret-id docdb-tutorial-credentials \
    --query SecretString --output text | grep -o '"password":"[^"]*"' | cut -d'"' -f4)

mongosh --tls --tlsCAFile ~/certs/global-bundle.pem \
    --host docdb-cluster.cluster-abcd1234xmpl.us-east-1.docdb.amazonaws.com:27017 \
    --username adminuser \
    --password "${DB_PASSWORD}"
```

If the connection is successful, you'll see the MongoDB Shell prompt: `test>`.

**Verify connection**

```javascript
db.runCommand({connectionStatus: 1})
```

## Perform database operations

Now that you're connected to your cluster, you can perform various database operations.

**Insert a single document**

Insert a simple document into a collection:

```javascript
db.collection.insertOne({"hello":"DocumentDB"})
```

This command inserts a document with a field `hello` and value `DocumentDB` into a collection named `collection`. You should see output confirming the insertion with an ObjectId.

**Read the document**

Retrieve the document you just inserted:

```javascript
db.collection.findOne()
```

This returns the document with an automatically generated `_id` field. The output should look similar to:

```
{ "_id" : ObjectId("5e401fe56056fda7321fbd67"), "hello" : "DocumentDB" }
```

**Insert multiple documents**

Insert multiple documents at once:

```javascript
db.profiles.insertMany([
  { _id: 1, name: 'Matt', status: 'active', level: 12, score: 202 },
  { _id: 2, name: 'Frank', status: 'inactive', level: 2, score: 9 },
  { _id: 3, name: 'Karen', status: 'active', level: 7, score: 87 },
  { _id: 4, name: 'Katie', status: 'active', level: 3, score: 27 }
])
```

This creates a new collection called `profiles` and inserts four documents. You should see output confirming the insertion of all four documents.

**Query all documents in a collection**

Retrieve all documents in the `profiles` collection:

```javascript
db.profiles.find()
```

This returns all documents in the `profiles` collection. You should see all four profiles you inserted.

**Query with a filter**

Find a specific document using a filter:

```javascript
db.profiles.find({name: "Katie"})
```

This returns only the document where the `name` field equals `Katie`. You should see just Katie's profile in the output.

**Find and modify a document**

Update a document and return its original content:

```javascript
db.profiles.findAndModify({
  query: { name: "Matt", status: "active"},
  update: { $inc: { score: 10 } }
})
```

This increases Matt's score by 10 points. The output shows the document before the modification.

**Verify the modification**

Check that the update was applied:

```javascript
db.profiles.find({name: "Matt"})
```

The score should now be 212 instead of 202, confirming that the update was successful.

**Exit the MongoDB Shell**

When you're done exploring, exit the MongoDB Shell:

```javascript
exit
```

This returns you to your system command prompt.

## Clean up resources

When you're finished with this tutorial, delete the resources to avoid incurring additional charges.

**Delete the DB instance**

First, delete the instance:

```bash
aws docdb delete-db-instance \
    --db-instance-identifier docdb-instance
```

Wait for the instance to be deleted before proceeding:

```bash
aws docdb describe-db-instances \
    --db-instance-identifier docdb-instance \
    --query "DBInstances[0].DBInstanceStatus" \
    --output text
```

Run this command periodically until it returns an error indicating the instance was not found. This typically takes 5-10 minutes.

**Delete the DB cluster**

Next, delete the cluster:

```bash
aws docdb delete-db-cluster \
    --db-cluster-identifier docdb-cluster \
    --skip-final-snapshot
```

The `--skip-final-snapshot` parameter tells DocumentDB not to create a final snapshot before deletion. In a production environment, you might want to create a final snapshot for backup purposes.

Wait for the cluster to be deleted:

```bash
aws docdb describe-db-clusters \
    --db-cluster-identifier docdb-cluster \
    --query "DBClusters[0].Status" \
    --output text
```

Run this command periodically until it returns an error indicating the cluster was not found.

**Delete the DB subnet group**

Delete the subnet group:

```bash
aws docdb delete-db-subnet-group \
    --db-subnet-group-name docdb-subnet-group
```

**Delete the secret**

Delete the secret from Secrets Manager:

```bash
aws secretsmanager delete-secret \
    --secret-id docdb-tutorial-credentials \
    --force-delete-without-recovery
```

**Revoke the security group rule**

Remove the inbound rule you added to allow MongoDB connections. Replace `sg-abcd1234` with your security group ID:

```bash
aws ec2 revoke-security-group-ingress \
    --group-id sg-abcd1234 \
    --protocol tcp \
    --port 27017 \
    --cidr 203.0.113.75/32
```

This completes the cleanup process. All resources created during this tutorial have been deleted, and you won't incur any further charges.

## Going to production

This tutorial is designed for learning purposes and demonstrates basic Amazon DocumentDB functionality. For production deployments, consider the following additional best practices.

**Security enhancements**

- Use IAM authentication instead of password authentication for stronger security.
- Use VPC endpoints to keep traffic within the AWS network.
- Enable audit logging to track database activities.
- Rotate credentials stored in Secrets Manager on a regular schedule.

**Architecture improvements**

- Deploy multiple instances across different Availability Zones for high availability.
- Add read replicas to distribute read operations and improve performance.
- Set up CloudWatch monitoring for your cluster.
- Implement a comprehensive backup and restore strategy.

## Next steps

Now that you've learned the basics of Amazon DocumentDB, you can explore more advanced features:

- [Managing Amazon DocumentDB clusters](https://docs.aws.amazon.com/documentdb/latest/developerguide/db-cluster-manage.html) - Learn how to manage your DocumentDB clusters and instances.
- [Scaling Amazon DocumentDB](https://docs.aws.amazon.com/documentdb/latest/developerguide/operational_tasks.html) - Discover how to scale your clusters to handle more traffic.
- [Backing up and restoring](https://docs.aws.amazon.com/documentdb/latest/developerguide/backup_restore.html) - Learn about backup and restore options for your data.
- [Security best practices](https://docs.aws.amazon.com/documentdb/latest/developerguide/security.html) - Implement security best practices for your DocumentDB deployments.
- [Performance optimization](https://docs.aws.amazon.com/documentdb/latest/developerguide/performance-tips.html) - Optimize your cluster for better performance.
