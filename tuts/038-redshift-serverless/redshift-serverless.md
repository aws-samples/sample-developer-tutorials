# Getting started with Amazon Redshift Serverless using the AWS CLI

This tutorial guides you through setting up and using Amazon Redshift Serverless with the AWS Command Line Interface (AWS CLI). You'll learn how to create serverless resources, load sample data, and run queries against your data warehouse.

## Topics

- [Prerequisites](#prerequisites)
- [Creating an IAM role for Amazon S3 access](#creating-an-iam-role-for-amazon-s3-access)
- [Creating a Redshift Serverless namespace and workgroup](#creating-a-redshift-serverless-namespace-and-workgroup)
- [Creating tables and loading sample data](#creating-tables-and-loading-sample-data)
- [Running queries on your data](#running-queries-on-your-data)
- [Cleaning up resources](#cleaning-up-resources)
- [Going to production](#going-to-production)
- [Next steps](#next-steps)

## Prerequisites

Before you begin this tutorial, make sure you have the following:

1. The AWS CLI. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
2. Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
3. Basic familiarity with SQL and database concepts.
4. Sufficient permissions to create and manage Redshift Serverless resources, IAM roles, and access Amazon S3 in your AWS account.

Amazon Redshift Serverless requires an Amazon VPC with at least three subnets in three different availability zones, and at least 3 available IP addresses. Make sure your AWS account has a VPC that meets these requirements before proceeding.

This tutorial will take approximately 30-45 minutes to complete.

### Cost information

The resources you create in this tutorial will incur costs while they exist. The primary cost driver is the Redshift Serverless compute capacity:

- Redshift Serverless with 8 RPUs: Approximately $3.00 per hour
- Storage costs: Minimal for this tutorial (approximately $0.024 per GB-month)

The total cost for completing this tutorial should be less than $3.00 if you follow the cleanup instructions. If you leave the resources running, you could incur charges of approximately $72.00 per day.

For current pricing information, see [Amazon Redshift Serverless pricing](https://aws.amazon.com/redshift/serverless/pricing/).

## Creating an IAM role for Amazon S3 access

To load data from Amazon S3 into Redshift Serverless, you need to create an IAM role with the necessary permissions. This role allows Redshift Serverless to access objects in the S3 bucket.

First, let's create a trust policy document that allows Redshift Serverless to assume the role:

```
cat > redshift-trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "redshift-serverless.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
```

This trust policy specifies that the Redshift Serverless service can assume this role.

Next, create a policy document that grants access to the S3 bucket containing the sample data:

```
cat > redshift-s3-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::amzn-s3-demo-bucket",
        "arn:aws:s3:::amzn-s3-demo-bucket/*"
      ]
    }
  ]
}
EOF
```

This policy grants read-only access to the Amazon Redshift sample data bucket. For this tutorial, we'll use the public Redshift sample data bucket, but in the commands we'll use the actual bucket name `redshift-downloads`.

Now, create the IAM role using the trust policy:

```
aws iam create-role --role-name RedshiftServerlessS3Role --assume-role-policy-document file://redshift-trust-policy.json
```

The command returns details about the newly created role, including its Amazon Resource Name (ARN).

Attach the S3 access policy to the role:

```
aws iam put-role-policy --role-name RedshiftServerlessS3Role --policy-name S3Access --policy-document file://redshift-s3-policy.json
```

Finally, store the role ARN in a variable for later use:

```
ROLE_ARN=$(aws iam get-role --role-name RedshiftServerlessS3Role --query 'Role.Arn' --output text)
echo "Role ARN: $ROLE_ARN"
```

The role ARN will be used when loading data from S3 into your Redshift Serverless database.

## Creating a Redshift Serverless namespace and workgroup

Amazon Redshift Serverless organizes resources into namespaces and workgroups:
- A namespace is a collection of database objects and users
- A workgroup is a collection of compute resources

Let's create a namespace first. For security purposes, we'll generate a strong password instead of hardcoding one:

```
ADMIN_PASSWORD=$(openssl rand -base64 12)
echo "Generated password: $ADMIN_PASSWORD"
```

Make sure to save this password securely, as you'll need it to connect to your database.

Now create the namespace:

```
aws redshift-serverless create-namespace \
  --namespace-name default-namespace \
  --admin-username admin \
  --admin-user-password "$ADMIN_PASSWORD" \
  --db-name dev
```

This command creates a namespace named "default-namespace" with an admin user and a database named "dev".

Wait a few moments for the namespace to be available:

```
echo "Waiting for namespace to be available..."
sleep 10
```

Now, associate the IAM role we created earlier with the namespace:

```
aws redshift-serverless update-namespace \
  --namespace-name default-namespace \
  --iam-roles "$ROLE_ARN"
```

Next, create a workgroup associated with the namespace:

```
aws redshift-serverless create-workgroup \
  --workgroup-name default-workgroup \
  --namespace-name default-namespace \
  --base-capacity 8
```

The base-capacity parameter specifies the compute capacity for the workgroup in Redshift Processing Units (RPUs). Each RPU provides 16 GB of memory.

Wait for the workgroup to be available:

```
echo "Waiting for workgroup to be available..."
sleep 60
```

Once the workgroup is available, you can retrieve its endpoint:

```
WORKGROUP_ENDPOINT=$(aws redshift-serverless get-workgroup \
  --workgroup-name default-workgroup \
  --query 'workgroup.endpoint.address' \
  --output text)
echo "Workgroup endpoint: $WORKGROUP_ENDPOINT"
```

The endpoint is the connection point for your SQL client tools to connect to your Redshift Serverless database.

## Creating tables and loading sample data

Now that your Redshift Serverless resources are set up, you can create tables and load sample data. We'll use the Redshift Data API to execute SQL statements.

First, let's create three tables for the sample data:

```
aws redshift-data execute-statement \
  --database dev \
  --workgroup-name default-workgroup \
  --sql "CREATE TABLE users(
    userid INTEGER NOT NULL DISTKEY SORTKEY,
    username CHAR(8),
    firstname VARCHAR(30),
    lastname VARCHAR(30),
    city VARCHAR(30),
    state CHAR(2),
    email VARCHAR(100),
    phone CHAR(14),
    likesports BOOLEAN,
    liketheatre BOOLEAN,
    likeconcerts BOOLEAN,
    likejazz BOOLEAN,
    likeclassical BOOLEAN,
    likeopera BOOLEAN,
    likerock BOOLEAN,
    likevegas BOOLEAN,
    likebroadway BOOLEAN,
    likemusicals BOOLEAN
  );"
```

This command creates a "users" table with various columns to store user information.

Next, create an "event" table:

```
aws redshift-data execute-statement \
  --database dev \
  --workgroup-name default-workgroup \
  --sql "CREATE TABLE event(
    eventid INTEGER NOT NULL DISTKEY,
    venueid SMALLINT NOT NULL,
    catid SMALLINT NOT NULL,
    dateid SMALLINT NOT NULL SORTKEY,
    eventname VARCHAR(200),
    starttime TIMESTAMP
  );"
```

Finally, create a "sales" table:

```
aws redshift-data execute-statement \
  --database dev \
  --workgroup-name default-workgroup \
  --sql "CREATE TABLE sales(
    salesid INTEGER NOT NULL,
    listid INTEGER NOT NULL DISTKEY,
    sellerid INTEGER NOT NULL,
    buyerid INTEGER NOT NULL,
    eventid INTEGER NOT NULL,
    dateid SMALLINT NOT NULL SORTKEY,
    qtysold SMALLINT NOT NULL,
    pricepaid DECIMAL(8,2),
    commission DECIMAL(8,2),
    saletime TIMESTAMP
  );"
```

Wait a moment for the tables to be created:

```
echo "Waiting for tables to be created..."
sleep 10
```

Now, let's load data into these tables from the public Amazon Redshift sample data bucket using the COPY command:

```
aws redshift-data execute-statement \
  --database dev \
  --workgroup-name default-workgroup \
  --sql "COPY users
    FROM 's3://redshift-downloads/tickit/allusers_pipe.txt'
    DELIMITER '|'
    TIMEFORMAT 'YYYY-MM-DD HH:MI:SS'
    IGNOREHEADER 1
    IAM_ROLE '$ROLE_ARN';"
```

This command loads data into the "users" table from an S3 file with pipe-delimited values.

Load data into the "event" table:

```
aws redshift-data execute-statement \
  --database dev \
  --workgroup-name default-workgroup \
  --sql "COPY event
    FROM 's3://redshift-downloads/tickit/allevents_pipe.txt'
    DELIMITER '|'
    TIMEFORMAT 'YYYY-MM-DD HH:MI:SS'
    IGNOREHEADER 1
    IAM_ROLE '$ROLE_ARN';"
```

Finally, load data into the "sales" table:

```
aws redshift-data execute-statement \
  --database dev \
  --workgroup-name default-workgroup \
  --sql "COPY sales
    FROM 's3://redshift-downloads/tickit/sales_tab.txt'
    DELIMITER '\t'
    TIMEFORMAT 'MM/DD/YYYY HH:MI:SS'
    IGNOREHEADER 1
    IAM_ROLE '$ROLE_ARN';"
```

Note that the sales data uses tab-delimited values, so we specify `\t` as the delimiter.

Wait for the data loading to complete:

```
echo "Waiting for data loading to complete..."
sleep 30
```

### Verifying data was loaded correctly

Let's verify that our data was loaded correctly by running some simple COUNT queries:

```
USERS_COUNT_QUERY_ID=$(aws redshift-data execute-statement \
  --database dev \
  --workgroup-name default-workgroup \
  --sql "SELECT COUNT(*) FROM users;" \
  --query 'Id' --output text)

echo "Waiting for query to complete..."
sleep 5

aws redshift-data get-statement-result --id "$USERS_COUNT_QUERY_ID"
```

This should return the number of rows in the users table. Similarly, check the event and sales tables:

```
EVENT_COUNT_QUERY_ID=$(aws redshift-data execute-statement \
  --database dev \
  --workgroup-name default-workgroup \
  --sql "SELECT COUNT(*) FROM event;" \
  --query 'Id' --output text)

sleep 5
aws redshift-data get-statement-result --id "$EVENT_COUNT_QUERY_ID"

SALES_COUNT_QUERY_ID=$(aws redshift-data execute-statement \
  --database dev \
  --workgroup-name default-workgroup \
  --sql "SELECT COUNT(*) FROM sales;" \
  --query 'Id' --output text)

sleep 5
aws redshift-data get-statement-result --id "$SALES_COUNT_QUERY_ID"
```

If these queries return non-zero counts, your data was loaded successfully.

## Running queries on your data

Now that you have data loaded into your tables, you can run queries to analyze it. Let's run a couple of example queries.

First, let's find the top 10 buyers by quantity:

```
QUERY1_ID=$(aws redshift-data execute-statement \
  --database dev \
  --workgroup-name default-workgroup \
  --sql "SELECT firstname, lastname, total_quantity
    FROM (SELECT buyerid, sum(qtysold) total_quantity
          FROM sales
          GROUP BY buyerid
          ORDER BY total_quantity desc limit 10) Q, users
    WHERE Q.buyerid = userid
    ORDER BY Q.total_quantity desc;" \
  --query 'Id' --output text)
```

The Redshift Data API executes queries asynchronously, so we need to wait for the query to complete:

```
echo "Waiting for query to complete..."
sleep 10
```

Now, retrieve the query results:

```
aws redshift-data get-statement-result --id "$QUERY1_ID"
```

This command returns the results of the query, showing the top 10 buyers by quantity.

Let's run another query to find events in the 99.9 percentile in terms of all-time gross sales:

```
QUERY2_ID=$(aws redshift-data execute-statement \
  --database dev \
  --workgroup-name default-workgroup \
  --sql "SELECT eventname, total_price
    FROM (SELECT eventid, total_price, ntile(1000) over(order by total_price desc) as percentile
          FROM (SELECT eventid, sum(pricepaid) total_price
                FROM sales
                GROUP BY eventid)) Q, event E
    WHERE Q.eventid = E.eventid
    AND percentile = 1
    ORDER BY total_price desc;" \
  --query 'Id' --output text)
```

Wait for the query to complete:

```
echo "Waiting for query to complete..."
sleep 10
```

Retrieve the results:

```
aws redshift-data get-statement-result --id "$QUERY2_ID"
```

This query shows the events with the highest gross sales, representing the top 0.1% of all events.

## Cleaning up resources

When you're done experimenting with Redshift Serverless, you should clean up the resources to avoid incurring charges:

```
# Delete the workgroup
aws redshift-serverless delete-workgroup --workgroup-name default-workgroup

# Wait for workgroup to be deleted before deleting namespace
echo "Waiting for workgroup to be deleted..."
sleep 60

# Delete the namespace
aws redshift-serverless delete-namespace --namespace-name default-namespace

# Delete the IAM role policy
aws iam delete-role-policy --role-name RedshiftServerlessS3Role --policy-name S3Access

# Delete the IAM role
aws iam delete-role --role-name RedshiftServerlessS3Role

# Clean up temporary files
rm -f redshift-trust-policy.json redshift-s3-policy.json
```

These commands delete all the resources created during this tutorial, including the workgroup, namespace, and IAM role.

## Going to production

This tutorial is designed to help you learn the basics of Amazon Redshift Serverless using the AWS CLI. For production environments, consider the following additional best practices:

### Security considerations

1. **Password management**: Use AWS Secrets Manager to store and manage database credentials instead of generating them in scripts.

2. **Network security**: Configure VPC security groups to restrict access to your Redshift Serverless resources. Consider using VPC endpoints for enhanced security.

3. **Encryption**: Use customer-managed KMS keys for enhanced control over data encryption.

4. **IAM permissions**: Further restrict IAM permissions based on the principle of least privilege.

5. **Audit logging**: Enable audit logging to track database activities.

For more information, see [Security in Amazon Redshift Serverless](https://docs.aws.amazon.com/redshift/latest/mgmt/serverless-security.html).

### Architecture best practices

1. **Infrastructure as Code**: Use AWS CloudFormation or AWS CDK to define and provision resources.

2. **Monitoring and observability**: Set up CloudWatch dashboards and alarms to monitor performance and costs.

3. **Workload management**: Configure workload management to optimize resource utilization.

4. **Backup and recovery**: Implement a backup strategy using snapshots.

5. **Cost optimization**: Use usage limits to control costs and monitor usage with AWS Cost Explorer.

For more information, see the [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/) and [Amazon Redshift best practices](https://docs.aws.amazon.com/redshift/latest/dg/best-practices.html).

## Next steps

Now that you've learned how to set up and use Amazon Redshift Serverless with the AWS CLI, you can explore more advanced features:

- [Connect to Amazon Redshift Serverless using JDBC and ODBC drivers](https://docs.aws.amazon.com/redshift/latest/mgmt/serverless-connecting.html)
- [Use the Amazon Redshift Data API for programmatic access](https://docs.aws.amazon.com/redshift/latest/mgmt/data-api.html)
- [Build machine learning models with Amazon Redshift ML](https://docs.aws.amazon.com/redshift/latest/dg/getting-started-machine-learning.html)
- [Query data directly from an Amazon S3 data lake](https://docs.aws.amazon.com/redshift/latest/dg/c-getting-started-using-spectrum.html)
- [Manage Amazon Redshift Serverless workgroups and namespaces](https://docs.aws.amazon.com/redshift/latest/mgmt/serverless-workgroups-and-namespaces.html)

You can also explore the [Amazon Redshift Serverless pricing](https://aws.amazon.com/redshift/serverless/pricing/) to understand the cost structure for your specific workloads.
