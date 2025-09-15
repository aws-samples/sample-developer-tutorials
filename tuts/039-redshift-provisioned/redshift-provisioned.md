# Getting started with Amazon Redshift provisioned clusters using the AWS CLI

This tutorial guides you through setting up an Amazon Redshift provisioned cluster, loading sample data, and running queries using the AWS Command Line Interface (AWS CLI). Amazon Redshift is a fully managed data warehouse service that makes it simple and cost-effective to analyze your data using standard SQL.

## Topics

- [Prerequisites](#prerequisites)
- [Create a Redshift cluster](#create-a-redshift-cluster)
- [Create an IAM role for S3 access](#create-an-iam-role-for-s3-access)
- [Create tables and load data](#create-tables-and-load-data)
- [Run example queries](#run-example-queries)
- [Clean up resources](#clean-up-resources)
- [Going to production](#going-to-production)
- [Next steps](#next-steps)

## Prerequisites

Before you begin this tutorial, make sure you have the following:

1. The AWS CLI. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
2. Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
3. Sufficient permissions to create and manage Amazon Redshift clusters, IAM roles, and access Amazon S3 in your AWS account.
4. Basic understanding of SQL and data warehousing concepts.

**Time to complete**: Approximately 1-2 hours

**Cost**: This tutorial uses AWS resources that will incur charges in your account. The estimated cost for running the resources in this tutorial for 2 hours is approximately $13.60 USD. The primary cost comes from the Amazon Redshift cluster with 2 ra3.4xlarge nodes at $3.40 per node-hour. Remember to follow the cleanup instructions to avoid ongoing charges.

## Create a Redshift cluster

In this section, you'll create an Amazon Redshift cluster that will host your data warehouse. The cluster consists of a leader node and compute nodes that process your queries.

**Create the cluster**

The following command creates a Redshift cluster with two RA3.4xlarge nodes. This cluster type provides separated compute and storage, allowing you to scale each independently.

```
aws redshift create-cluster \
  --cluster-identifier examplecluster \
  --node-type ra3.4xlarge \
  --number-of-nodes 2 \
  --master-username awsuser \
  --master-user-password Changeit1 \
  --db-name dev \
  --port 5439
```

After running this command, Amazon Redshift begins provisioning your cluster. This process typically takes several minutes to complete.

**Wait for the cluster to become available**

You can check the status of your cluster using the following command:

```
aws redshift describe-clusters \
  --cluster-identifier examplecluster \
  --query 'Clusters[0].ClusterStatus'
```

Alternatively, you can use the wait command to automatically wait until the cluster is available:

```
aws redshift wait cluster-available \
  --cluster-identifier examplecluster
```

Once the cluster is available, you'll see the status change to "available". Now your cluster is ready to use.

## Create an IAM role for S3 access

To load data from Amazon S3 into your Redshift cluster, you need to create an IAM role that grants the necessary permissions. This role allows Redshift to securely access data stored in S3 buckets.

**Create a trust policy**

First, create a trust policy document that allows Redshift to assume the role:

```
cat > redshift-trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "redshift.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
```

This policy document defines a trust relationship that allows the Redshift service to assume this role.

**Create the IAM role**

Now, create the IAM role using the trust policy:

```
aws iam create-role \
  --role-name RedshiftS3Role \
  --assume-role-policy-document file://redshift-trust-policy.json
```

After creating the role, you need to store its ARN (Amazon Resource Name) for later use:

```
ROLE_ARN=$(aws iam get-role \
  --role-name RedshiftS3Role \
  --query 'Role.Arn' \
  --output text)
```

**Create and attach a policy for S3 access**

Next, create a policy document that grants read access to the S3 bucket containing the sample data:

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
        "arn:aws:s3:::redshift-downloads",
        "arn:aws:s3:::redshift-downloads/*"
      ]
    }
  ]
}
EOF
```

Attach this policy to the IAM role:

```
aws iam put-role-policy \
  --role-name RedshiftS3Role \
  --policy-name RedshiftS3Access \
  --policy-document file://redshift-s3-policy.json
```

**Attach the role to your cluster**

Finally, attach the IAM role to your Redshift cluster:

```
aws redshift modify-cluster-iam-roles \
  --cluster-identifier examplecluster \
  --add-iam-roles $ROLE_ARN
```

It may take a few minutes for the role to be fully attached to the cluster. You can check the status with:

```
aws redshift describe-clusters \
  --cluster-identifier examplecluster \
  --query "Clusters[0].IamRoles[?IamRoleArn=='$ROLE_ARN'].ApplyStatus"
```

When the status shows "in-sync", the role is successfully attached and ready to use. Wait for about 30 seconds after seeing "in-sync" to ensure the permissions have fully propagated.

## Create tables and load data

Now that your cluster is set up with the necessary permissions, you can create tables and load data from Amazon S3. In this section, you'll create two tables and load sample data into them.

**Get cluster connection information**

First, retrieve your cluster's endpoint information:

```
aws redshift describe-clusters \
  --cluster-identifier examplecluster \
  --query 'Clusters[0].Endpoint.{Address:Address,Port:Port}'
```

This information would be needed if you were connecting with a SQL client. For this tutorial, we'll use the AWS CLI to execute SQL statements directly.

**Create the sales table**

Create a table to store sales data:

```
aws redshift-data execute-statement \
  --cluster-identifier examplecluster \
  --database dev \
  --db-user awsuser \
  --sql "DROP TABLE IF EXISTS sales; CREATE TABLE sales(salesid integer not null, listid integer not null distkey, sellerid integer not null, buyerid integer not null, eventid integer not null, dateid smallint not null sortkey, qtysold smallint not null, pricepaid decimal(8,2), commission decimal(8,2), saletime timestamp);"
```

This command creates a table named "sales" with columns for various sales data attributes. The "listid" column is designated as the distribution key, and "dateid" is the sort key, which helps optimize query performance.

**Create the date table**

Create a table to store date information:

```
aws redshift-data execute-statement \
  --cluster-identifier examplecluster \
  --database dev \
  --db-user awsuser \
  --sql "DROP TABLE IF EXISTS date; CREATE TABLE date(dateid smallint not null distkey sortkey, caldate date not null, day character(3) not null, week smallint not null, month character(5) not null, qtr character(5) not null, year smallint not null, holiday boolean default('N'));"
```

This table will store calendar date information that can be joined with the sales data.

**Load data into the sales table**

Now, load data into the sales table from the S3 bucket:

```
aws redshift-data execute-statement \
  --cluster-identifier examplecluster \
  --database dev \
  --db-user awsuser \
  --sql "COPY sales FROM 's3://redshift-downloads/tickit/sales_tab.txt' DELIMITER '\t' TIMEFORMAT 'MM/DD/YYYY HH:MI:SS' REGION 'us-east-1' IAM_ROLE '$ROLE_ARN';"
```

This command uses the COPY command, which is the recommended way to load large datasets into Amazon Redshift. The command specifies the source S3 path, delimiter, time format, and uses the IAM role we created earlier for authentication.

**Load data into the date table**

Similarly, load data into the date table:

```
aws redshift-data execute-statement \
  --cluster-identifier examplecluster \
  --database dev \
  --db-user awsuser \
  --sql "COPY date FROM 's3://redshift-downloads/tickit/date2008_pipe.txt' DELIMITER '|' REGION 'us-east-1' IAM_ROLE '$ROLE_ARN';"
```

This command loads date information using a pipe (|) as the delimiter.

## Run example queries

With data loaded into your tables, you can now run queries to analyze the data. In this section, you'll run a couple of example queries to demonstrate Redshift's capabilities.

**Query the sales table definition**

First, let's examine the structure of the sales table:

```
aws redshift-data execute-statement \
  --cluster-identifier examplecluster \
  --database dev \
  --db-user awsuser \
  --sql "SELECT * FROM pg_table_def WHERE tablename = 'sales';"
```

This query returns metadata about the sales table, including column names, data types, and other attributes. To view the results, you need to get the statement ID from the output and use it in the following command:

```
aws redshift-data get-statement-result --id <statement-id>
```

**Find total sales for a specific date**

Now, let's run a query that joins the sales and date tables to find the total quantity sold on a specific date:

```
aws redshift-data execute-statement \
  --cluster-identifier examplecluster \
  --database dev \
  --db-user awsuser \
  --sql "SELECT sum(qtysold) FROM sales, date WHERE sales.dateid = date.dateid AND caldate = '2008-01-05';"
```

This query demonstrates how to join tables and perform aggregations in Redshift. Again, you'll need to use the get-statement-result command with the statement ID to view the results.

## Clean up resources

When you're finished with this tutorial, you should delete the resources you created to avoid incurring additional charges.

**Delete the Redshift cluster**

Delete the cluster with the following command:

```
aws redshift delete-cluster \
  --cluster-identifier examplecluster \
  --skip-final-cluster-snapshot
```

This command initiates the deletion of your cluster. The `--skip-final-cluster-snapshot` parameter indicates that you don't want to create a final snapshot before deletion.

**Wait for cluster deletion**

You can wait for the cluster to be fully deleted:

```
aws redshift wait cluster-deleted \
  --cluster-identifier examplecluster
```

**Delete the IAM role**

Finally, clean up the IAM role and policy:

```
aws iam delete-role-policy \
  --role-name RedshiftS3Role \
  --policy-name RedshiftS3Access

aws iam delete-role \
  --role-name RedshiftS3Role
```

These commands remove the policy from the role and then delete the role itself.

## Going to production

This tutorial is designed to help you learn how to use Amazon Redshift with the AWS CLI in a development or test environment. For production deployments, consider the following additional best practices:

**Security considerations:**

1. **Credential management** - Use AWS Secrets Manager instead of hardcoded passwords for database credentials.
2. **Encryption** - Enable encryption at rest using AWS KMS and configure SSL for connections.
3. **Network security** - Deploy your cluster in a private subnet with appropriate security groups.
4. **IAM database authentication** - Consider using IAM authentication instead of database passwords.
5. **Audit logging** - Enable audit logging to track user activities and queries.

**Architecture best practices:**

1. **High availability** - Consider multi-AZ deployments for production workloads.
2. **Backup strategy** - Configure automated snapshots and retention policies.
3. **Monitoring** - Set up CloudWatch alarms for key metrics like CPU utilization and query performance.
4. **Workload management** - Configure workload management (WLM) to prioritize different query types.
5. **Scaling** - Plan for data growth and consider using elastic resize or concurrency scaling.

For more information on building production-ready solutions with Amazon Redshift, see:
- [Amazon Redshift Best Practices](https://docs.aws.amazon.com/redshift/latest/dg/best-practices.html)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Amazon Redshift Security Overview](https://docs.aws.amazon.com/redshift/latest/mgmt/security-overview.html)

## Next steps

Now that you've learned the basics of working with Amazon Redshift using the AWS CLI, you can explore more advanced features:

- Learn about [Amazon Redshift Serverless](https://docs.aws.amazon.com/redshift/latest/mgmt/serverless-console.html) for on-demand data warehousing without managing clusters
- Explore [Amazon Redshift query editor v2](https://docs.aws.amazon.com/redshift/latest/mgmt/query-editor-v2-using.html) for a web-based SQL client experience
- Discover [Amazon Redshift data sharing](https://docs.aws.amazon.com/redshift/latest/dg/datashare-overview.html) to share data across clusters and AWS accounts
- Implement [Amazon Redshift Spectrum](https://docs.aws.amazon.com/redshift/latest/dg/c-using-spectrum.html) to query data directly from files in Amazon S3
- Set up [automated snapshots and backups](https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-snapshots.html) for disaster recovery

For more information about Amazon Redshift features and best practices, see the [Amazon Redshift Database Developer Guide](https://docs.aws.amazon.com/redshift/latest/dg/welcome.html).
