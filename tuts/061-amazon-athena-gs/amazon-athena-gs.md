# Getting started with Amazon Athena using the AWS CLI

This tutorial walks you through using Amazon Athena with the AWS Command Line Interface (CLI) to query data. You'll create a database and table based on sample data stored in Amazon S3, run SQL queries, and manage named queries.

## Prerequisites

Before you begin this tutorial, you need:

- An AWS account. If you don't have one, sign up at [https://aws.amazon.com/free/](https://aws.amazon.com/free/).
- The AWS CLI installed and configured with appropriate permissions. For installation instructions, see [Installing or updating the latest version of the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
- Basic knowledge of SQL queries.

This tutorial uses live resources, so you are charged for the queries that you run. The estimated cost for completing this tutorial is approximately $0.0001 (one-tenth of a cent), assuming you follow the cleanup instructions. You aren't charged for the sample data in the location that this tutorial uses, but if you upload your own data files to Amazon S3, additional charges may apply.

## Create an S3 bucket for query results

Amazon Athena stores query results in an Amazon S3 bucket. Before you can run queries, you need to create a bucket for these results.

Create an S3 bucket with a unique name:

```bash
RANDOM_ID=$(openssl rand -hex 6)
S3_BUCKET="amzn-s3-demo-${RANDOM_ID}"
aws s3 mb "s3://$S3_BUCKET"
```

The command generates a random identifier to ensure your bucket name is unique. The output should look like this:

```
make_bucket: amzn-s3-demo-9e81a17340c0
```

Remember this bucket name as you'll use it throughout the tutorial.

For better security in a real environment, you would also configure bucket encryption and block public access:

```bash
# Block all public access
aws s3api put-public-access-block \
  --bucket $S3_BUCKET \
  --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# Enable server-side encryption
aws s3api put-bucket-encryption \
  --bucket $S3_BUCKET \
  --server-side-encryption-configuration '{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]}'
```

## Create a database

Now that you have a bucket for query results, you can create an Athena database.

Run the following command to create a database named `mydatabase`:

```bash
aws athena start-query-execution \
  --query-string "CREATE DATABASE IF NOT EXISTS mydatabase" \
  --result-configuration "OutputLocation=s3://$S3_BUCKET/output/"
```

The command returns a query execution ID that you can use to check the status of the operation:

```json
{
    "QueryExecutionId": "90d99c50-xmpl-436b-a6c0-d79288ce3c8e"
}
```

Store this ID in a variable to track the operation:

```bash
QUERY_ID="90d99c50-xmpl-436b-a6c0-d79288ce3c8e"  # Replace with your actual query ID
```

Wait for the database creation to complete:

```bash
# Wait for query to complete
echo "Waiting for database creation to complete..."
while true; do
    STATUS=$(aws athena get-query-execution --query-execution-id $QUERY_ID --query "QueryExecution.Status.State" --output text)
    if [ "$STATUS" = "SUCCEEDED" ]; then
        echo "Database creation completed successfully."
        break
    elif [ "$STATUS" = "FAILED" ] || [ "$STATUS" = "CANCELLED" ]; then
        echo "Database creation failed with status: $STATUS"
        exit 1
    fi
    echo "Database creation in progress, status: $STATUS"
    sleep 2
done
```

To verify that the database was created, list all databases in your Athena data catalog:

```bash
aws athena list-databases --catalog-name AwsDataCatalog
```

The output should include your new database:

```json
{
    "DatabaseList": [
        {
            "Name": "default"
        },
        {
            "Name": "mydatabase"
        }
    ]
}
```

## Create a table

Now that you have a database, you can create a table based on sample Amazon CloudFront log data. The sample data is in tab-separated values (TSV) format and is available in a public Amazon S3 bucket.

Run the following command to create a table named `cloudfront_logs`:

```bash
# Store your AWS region in a variable
AWS_REGION=$(aws configure get region)

# Create a temporary SQL file
cat > create_table.sql << EOF
CREATE EXTERNAL TABLE IF NOT EXISTS mydatabase.cloudfront_logs (
  \`Date\` DATE,
  Time STRING,
  Location STRING,
  Bytes INT,
  RequestIP STRING,
  Method STRING,
  Host STRING,
  Uri STRING,
  Status INT,
  Referrer STRING,
  os STRING,
  Browser STRING,
  BrowserVersion STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.RegexSerDe'
WITH SERDEPROPERTIES (
  "input.regex" = "^(?!#)([^ ]+)\\s+([^ ]+)\\s+([^ ]+)\\s+([^ ]+)\\s+([^ ]+)\\s+([^ ]+)\\s+([^ ]+)\\s+([^ ]+)\\s+([^ ]+)\\s+([^ ]+)\\s+[^\\(]+\\([^\\;]+\\).*\\%20([^\\/]+)[\\/](.*)$"
) LOCATION 's3://athena-examples-us-east-1/cloudfront/plaintext/';
EOF

aws athena start-query-execution \
  --query-string "$(cat create_table.sql)" \
  --result-configuration "OutputLocation=s3://$S3_BUCKET/output/"
```

This command creates an external table that maps to the CloudFront log data stored in Amazon S3. The command uses a regular expression to parse the log data and extract fields like date, time, location, and browser information.

Capture the query ID and wait for the table creation to complete:

```bash
# Capture the query ID
TABLE_QUERY="CREATE EXTERNAL TABLE IF NOT EXISTS mydatabase.cloudfront_logs (
    \`Date\` DATE,
    Time STRING,
    Location STRING,
    Bytes INT,
    RequestIP STRING,
    Method STRING,
    Host STRING,
    Uri STRING,
    Status INT,
    Referrer STRING,
    os STRING,
    Browser STRING,
    BrowserVersion STRING
  )
  ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.RegexSerDe'
  WITH SERDEPROPERTIES (
    \"input.regex\" = \"^(?!#)([^ ]+)\\\\s+([^ ]+)\\\\s+([^ ]+)\\\\s+([^ ]+)\\\\s+([^ ]+)\\\\s+([^ ]+)\\\\s+([^ ]+)\\\\s+([^ ]+)\\\\s+([^ ]+)\\\\s+([^ ]+)\\\\s+[^\\\\(]+[\\\\(]([^\\\\;]+).*\\\\%20([^\\\\/]+)[\\\\/](.*)$\"
  ) LOCATION 's3://athena-examples-us-east-1/cloudfront/plaintext/';"

TABLE_QUERY_ID=$(aws athena start-query-execution \
  --query-string "$TABLE_QUERY" \
  --result-configuration "OutputLocation=s3://$S3_BUCKET/output/" \
  --query "QueryExecutionId" --output text)

# Wait for table creation to complete
echo "Waiting for table creation to complete..."
while true; do
    STATUS=$(aws athena get-query-execution --query-execution-id $TABLE_QUERY_ID --query "QueryExecution.Status.State" --output text)
    if [ "$STATUS" = "SUCCEEDED" ]; then
        echo "Table creation completed successfully."
        break
    elif [ "$STATUS" = "FAILED" ] || [ "$STATUS" = "CANCELLED" ]; then
        echo "Table creation failed with status: $STATUS"
        exit 1
    fi
    echo "Table creation in progress, status: $STATUS"
    sleep 2
done
```

To verify that the table was created, list the tables in your database:

```bash
aws athena list-table-metadata \
  --catalog-name AwsDataCatalog \
  --database-name mydatabase
```

The output should include details about your new table:

```json
{
    "TableMetadataList": [
        {
            "Name": "cloudfront_logs",
            "CreateTime": 1751906758.0,
            "TableType": "EXTERNAL_TABLE",
            "Columns": [
                {
                    "Name": "date",
                    "Type": "date"
                },
                {
                    "Name": "time",
                    "Type": "string"
                },
                // Additional columns omitted for brevity
            ],
            "Parameters": {
                "EXTERNAL": "TRUE",
                "location": "s3://athena-examples-us-east-1/cloudfront/plaintext"
                // Additional parameters omitted for brevity
            }
        }
    ]
}
```

## Run a query

Now that you have created a table, you can run SQL queries against it. Let's run a query to count the number of log entries by operating system.

Run the following command:

```bash
# Execute the query and capture the query ID
QUERY_ID=$(aws athena start-query-execution \
  --query-string "SELECT os, COUNT(*) count
  FROM mydatabase.cloudfront_logs
  WHERE date BETWEEN date '2014-07-05' AND date '2014-08-05'
  GROUP BY os" \
  --result-configuration "OutputLocation=s3://$S3_BUCKET/output/" \
  --query "QueryExecutionId" --output text)

echo "Query execution ID: $QUERY_ID"
```

Wait for the query to complete:

```bash
# Wait for query to complete
echo "Waiting for query to complete..."
while true; do
    STATUS=$(aws athena get-query-execution --query-execution-id $QUERY_ID --query "QueryExecution.Status.State" --output text)
    if [ "$STATUS" = "SUCCEEDED" ]; then
        echo "Query completed successfully."
        break
    elif [ "$STATUS" = "FAILED" ] || [ "$STATUS" = "CANCELLED" ]; then
        echo "Query failed with status: $STATUS"
        exit 1
    fi
    echo "Query in progress, status: $STATUS"
    sleep 2
done
```

Once the query completes, get the results:

```bash
aws athena get-query-results --query-execution-id $QUERY_ID
```

The output should look like this:

```json
{
    "ResultSet": {
        "Rows": [
            {
                "Data": [
                    {
                        "VarCharValue": "os"
                    },
                    {
                        "VarCharValue": "count"
                    }
                ]
            },
            {
                "Data": [
                    {
                        "VarCharValue": "MacOS"
                    },
                    {
                        "VarCharValue": "852"
                    }
                ]
            },
            {
                "Data": [
                    {
                        "VarCharValue": "Linux"
                    },
                    {
                        "VarCharValue": "813"
                    }
                ]
            },
            // Additional rows omitted for brevity
        ]
    }
}
```

You can also download the results directly from the S3 bucket:

```bash
# Get the S3 path of the results
S3_PATH=$(aws athena get-query-execution --query-execution-id $QUERY_ID --query "QueryExecution.ResultConfiguration.OutputLocation" --output text)

# Download the results
aws s3 cp $S3_PATH ./query-results.csv
```

This command downloads the query results to a local CSV file named `query-results.csv`.

## Create and use named queries

Athena allows you to save queries with names for future use. This is useful for queries that you run frequently.

Create a named query:

```bash
# Create a named query and capture its ID
NAMED_QUERY_ID=$(aws athena create-named-query \
  --name "OS Count Query" \
  --description "Count of operating systems in CloudFront logs" \
  --database "mydatabase" \
  --query-string "SELECT os, COUNT(*) count
  FROM mydatabase.cloudfront_logs
  WHERE date BETWEEN date '2014-07-05' AND date '2014-08-05'
  GROUP BY os" \
  --query "NamedQueryId" --output text)

echo "Named query created with ID: $NAMED_QUERY_ID"
```

List all your named queries:

```bash
aws athena list-named-queries
```

The output should include your new named query:

```json
{
    "NamedQueryIds": [
        "5b6853a5-xmpl-4378-bb8c-ae7467e57c76"
    ]
}
```

Get the details of a specific named query:

```bash
aws athena get-named-query --named-query-id $NAMED_QUERY_ID
```

The output includes the query string and other details:

```json
{
    "NamedQuery": {
        "Name": "OS Count Query",
        "Description": "Count of operating systems in CloudFront logs",
        "Database": "mydatabase",
        "QueryString": "SELECT os, COUNT(*) count \nFROM mydatabase.cloudfront_logs \nWHERE date BETWEEN date '2014-07-05' AND date '2014-08-05' \nGROUP BY os",
        "NamedQueryId": "5b6853a5-xmpl-4378-bb8c-ae7467e57c76",
        "WorkGroup": "primary"
    }
}
```

Execute a named query:

```bash
# Get the query string from the named query
QUERY_STRING=$(aws athena get-named-query --named-query-id $NAMED_QUERY_ID --query "NamedQuery.QueryString" --output text)

# Execute the query and capture the query ID
EXEC_QUERY_ID=$(aws athena start-query-execution \
  --query-string "$QUERY_STRING" \
  --result-configuration "OutputLocation=s3://$S3_BUCKET/output/" \
  --query "QueryExecutionId" --output text)

echo "Named query execution ID: $EXEC_QUERY_ID"

# Wait for the query to complete
echo "Waiting for named query execution to complete..."
while true; do
    STATUS=$(aws athena get-query-execution --query-execution-id $EXEC_QUERY_ID --query "QueryExecution.Status.State" --output text)
    if [ "$STATUS" = "SUCCEEDED" ]; then
        echo "Named query execution completed successfully."
        break
    elif [ "$STATUS" = "FAILED" ] || [ "$STATUS" = "CANCELLED" ]; then
        echo "Named query execution failed with status: $STATUS"
        exit 1
    fi
    echo "Named query execution in progress, status: $STATUS"
    sleep 2
done
```

## Troubleshooting common issues

Here are some common issues you might encounter when using Athena with the AWS CLI:

1. **Query fails with "FAILED: Access Denied"**: Ensure your IAM user or role has the necessary permissions to access the S3 bucket containing the data and the query results location.

2. **Table not found**: Verify that you're using the correct database name and table name. Database and table names are case-sensitive.

3. **Invalid query syntax**: Check your SQL syntax. Athena uses Presto SQL, which has some differences from other SQL dialects.

4. **Query timeout**: For large datasets, queries might time out. Consider optimizing your query or using partitioning to reduce the amount of data scanned.

5. **S3 bucket already exists**: If you get an error that the S3 bucket already exists, try using a different random identifier.

## Clean up resources

To avoid incurring additional charges, clean up the resources you created in this tutorial.

Delete the named query:

```bash
aws athena delete-named-query --named-query-id $NAMED_QUERY_ID
```

Drop the table:

```bash
# Drop the table and capture the query ID
DROP_TABLE_QUERY_ID=$(aws athena start-query-execution \
  --query-string "DROP TABLE IF EXISTS mydatabase.cloudfront_logs" \
  --result-configuration "OutputLocation=s3://$S3_BUCKET/output/" \
  --query "QueryExecutionId" --output text)

# Wait for the table deletion to complete
echo "Waiting for table deletion to complete..."
while true; do
    STATUS=$(aws athena get-query-execution --query-execution-id $DROP_TABLE_QUERY_ID --query "QueryExecution.Status.State" --output text)
    if [ "$STATUS" = "SUCCEEDED" ]; then
        echo "Table dropped successfully."
        break
    elif [ "$STATUS" = "FAILED" ] || [ "$STATUS" = "CANCELLED" ]; then
        echo "Table deletion failed with status: $STATUS"
        exit 1
    fi
    echo "Table deletion in progress, status: $STATUS"
    sleep 2
done
```

Drop the database:

```bash
# Drop the database and capture the query ID
DROP_DB_QUERY_ID=$(aws athena start-query-execution \
  --query-string "DROP DATABASE IF EXISTS mydatabase" \
  --result-configuration "OutputLocation=s3://$S3_BUCKET/output/" \
  --query "QueryExecutionId" --output text)

# Wait for the database deletion to complete
echo "Waiting for database deletion to complete..."
while true; do
    STATUS=$(aws athena get-query-execution --query-execution-id $DROP_DB_QUERY_ID --query "QueryExecution.Status.State" --output text)
    if [ "$STATUS" = "SUCCEEDED" ]; then
        echo "Database dropped successfully."
        break
    elif [ "$STATUS" = "FAILED" ] || [ "$STATUS" = "CANCELLED" ]; then
        echo "Database deletion failed with status: $STATUS"
        exit 1
    fi
    echo "Database deletion in progress, status: $STATUS"
    sleep 2
done
```

Empty and delete the S3 bucket:

```bash
# Empty the bucket
aws s3 rm "s3://$S3_BUCKET" --recursive

# Delete the bucket
aws s3 rb "s3://$S3_BUCKET"
```

## Going to production

This tutorial is designed to help you learn the basics of using Amazon Athena with the AWS CLI. For production environments, consider the following best practices:

### Security best practices

1. **Encryption**: Enable encryption for your S3 buckets and Athena query results.
2. **IAM permissions**: Use the principle of least privilege when granting permissions.
3. **VPC endpoints**: Consider using VPC endpoints for Athena to keep traffic within your VPC.
4. **Access logging**: Enable access logging for your S3 buckets.

### Performance optimization

1. **Columnar formats**: Convert your data to columnar formats like Parquet or ORC for better query performance.
2. **Partitioning**: Partition your data to reduce the amount of data scanned by each query.
3. **Compression**: Use compression to reduce storage costs and improve query performance.
4. **Workgroups**: Use workgroups to separate users, teams, applications, or workloads.

### Cost management

1. **Query optimization**: Optimize your queries to scan less data.
2. **Result reuse**: Enable query result reuse to avoid re-running identical queries.
3. **Data lifecycle policies**: Implement lifecycle policies for your query results.
4. **Query limits**: Set query limits in workgroups to control costs.

For more information on these topics, see:
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Security in Amazon Athena](https://docs.aws.amazon.com/athena/latest/ug/security.html)
- [Top 10 Performance Tuning Tips for Amazon Athena](https://aws.amazon.com/blogs/big-data/top-10-performance-tuning-tips-for-amazon-athena/)

## Next steps

Now that you've learned the basics of using Amazon Athena with the AWS CLI, you can explore these additional features:

- [Use AWS Glue Data Catalog with Athena](https://docs.aws.amazon.com/athena/latest/ug/data-sources-glue.html) - Learn how to use AWS Glue to create and manage your data catalog.
- [Query Amazon CloudFront logs](https://docs.aws.amazon.com/athena/latest/ug/cloudfront-logs.html) - Explore more advanced queries for CloudFront logs.
- [Connect to other data sources](https://docs.aws.amazon.com/athena/latest/ug/work-with-data-stores.html) - Learn how to connect Athena to various data sources.
- [Use workgroups to control query access and costs](https://docs.aws.amazon.com/athena/latest/ug/workgroups.html) - Organize users and applications into workgroups for better resource management.
