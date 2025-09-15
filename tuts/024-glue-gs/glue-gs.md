# Getting started with the AWS Glue Data Catalog using the AWS CLI

This tutorial guides you through creating and managing AWS Glue Data Catalog resources using the AWS Command Line Interface (AWS CLI). You'll learn how to create databases and tables, and how to use the Data Catalog to organize your metadata.

## Topics

- [Prerequisites](#prerequisites)
- [Create a database](#create-a-database)
- [Create a table](#create-a-table)
- [Explore the Data Catalog](#explore-the-data-catalog)
- [Clean up resources](#clean-up-resources)
- [Going to production](#going-to-production)
- [Next steps](#next-steps)

## Prerequisites

Before you begin this tutorial, make sure you have the following:

1. The AWS CLI. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
2. Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
3. Basic familiarity with AWS Glue concepts and data formats.
4. Sufficient permissions to create and manage AWS Glue resources in your AWS account.

**Cost**: The AWS Glue Data Catalog provides storage for up to 1 million objects (databases, tables, partitions) at no additional charge. This tutorial creates only one database and one table, which is well within the free tier. There are no costs associated with running this tutorial as long as you stay within the free tier limits and follow the cleanup instructions.

Before you start, set the `AWS_REGION` environment variable to the same Region that you configured the AWS CLI to use, if it's not already set. This environment variable is used in example commands to specify the region for AWS Glue resources.

```
$ [ -z "${AWS_REGION}" ] && export AWS_REGION=$(aws configure get region)
```

Let's get started with creating and managing AWS Glue Data Catalog resources using the CLI.

## Create a database

The AWS Glue Data Catalog organizes metadata in databases and tables. In this section, you'll create a database to store your metadata.

**Create a new database**

The following command creates a new database named "tutorial_database" with a description:

```
$ aws glue create-database --database-input '{"Name":"tutorial_database","Description":"Database for AWS Glue tutorial"}'
```

This command creates a database in the AWS Glue Data Catalog. The `--database-input` parameter takes a JSON string that defines the database properties.

**Verify the database was created**

To verify that your database was created successfully, use the following command:

```
$ aws glue get-database --name tutorial_database
{
    "Database": {
        "Name": "tutorial_database",
        "Description": "Database for AWS Glue tutorial",
        "CreateTime": "2025-01-13T12:00:00.000Z",
        "CatalogId": "123456789012"
    }
}
```

The output shows the details of your newly created database, including its name, description, creation time, and the catalog ID.

**List all databases**

You can also list all databases in your Data Catalog:

```
$ aws glue get-databases
{
    "DatabaseList": [
        {
            "Name": "default",
            "CatalogId": "123456789012"
        },
        {
            "Name": "tutorial_database",
            "Description": "Database for AWS Glue tutorial",
            "CreateTime": "2025-01-13T12:00:00.000Z",
            "CatalogId": "123456789012"
        }
    ]
}
```

The output shows all databases in your Data Catalog, including the default database and the one you just created.

## Create a table

Tables in the AWS Glue Data Catalog contain metadata about your data. In this section, you'll create a table that references data stored in an Amazon S3 bucket.

**Prepare the table definition**

First, create a JSON file named `table-input.json` with the following content:

```json
{
  "Name": "flights_data",
  "StorageDescriptor": {
    "Columns": [
      {
        "Name": "year",
        "Type": "bigint"
      },
      {
        "Name": "quarter",
        "Type": "bigint"
      }
    ],
    "Location": "s3://amzn-s3-demo-bucket/flight/2016/csv",
    "InputFormat": "org.apache.hadoop.mapred.TextInputFormat",
    "OutputFormat": "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat",
    "Compressed": false,
    "NumberOfBuckets": -1,
    "SerdeInfo": {
      "SerializationLibrary": "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe",
      "Parameters": {
        "field.delim": ",",
        "serialization.format": ","
      }
    }
  },
  "PartitionKeys": [
    {
      "Name": "mon",
      "Type": "string"
    }
  ],
  "TableType": "EXTERNAL_TABLE",
  "Parameters": {
    "EXTERNAL": "TRUE",
    "classification": "csv",
    "columnsOrdered": "true",
    "compressionType": "none",
    "delimiter": ",",
    "skip.header.line.count": "1",
    "typeOfData": "file"
  }
}
```

This JSON defines a table named "flights_data" with two columns: "year" and "quarter", both of type "bigint". It also defines a partition key "mon" of type "string". The table references CSV data stored in an Amazon S3 bucket.

**Create the table**

Now, create the table using the AWS CLI:

```
$ aws glue create-table --database-name tutorial_database --table-input file://table-input.json
```

This command creates a table in the specified database using the table definition from the JSON file.

**Verify the table was created**

To verify that your table was created successfully, use the following command:

```
$ aws glue get-table --database-name tutorial_database --name flights_data
{
    "Table": {
        "Name": "flights_data",
        "DatabaseName": "tutorial_database",
        "CreateTime": "2025-01-13T12:00:00.000Z",
        "UpdateTime": "2025-01-13T12:00:00.000Z",
        "Retention": 0,
        "StorageDescriptor": {
            "Columns": [
                {
                    "Name": "year",
                    "Type": "bigint"
                },
                {
                    "Name": "quarter",
                    "Type": "bigint"
                }
            ],
            "Location": "s3://amzn-s3-demo-bucket/flight/2016/csv",
            "InputFormat": "org.apache.hadoop.mapred.TextInputFormat",
            "OutputFormat": "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat",
            "Compressed": false,
            "NumberOfBuckets": -1,
            "SerdeInfo": {
                "SerializationLibrary": "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe",
                "Parameters": {
                    "field.delim": ",",
                    "serialization.format": ","
                }
            },
            "SortColumns": [],
            "StoredAsSubDirectories": false
        },
        "PartitionKeys": [
            {
                "Name": "mon",
                "Type": "string"
            }
        ],
        "TableType": "EXTERNAL_TABLE",
        "Parameters": {
            "EXTERNAL": "TRUE",
            "classification": "csv",
            "columnsOrdered": "true",
            "compressionType": "none",
            "delimiter": ",",
            "skip.header.line.count": "1",
            "typeOfData": "file"
        },
        "CreatedBy": "arn:aws:iam::123456789012:user/example-user",
        "IsRegisteredWithLakeFormation": false,
        "CatalogId": "123456789012"
    }
}
```

The output shows the details of your newly created table, including its name, database, columns, location, and other properties.

## Explore the Data Catalog

Now that you have created a database and a table, you can explore the Data Catalog to see what's available.

**List tables in a database**

To list all tables in a database, use the following command:

```
$ aws glue get-tables --database-name tutorial_database
{
    "TableList": [
        {
            "Name": "flights_data",
            "DatabaseName": "tutorial_database",
            "CreateTime": "2025-01-13T12:00:00.000Z",
            "UpdateTime": "2025-01-13T12:00:00.000Z",
            "Retention": 0,
            "StorageDescriptor": {
                "Columns": [
                    {
                        "Name": "year",
                        "Type": "bigint"
                    },
                    {
                        "Name": "quarter",
                        "Type": "bigint"
                    }
                ],
                "Location": "s3://amzn-s3-demo-bucket/flight/2016/csv",
                "InputFormat": "org.apache.hadoop.mapred.TextInputFormat",
                "OutputFormat": "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat",
                "Compressed": false,
                "NumberOfBuckets": -1,
                "SerdeInfo": {
                    "SerializationLibrary": "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe",
                    "Parameters": {
                        "field.delim": ",",
                        "serialization.format": ","
                    }
                },
                "SortColumns": [],
                "StoredAsSubDirectories": false
            },
            "PartitionKeys": [
                {
                    "Name": "mon",
                    "Type": "string"
                }
            ],
            "TableType": "EXTERNAL_TABLE",
            "Parameters": {
                "EXTERNAL": "TRUE",
                "classification": "csv",
                "columnsOrdered": "true",
                "compressionType": "none",
                "delimiter": ",",
                "skip.header.line.count": "1",
                "typeOfData": "file"
            },
            "CreatedBy": "arn:aws:iam::123456789012:user/example-user",
            "IsRegisteredWithLakeFormation": false,
            "CatalogId": "123456789012"
        }
    ]
}
```

The output shows all tables in the specified database, including their details.

**Search for tables**

You can also search for tables across all databases using the `search-tables` command:

```
$ aws glue search-tables --search-text flights
{
    "TableList": [
        {
            "Name": "flights_data",
            "DatabaseName": "tutorial_database",
            "CreateTime": "2025-01-13T12:00:00.000Z",
            "UpdateTime": "2025-01-13T12:00:00.000Z",
            "Retention": 0,
            "StorageDescriptor": {
                "Columns": [
                    {
                        "Name": "year",
                        "Type": "bigint"
                    },
                    {
                        "Name": "quarter",
                        "Type": "bigint"
                    }
                ],
                "Location": "s3://amzn-s3-demo-bucket/flight/2016/csv",
                "InputFormat": "org.apache.hadoop.mapred.TextInputFormat",
                "OutputFormat": "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat",
                "Compressed": false,
                "NumberOfBuckets": -1,
                "SerdeInfo": {
                    "SerializationLibrary": "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe",
                    "Parameters": {
                        "field.delim": ",",
                        "serialization.format": ","
                    }
                },
                "SortColumns": [],
                "StoredAsSubDirectories": false
            },
            "PartitionKeys": [
                {
                    "Name": "mon",
                    "Type": "string"
                }
            ],
            "TableType": "EXTERNAL_TABLE",
            "Parameters": {
                "EXTERNAL": "TRUE",
                "classification": "csv",
                "columnsOrdered": "true",
                "compressionType": "none",
                "delimiter": ",",
                "skip.header.line.count": "1",
                "typeOfData": "file"
            },
            "CreatedBy": "arn:aws:iam::123456789012:user/example-user",
            "IsRegisteredWithLakeFormation": false,
            "CatalogId": "123456789012"
        }
    ]
}
```

This command searches for tables that match the specified text across all databases in your Data Catalog.

## Clean up resources

To avoid unnecessary charges, you should clean up the resources you created in this tutorial when you're done.

**Delete the table**

To delete the table, use the following command:

```
$ aws glue delete-table --database-name tutorial_database --name flights_data
```

This command deletes the specified table from the database. There is no output if the command is successful.

**Delete the database**

To delete the database, use the following command:

```
$ aws glue delete-database --name tutorial_database
```

This command deletes the specified database from the Data Catalog. There is no output if the command is successful.

**Verify resources are deleted**

To verify that the resources were deleted, you can try to retrieve them:

```
$ aws glue get-database --name tutorial_database
```

If the database was successfully deleted, you should see an error message indicating that the database does not exist.

## Going to production

This tutorial is designed to help you learn how to use the AWS CLI to manage AWS Glue Data Catalog resources. When implementing these operations in a production environment, consider the following best practices:

### Security Best Practices

1. **Use Least Privilege IAM Policies**: Create IAM policies that grant only the permissions needed for specific operations. For example:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "glue:CreateDatabase",
           "glue:GetDatabase",
           "glue:GetDatabases",
           "glue:CreateTable",
           "glue:GetTable",
           "glue:GetTables",
           "glue:SearchTables",
           "glue:DeleteTable",
           "glue:DeleteDatabase"
         ],
         "Resource": "*"
       }
     ]
   }
   ```

2. **Enable Encryption**: Consider enabling encryption for your Data Catalog to protect sensitive metadata.

3. **Use AWS Lake Formation**: For fine-grained access control to your Data Catalog resources, consider using AWS Lake Formation.

### Architecture Best Practices

1. **Automation**: Use AWS CloudFormation or Terraform to automate the creation and management of Data Catalog resources instead of manual CLI commands.

2. **Resource Organization**: Implement a comprehensive tagging strategy to organize and track your Data Catalog resources.

3. **Partition Management**: For large datasets, implement proper partition management strategies to optimize query performance.

4. **Schema Evolution**: Plan for schema evolution and implement strategies for handling changes to table schemas over time.

For more information on building production-ready solutions, refer to:

- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [AWS Security Best Practices](https://aws.amazon.com/architecture/security-identity-compliance/)
- [AWS Glue Best Practices](https://docs.aws.amazon.com/glue/latest/dg/best-practices.html)

## Next steps

Now that you've learned how to create and manage AWS Glue Data Catalog resources using the AWS CLI, you can explore more advanced features:

- [Create and run a crawler](https://docs.aws.amazon.com/glue/latest/dg/add-crawler.html) to automatically discover and catalog data
- [Create ETL jobs](https://docs.aws.amazon.com/glue/latest/dg/author-job-glue.html) to transform your data
- [Set up triggers](https://docs.aws.amazon.com/glue/latest/dg/trigger-job.html) to automate your ETL workflows
- [Use the AWS Glue Schema Registry](https://docs.aws.amazon.com/glue/latest/dg/schema-registry.html) to manage and enforce schemas for your data
- [Integrate with AWS Lake Formation](https://docs.aws.amazon.com/lake-formation/latest/dg/what-is-lake-formation.html) for fine-grained access control

## Troubleshooting

Here are some common issues you might encounter when working with the AWS Glue Data Catalog and how to resolve them:

**Error: Database already exists**

If you try to create a database that already exists, you'll see an error like this:
```
An error occurred (AlreadyExistsException) when calling the CreateDatabase operation: Database tutorial_database already exists.
```

To resolve this, either use a different database name or delete the existing database first.

**Error: Table already exists**

Similarly, if you try to create a table that already exists in the specified database, you'll see an error like this:
```
An error occurred (AlreadyExistsException) when calling the CreateTable operation: Table flights_data already exists.
```

To resolve this, either use a different table name or delete the existing table first.

**Error: Cannot delete database with tables**

If you try to delete a database that still contains tables, you'll see an error like this:
```
An error occurred (InvalidInputException) when calling the DeleteDatabase operation: Cannot delete database tutorial_database because it contains tables.
```

To resolve this, delete all tables in the database before deleting the database itself.
