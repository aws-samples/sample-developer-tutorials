# Getting started with Amazon Neptune using the AWS CLI

This tutorial guides you through setting up an Amazon Neptune graph database using the AWS Command Line Interface (CLI). You'll create a Neptune database cluster, configure the necessary networking components, and learn how to interact with your graph database.

## Prerequisites

Before you begin, make sure you have:

- An AWS account with permissions to create Neptune resources
- AWS CLI installed and configured with appropriate credentials
- Basic understanding of AWS networking concepts (VPC, subnets, security groups)
- Approximately 20-30 minutes to complete the tutorial
- Estimated cost: The resources created in this tutorial will incur charges. A db.r5.large Neptune instance costs approximately $0.35 per hour, with minimal storage costs (around $0.01 per hour for the minimum 10GB allocation). The total cost for completing this tutorial should be less than $0.20 if you delete all resources immediately after completion. Remember to delete all resources after completing the tutorial to avoid unnecessary charges.

## Create a VPC for your Neptune database

Amazon Neptune requires a Virtual Private Cloud (VPC) to operate. In this section, you'll create a VPC with the necessary components.

First, create a VPC with DNS support enabled:

```bash
VPC_NAME="neptune-vpc"
VPC_OUTPUT=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=$VPC_NAME}]" --output json)
VPC_ID=$(echo "$VPC_OUTPUT" | grep -o '"VpcId": "[^"]*' | cut -d'"' -f4)
echo "VPC created with ID: $VPC_ID"

aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-support
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames
```

After creating the VPC, you need to create an Internet Gateway and attach it to your VPC:

```bash
IGW_OUTPUT=$(aws ec2 create-internet-gateway --output json)
IGW_ID=$(echo "$IGW_OUTPUT" | grep -o '"InternetGatewayId": "[^"]*' | cut -d'"' -f4)
echo "Internet Gateway created with ID: $IGW_ID"

aws ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
```

## Create subnets in multiple availability zones

Neptune requires subnets in at least three different Availability Zones. Let's create these subnets:

```bash
# Get available AZs
AZ_OUTPUT=$(aws ec2 describe-availability-zones --output json)
AZ1=$(echo "$AZ_OUTPUT" | grep -o '"ZoneName": "[^"]*' | cut -d'"' -f4 | head -1)
AZ2=$(echo "$AZ_OUTPUT" | grep -o '"ZoneName": "[^"]*' | cut -d'"' -f4 | head -2 | tail -1)
AZ3=$(echo "$AZ_OUTPUT" | grep -o '"ZoneName": "[^"]*' | cut -d'"' -f4 | head -3 | tail -1)

# Create 3 subnets in different AZs
SUBNET1_OUTPUT=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.1.0/24 --availability-zone $AZ1 --output json)
SUBNET1_ID=$(echo "$SUBNET1_OUTPUT" | grep -o '"SubnetId": "[^"]*' | cut -d'"' -f4)

SUBNET2_OUTPUT=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.2.0/24 --availability-zone $AZ2 --output json)
SUBNET2_ID=$(echo "$SUBNET2_OUTPUT" | grep -o '"SubnetId": "[^"]*' | cut -d'"' -f4)

SUBNET3_OUTPUT=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.3.0/24 --availability-zone $AZ3 --output json)
SUBNET3_ID=$(echo "$SUBNET3_OUTPUT" | grep -o '"SubnetId": "[^"]*' | cut -d'"' -f4)

echo "Created subnets: $SUBNET1_ID, $SUBNET2_ID, $SUBNET3_ID"
```

Now create a route table and add a route to the Internet Gateway:

```bash
ROUTE_TABLE_OUTPUT=$(aws ec2 create-route-table --vpc-id $VPC_ID --output json)
ROUTE_TABLE_ID=$(echo "$ROUTE_TABLE_OUTPUT" | grep -o '"RouteTableId": "[^"]*' | cut -d'"' -f4)
echo "Route table created with ID: $ROUTE_TABLE_ID"

# Add route to Internet Gateway
aws ec2 create-route --route-table-id $ROUTE_TABLE_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID

# Associate route table with subnets
aws ec2 associate-route-table --route-table-id $ROUTE_TABLE_ID --subnet-id $SUBNET1_ID
aws ec2 associate-route-table --route-table-id $ROUTE_TABLE_ID --subnet-id $SUBNET2_ID
aws ec2 associate-route-table --route-table-id $ROUTE_TABLE_ID --subnet-id $SUBNET3_ID
```

## Configure security for your Neptune database

Create a security group to control access to your Neptune database:

```bash
SG_NAME="neptune-sg"
SG_OUTPUT=$(aws ec2 create-security-group --group-name $SG_NAME --description "Security group for Neptune" --vpc-id $VPC_ID --output json)
SECURITY_GROUP_ID=$(echo "$SG_OUTPUT" | grep -o '"GroupId": "[^"]*' | cut -d'"' -f4)
echo "Security group created with ID: $SECURITY_GROUP_ID"

# Add inbound rule for Neptune port (8182)
# Note: For this tutorial, we're restricting access to within the VPC
# In a production environment, you should restrict access further
aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 8182 --cidr 10.0.0.0/16
```

This security group allows traffic to the Neptune port (8182) from within your VPC. For production environments, you should restrict access further to only the specific resources that need to connect to Neptune.

## Create a Neptune DB subnet group

A DB subnet group is a collection of subnets that you can use for your Neptune database:

```bash
DB_SUBNET_GROUP="neptune-subnet-group"
aws neptune create-db-subnet-group \
    --db-subnet-group-name $DB_SUBNET_GROUP \
    --db-subnet-group-description "Subnet group for Neptune" \
    --subnet-ids $SUBNET1_ID $SUBNET2_ID $SUBNET3_ID
```

## Create a Neptune DB cluster and instance

Now you're ready to create your Neptune database cluster:

```bash
DB_CLUSTER_ID="neptune-cluster"
aws neptune create-db-cluster \
    --db-cluster-identifier $DB_CLUSTER_ID \
    --engine neptune \
    --vpc-security-group-ids $SECURITY_GROUP_ID \
    --db-subnet-group-name $DB_SUBNET_GROUP
```

After creating the cluster, create a Neptune instance within that cluster:

```bash
DB_INSTANCE_ID="neptune-instance"
aws neptune create-db-instance \
    --db-instance-identifier $DB_INSTANCE_ID \
    --db-instance-class db.r5.large \
    --engine neptune \
    --db-cluster-identifier $DB_CLUSTER_ID
```

Wait for the DB instance to become available:

```bash
aws neptune wait db-instance-available --db-instance-identifier $DB_INSTANCE_ID
```

This command will wait until your Neptune instance is fully provisioned and ready to use, which typically takes several minutes.

## Connect to your Neptune database

Once your Neptune instance is available, you can retrieve the endpoint to connect to it:

```bash
ENDPOINT_OUTPUT=$(aws neptune describe-db-clusters --db-cluster-identifier $DB_CLUSTER_ID --output json)
NEPTUNE_ENDPOINT=$(echo "$ENDPOINT_OUTPUT" | grep -o '"Endpoint": "[^"]*' | cut -d'"' -f4)
echo "Neptune endpoint: $NEPTUNE_ENDPOINT"
```

Neptune supports multiple graph query languages. Here's how you can use curl to send a Gremlin query to your Neptune database:

```bash
curl -X POST \
    -d '{"gremlin":"g.V().limit(1)"}' \
    https://$NEPTUNE_ENDPOINT:8182/gremlin
```

This query returns up to one vertex from your graph. Since your database is empty, it should return an empty result.

## Add data to your graph database

Let's add some data to your graph database. The following commands create vertices representing people and edges representing friendships:

```bash
# Add a person named Howard
curl -X POST \
    -d '{"gremlin":"g.addV(\"person\").property(\"name\", \"Howard\")"}' \
    https://$NEPTUNE_ENDPOINT:8182/gremlin

# Add a person named Jack
curl -X POST \
    -d '{"gremlin":"g.addV(\"person\").property(\"name\", \"Jack\")"}' \
    https://$NEPTUNE_ENDPOINT:8182/gremlin

# Add a person named Annie
curl -X POST \
    -d '{"gremlin":"g.addV(\"person\").property(\"name\", \"Annie\")"}' \
    https://$NEPTUNE_ENDPOINT:8182/gremlin

# Create a friendship between Howard and Jack
curl -X POST \
    -d '{"gremlin":"g.V().has(\"name\", \"Howard\").as(\"a\").V().has(\"name\", \"Jack\").addE(\"friend\").from(\"a\")"}' \
    https://$NEPTUNE_ENDPOINT:8182/gremlin

# Create a friendship between Jack and Annie
curl -X POST \
    -d '{"gremlin":"g.V().has(\"name\", \"Jack\").as(\"a\").V().has(\"name\", \"Annie\").addE(\"friend\").from(\"a\")"}' \
    https://$NEPTUNE_ENDPOINT:8182/gremlin
```

This creates a simple social network graph that looks like this:

```
Howard --friend--> Jack --friend--> Annie
```

## Query your graph database

Now that you have data in your graph, you can run more interesting queries. For example, to find friends of Howard's friends:

```bash
curl -X POST \
    -d '{"gremlin":"g.V().has(\"name\", \"Howard\").out(\"friend\").out(\"friend\").values(\"name\")"}' \
    https://$NEPTUNE_ENDPOINT:8182/gremlin
```

This query should return "Annie" as the friend of Howard's friend (Jack). The query works by:
1. Finding the vertex with name "Howard"
2. Following outgoing "friend" edges to find Howard's friends (Jack)
3. Following outgoing "friend" edges from those vertices to find friends of Howard's friends (Annie)
4. Returning the "name" property of those vertices

## Troubleshooting

If you encounter issues during this tutorial, here are some common problems and solutions:

### Connection issues

If you can't connect to your Neptune endpoint, check:
- The security group allows traffic on port 8182
- Your client machine has network connectivity to the VPC
- The Neptune instance is in the "available" state

### Query errors

If your Gremlin queries return errors:
- Verify the syntax of your Gremlin query
- Check that you're using the correct endpoint
- Ensure you're using the proper JSON format in your curl command

### Resource creation failures

If resource creation fails:
- Check that you have sufficient permissions
- Verify that you haven't reached service quotas
- Ensure you're following the correct dependency order for resources

## Clean up resources

To avoid incurring charges, delete all the resources you created:

```bash
# Delete DB instance
aws neptune delete-db-instance --db-instance-identifier $DB_INSTANCE_ID --skip-final-snapshot

# Wait for DB instance to be deleted
aws neptune wait db-instance-deleted --db-instance-identifier $DB_INSTANCE_ID

# Delete DB cluster
aws neptune delete-db-cluster --db-cluster-identifier $DB_CLUSTER_ID --skip-final-snapshot

# Wait for DB cluster to be deleted (no specific wait command for this, so we'll sleep)
sleep 60

# Delete DB subnet group
aws neptune delete-db-subnet-group --db-subnet-group-name $DB_SUBNET_GROUP

# Delete security group
aws ec2 delete-security-group --group-id $SECURITY_GROUP_ID

# Detach and delete internet gateway
aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID

# Delete subnets
aws ec2 delete-subnet --subnet-id $SUBNET1_ID
aws ec2 delete-subnet --subnet-id $SUBNET2_ID
aws ec2 delete-subnet --subnet-id $SUBNET3_ID

# Delete route table
aws ec2 delete-route-table --route-table-id $ROUTE_TABLE_ID

# Delete VPC
aws ec2 delete-vpc --vpc-id $VPC_ID
```

Make sure to verify that all resources have been deleted to avoid unexpected charges.

## Going to production

This tutorial is designed to help you learn how Amazon Neptune works using the AWS CLI. For production deployments, consider these additional best practices:

### Security enhancements

1. **IAM authentication**: Enable IAM authentication for your Neptune cluster to control access using IAM policies
   ```bash
   aws neptune create-db-cluster --enable-iam-database-authentication --other-parameters
   ```

2. **Encryption at rest**: Enable storage encryption for your Neptune cluster
   ```bash
   aws neptune create-db-cluster --storage-encrypted --other-parameters
   ```

3. **Restricted security groups**: Limit access to specific security groups or IP ranges instead of the entire VPC
   ```bash
   aws ec2 authorize-security-group-ingress --group-id $SG_ID --source-group $CLIENT_SG_ID --protocol tcp --port 8182
   ```

4. **VPC endpoints**: Use VPC endpoints to keep traffic within the AWS network

### Architecture improvements

1. **Multi-AZ deployment**: Enable Multi-AZ for automatic failover
   ```bash
   aws neptune create-db-cluster --multi-az --other-parameters
   ```

2. **Read replicas**: Add read replicas for improved read performance and availability
   ```bash
   aws neptune create-db-instance --db-cluster-identifier $CLUSTER_ID --replica-source-db-instance-identifier $INSTANCE_ID
   ```

3. **Monitoring**: Set up CloudWatch alarms and dashboards for Neptune metrics

4. **Backup strategy**: Configure automated backups and test restoration procedures

For more information on building production-ready applications with Neptune, see:
- [Amazon Neptune Best Practices](https://docs.aws.amazon.com/neptune/latest/userguide/best-practices.html)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Neptune Security](https://docs.aws.amazon.com/neptune/latest/userguide/security.html)

## Next steps

Now that you've learned how to create and use a Neptune database, you might want to explore:

- [Using Neptune with graph notebooks](https://docs.aws.amazon.com/neptune/latest/userguide/graph-notebooks.html) - Learn how to use Jupyter notebooks to interact with your Neptune database
- [Loading data into Neptune](https://docs.aws.amazon.com/neptune/latest/userguide/bulk-load.html) - Learn how to bulk load data into your Neptune database
- [Neptune ML](https://docs.aws.amazon.com/neptune/latest/userguide/machine-learning.html) - Explore machine learning capabilities with Neptune
- [Neptune analytics](https://docs.aws.amazon.com/neptune/latest/userguide/analytics.html) - Learn about Neptune's analytics features
