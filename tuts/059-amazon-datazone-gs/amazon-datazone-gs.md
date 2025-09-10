# Getting started with Amazon DataZone using the AWS CLI

This tutorial guides you through setting up and using Amazon DataZone using the AWS Command Line Interface (AWS CLI). You'll learn how to create a domain, set up projects, create environments, and work with data assets.

## Topics

* [Prerequisites](#prerequisites)
* [Create an Amazon DataZone domain](#create-an-amazon-datazone-domain)
* [Create projects](#create-projects)
* [Create an environment profile and environment](#create-an-environment-profile-and-environment)
* [Create a data source for AWS Glue](#create-a-data-source-for-aws-glue)
* [Create and publish custom assets](#create-and-publish-custom-assets)
* [Search for assets and subscribe](#search-for-assets-and-subscribe)
* [Clean up resources](#clean-up-resources)
* [Going to production](#going-to-production)
* [Next steps](#next-steps)

## Prerequisites

Before you begin this tutorial, make sure you have the following:

1. The AWS CLI. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
2. Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
3. [Sufficient permissions](https://docs.aws.amazon.com/datazone/latest/userguide/create-iam-roles.html) to create and manage Amazon DataZone resources in your AWS account.
4. If you are using an AWS account with existing AWS Glue Data Catalog objects, you must also configure [Lake Formation permissions for Amazon DataZone](https://docs.aws.amazon.com/datazone/latest/userguide/lake-formation-permissions-for-datazone.html).

### Cost considerations

The resources created in this tutorial will incur costs as long as they exist in your AWS account. The estimated cost for running these resources for one hour is approximately $1.11. If left running for a full month, the cost would be approximately $810.30. The most expensive component is the DataZone domain itself ($0.50/hour).

To avoid unnecessary charges, make sure to follow the [Clean up resources](#clean-up-resources) section at the end of this tutorial to delete all resources when you're done.

Let's get started with creating and managing Amazon DataZone resources using the CLI.

## Create an Amazon DataZone domain

A domain is the primary container for all your Amazon DataZone resources. In this section, you'll create a domain and the necessary IAM role.

**Create a domain execution role**

Before creating a domain, you need to create an IAM role that Amazon DataZone can assume to perform operations on your behalf. The following commands create the necessary role and attach the required policies.

```bash
# Create trust policy document
cat > trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "datazone.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Create the role
aws iam create-role --role-name AmazonDataZoneDomainExecutionRole --assume-role-policy-document file://trust-policy.json

# Attach necessary policies
aws iam attach-role-policy --role-name AmazonDataZoneDomainExecutionRole --policy-arn "arn:aws:iam::aws:policy/AmazonDataZoneFullAccess"
```

The trust policy allows the Amazon DataZone service to assume this role. The attached policy grants the necessary permissions for Amazon DataZone to manage resources on your behalf.

**Create a domain**

Now that you have the necessary role, you can create an Amazon DataZone domain using the following command:

```bash
# Get your AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Create the domain
aws datazone create-domain \
  --name "MyDataZoneDomain" \
  --description "My first DataZone domain" \
  --domain-execution-role "arn:aws:iam::$ACCOUNT_ID:role/AmazonDataZoneDomainExecutionRole"
```

The command returns a response with details about the domain creation operation, including a domain identifier. Make note of this identifier as you'll need it for subsequent commands.

**Get domain details**

You can verify that your domain was created successfully and check its status using the following command:

```bash
aws datazone get-domain --identifier "dzd_abcd1234"
```

Replace `dzd_abcd1234` with your actual domain identifier. The domain status should be `AVAILABLE` before proceeding to the next steps.

## Create projects

Projects in Amazon DataZone help organize your data assets and manage access. In this section, you'll create two projects: one for publishing data and one for consuming data.

**Create a publishing project**

The following command creates a project for publishing data:

```bash
aws datazone create-project \
  --domain-identifier "dzd_abcd1234" \
  --name "PublishingProject"
```

The command returns a response with details about the project, including a project identifier. Make note of this identifier for later use.

**Create a consumer project**

Now, create a second project that will be used to subscribe to data:

```bash
aws datazone create-project \
  --domain-identifier "dzd_abcd1234" \
  --name "ConsumerProject"
```

Again, make note of the project identifier returned in the response.

**List projects**

You can list all projects in your domain to verify that both projects were created successfully:

```bash
aws datazone list-projects --domain-identifier "dzd_abcd1234"
```

This command returns a list of all projects in your domain, including their names and identifiers.

## Create an environment profile and environment

Environment profiles define the AWS accounts and regions where your DataZone environments can be created. Environments are the actual runtime contexts where your data assets are managed.

**List environment blueprints**

First, list the available environment blueprints:

```bash
aws datazone list-environment-blueprints \
  --domain-identifier "dzd_abcd1234"
```

This command returns a list of available environment blueprints. Note the identifier of the blueprint you want to use, typically the DefaultDataLake blueprint.

**Create an environment profile**

Now, create an environment profile using the blueprint:

```bash
# Get your AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

aws datazone create-environment-profile \
  --description "DataLake environment profile" \
  --domain-identifier "dzd_abcd1234" \
  --aws-account-id "$ACCOUNT_ID" \
  --aws-account-region "us-east-1" \
  --environment-blueprint-identifier "dzeb_abcd1234" \
  --name "DataLakeProfile" \
  --project-identifier "dzp_abcd1234"
```

Replace `dzeb_abcd1234` with the actual blueprint identifier and `dzp_abcd1234` with your publishing project identifier. The command returns details about the environment profile, including its identifier.

**Create an environment**

Now, create an actual environment using the profile:

```bash
aws datazone create-environment \
  --description "DataLake environment for data publishing" \
  --domain-identifier "dzd_abcd1234" \
  --environment-profile-identifier "dzep_abcd1234" \
  --name "DataLakeEnvironment" \
  --project-identifier "dzp_abcd1234"
```

Replace `dzep_abcd1234` with your environment profile identifier and `dzp_abcd1234` with your publishing project identifier. The command returns details about the environment, including its identifier.

**Get environment status**

You can check the status of your environment using the following command:

```bash
aws datazone get-environment \
  --domain-identifier "dzd_abcd1234" \
  --identifier "dze_abcd1234" \
  --project-identifier "dzp_abcd1234"
```

Replace `dze_abcd1234` with your environment identifier. The environment status should be `ACTIVE` before proceeding to the next steps.

## Create a data source for AWS Glue

Data sources in Amazon DataZone allow you to import metadata from external systems like AWS Glue. In this section, you'll set up a data source to import metadata from AWS Glue.

**Create a Glue access role**

First, create an IAM role that Amazon DataZone can use to access your AWS Glue resources:

```bash
# Get your AWS account ID and region
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=$(aws configure get region)
DOMAIN_ID="dzd_abcd1234"

# Create trust policy document
cat > glue-trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "datazone.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Create policy document with scoped permissions
cat > glue-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "glue:GetDatabase",
        "glue:GetDatabases"
      ],
      "Resource": [
        "arn:aws:glue:*:$ACCOUNT_ID:catalog",
        "arn:aws:glue:*:$ACCOUNT_ID:database/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "glue:GetTable",
        "glue:GetTables",
        "glue:GetPartition",
        "glue:GetPartitions"
      ],
      "Resource": [
        "arn:aws:glue:*:$ACCOUNT_ID:catalog",
        "arn:aws:glue:*:$ACCOUNT_ID:database/*",
        "arn:aws:glue:*:$ACCOUNT_ID:table/*/*"
      ]
    }
  ]
}
EOF

# Create the role
GLUE_ROLE_NAME="AmazonDataZoneGlueAccess-$REGION-$DOMAIN_ID"
aws iam create-role --role-name "$GLUE_ROLE_NAME" --assume-role-policy-document file://glue-trust-policy.json

# Attach policy
aws iam put-role-policy --role-name "$GLUE_ROLE_NAME" --policy-name "DataZoneGlueAccess" --policy-document file://glue-policy.json
```

Replace `dzd_abcd1234` with your domain identifier. This creates a role with the necessary permissions to access AWS Glue resources.

**Create a data source**

Now, create a data source that imports metadata from AWS Glue:

```bash
# Get your AWS account ID and region
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=$(aws configure get region)
DOMAIN_ID="dzd_abcd1234"
PROJECT_ID="dzp_abcd1234"
ENVIRONMENT_ID="dze_abcd1234"
GLUE_DB_NAME="my-glue-database"
GLUE_ROLE_NAME="AmazonDataZoneGlueAccess-$REGION-$DOMAIN_ID"

# Create data source configuration
cat > data-source-config.json << EOF
{
  "glueRunConfiguration": {
    "dataAccessRole": "arn:aws:iam::$ACCOUNT_ID:role/$GLUE_ROLE_NAME",
    "relationalFilterConfigurations": [
      {
        "databaseName": "$GLUE_DB_NAME",
        "filterExpressions": [
          {"expression": "*", "type": "INCLUDE"}
        ]
      }
    ]
  }
}
EOF

# Create data source
aws datazone create-data-source \
  --name "GlueDataSource" \
  --description "Data source for AWS Glue metadata" \
  --domain-identifier "$DOMAIN_ID" \
  --environment-identifier "$ENVIRONMENT_ID" \
  --project-identifier "$PROJECT_ID" \
  --enable-setting "ENABLED" \
  --publish-on-import false \
  --recommendation '{"enableBusinessNameGeneration": true}' \
  --type "GLUE" \
  --configuration file://data-source-config.json \
  --schedule '{"schedule": "cron(0 0 * * ? *)", "timezone": "UTC"}'
```

Replace `dzd_abcd1234`, `dzp_abcd1234`, `dze_abcd1234`, and `my-glue-database` with your actual values. This command creates a data source that will import metadata from the specified AWS Glue database on a daily schedule.

## Create and publish custom assets

In addition to importing metadata from external sources, you can create custom assets in Amazon DataZone. In this section, you'll create a custom form type, asset type, and asset.

**Create a custom form type**

First, create a custom form type that defines the structure of your asset metadata:

```bash
aws datazone create-form-type \
  --domain-identifier "dzd_abcd1234" \
  --name "CustomDataForm" \
  --model '{"smithy": "structure CustomDataForm { description: String, owner: String }"}' \
  --owning-project-identifier "dzp_abcd1234" \
  --status "ENABLED"
```

Replace `dzd_abcd1234` and `dzp_abcd1234` with your domain and project identifiers. The command returns details about the form type, including its identifier.

**Create a custom asset type**

Now, create a custom asset type that uses your form type:

```bash
# Create forms input JSON
cat > forms-input.json << EOF
{
  "CustomDataForm": {
    "typeIdentifier": "dft_abcd1234",
    "typeRevision": "1",
    "required": true
  }
}
EOF

aws datazone create-asset-type \
  --domain-identifier "dzd_abcd1234" \
  --name "CustomDataAssetType" \
  --forms-input file://forms-input.json \
  --owning-project-identifier "dzp_abcd1234"
```

Replace `dft_abcd1234`, `dzd_abcd1234`, and `dzp_abcd1234` with your actual values. The command returns details about the asset type, including its identifier.

**Create a custom asset**

Now, create a custom asset using your asset type:

```bash
# Create forms input JSON for asset
cat > asset-forms-input.json << EOF
[
  {
    "formName": "CustomDataForm",
    "typeIdentifier": "dft_abcd1234",
    "content": "{\"description\":\"Sample data for analysis\",\"owner\":\"Data Team\"}"
  }
]
EOF

aws datazone create-asset \
  --domain-identifier "dzd_abcd1234" \
  --name "MyCustomAsset" \
  --description "A custom data asset" \
  --owning-project-identifier "dzp_abcd1234" \
  --type-identifier "dat_abcd1234" \
  --forms-input file://asset-forms-input.json
```

Replace `dft_abcd1234`, `dzd_abcd1234`, `dzp_abcd1234`, and `dat_abcd1234` with your actual values. The command returns details about the asset, including its identifier.

**Publish the asset**

Finally, publish the asset to make it discoverable by other users:

```bash
aws datazone create-listing-change-set \
  --domain-identifier "dzd_abcd1234" \
  --entity-identifier "dza_abcd1234" \
  --entity-type "ASSET" \
  --action "PUBLISH"
```

Replace `dzd_abcd1234` and `dza_abcd1234` with your domain and asset identifiers. The command returns details about the listing, including its identifier.

## Search for assets and subscribe

Once assets are published, users can search for them and request access. In this section, you'll search for assets and create a subscription request.

**Search for assets**

Use the following command to search for assets in the catalog:

```bash
aws datazone search-listings \
  --domain-identifier "dzd_abcd1234" \
  --search-text "custom data"
```

Replace `dzd_abcd1234` with your domain identifier. The command returns a list of assets that match your search criteria.

**Create a subscription request**

Now, create a subscription request to access an asset:

```bash
# Create subscription request JSON
cat > subscription-request.json << EOF
{
  "domainIdentifier": "dzd_abcd1234",
  "subscribedPrincipals": [
    {
      "project": {
        "identifier": "dzp_consumer1234"
      }
    }
  ],
  "subscribedListings": [
    {
      "identifier": "dzl_abcd1234"
    }
  ],
  "requestReason": "Need this data for analysis"
}
EOF

aws datazone create-subscription-request \
  --cli-input-json file://subscription-request.json
```

Replace `dzd_abcd1234`, `dzp_consumer1234`, and `dzl_abcd1234` with your domain, consumer project, and listing identifiers. The command returns details about the subscription request, including its identifier.

**Accept the subscription request**

As a data owner, you can accept the subscription request:

```bash
aws datazone accept-subscription-request \
  --domain-identifier "dzd_abcd1234" \
  --identifier "dzsr_abcd1234"
```

Replace `dzd_abcd1234` and `dzsr_abcd1234` with your domain and subscription request identifiers. The command returns details about the accepted subscription.

## Clean up resources

When you're finished with your Amazon DataZone resources, you should delete them to avoid incurring additional charges. This section shows you how to clean up all the resources created in this tutorial.

**Delete subscription request**

```bash
aws datazone delete-subscription-request \
  --domain-identifier "dzd_abcd1234" \
  --identifier "dzsr_abcd1234"
```

**Delete asset**

```bash
aws datazone delete-asset \
  --domain-identifier "dzd_abcd1234" \
  --identifier "dza_abcd1234"
```

**Delete asset type**

```bash
aws datazone delete-asset-type \
  --domain-identifier "dzd_abcd1234" \
  --identifier "dat_abcd1234"
```

**Delete form type**

```bash
aws datazone delete-form-type \
  --domain-identifier "dzd_abcd1234" \
  --identifier "dft_abcd1234"
```

**Delete data source**

```bash
aws datazone delete-data-source \
  --domain-identifier "dzd_abcd1234" \
  --identifier "dzds_abcd1234"
```

**Delete environment**

```bash
aws datazone delete-environment \
  --domain-identifier "dzd_abcd1234" \
  --identifier "dze_abcd1234"
```

**Delete environment profile**

```bash
aws datazone delete-environment-profile \
  --domain-identifier "dzd_abcd1234" \
  --identifier "dzep_abcd1234"
```

**Delete projects**

```bash
aws datazone delete-project \
  --domain-identifier "dzd_abcd1234" \
  --identifier "dzp_consumer1234"

aws datazone delete-project \
  --domain-identifier "dzd_abcd1234" \
  --identifier "dzp_abcd1234"
```

**Delete domain**

```bash
aws datazone delete-domain \
  --identifier "dzd_abcd1234"
```

Replace all identifiers with your actual values. These commands delete all the resources created in this tutorial.

## Going to production

This tutorial is designed to help you learn how to use Amazon DataZone with the AWS CLI. For production environments, consider the following best practices:

### Security best practices

1. **Follow the principle of least privilege**: Create custom IAM policies that grant only the specific permissions needed for your operations, rather than using the broad managed policies shown in this tutorial.

2. **Implement resource-level permissions**: Scope down permissions to specific resources rather than using wildcards (`*`) in IAM policies.

3. **Configure encryption**: Use AWS KMS keys to encrypt your DataZone resources.

4. **Set up logging and monitoring**: Configure AWS CloudTrail to log DataZone API calls and set up Amazon CloudWatch alarms for suspicious activities.

5. **Implement resource tagging**: Add tags to all resources for better tracking and management.

### Architecture best practices

1. **Use Infrastructure as Code**: Instead of manual CLI commands, use AWS CloudFormation or Terraform to manage your DataZone resources.

2. **Implement automation**: Automate resource creation, monitoring, and cleanup processes.

3. **Consider multi-region strategies**: For critical DataZone resources, consider multi-region deployments for better reliability.

4. **Implement backup strategies**: Regularly back up your DataZone metadata.

5. **Set up cost monitoring**: Use AWS Budgets or Cost Explorer to monitor and control your DataZone costs.

For more information on AWS best practices, refer to:

- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [AWS Security Best Practices](https://aws.amazon.com/architecture/security-identity-compliance/)
- [AWS Cost Optimization](https://aws.amazon.com/architecture/cost-optimization/)

## Next steps

Now that you've learned the basics of managing Amazon DataZone resources using the AWS CLI, explore other features:

1. **Data Catalog** – [Browse and discover data assets](https://docs.aws.amazon.com/datazone/latest/userguide/data-catalog.html) in your organization.
2. **Glossaries** – [Create and manage business glossaries](https://docs.aws.amazon.com/datazone/latest/userguide/glossary.html) to standardize terminology.
3. **Data lineage** – [Track data origins and transformations](https://docs.aws.amazon.com/datazone/latest/userguide/lineage.html) to understand data flow.
4. **Data quality** – [Monitor and improve data quality](https://docs.aws.amazon.com/datazone/latest/userguide/data-quality.html) across your organization.
5. **Governance** – [Implement data governance policies](https://docs.aws.amazon.com/datazone/latest/userguide/governance.html) to ensure compliance and security.

For more information about available AWS CLI commands for Amazon DataZone, see the [AWS CLI Command Reference for Amazon DataZone](https://docs.aws.amazon.com/cli/latest/reference/datazone/index.html).
