# Getting started with Amazon ElastiCache using the AWS CLI

This tutorial guides you through the process of creating, using, and managing an Amazon ElastiCache serverless cache using the AWS Command Line Interface (AWS CLI). You'll learn how to create a Valkey serverless cache, connect to it, and perform basic operations.

## Topics

- [Prerequisites](#prerequisites)
- [Set up security group for ElastiCache access](#set-up-security-group-for-elasticache-access)
- [Create a Valkey serverless cache](#create-a-valkey-serverless-cache)
- [Connect to your cache](#connect-to-your-cache)
- [Clean up resources](#clean-up-resources)
- [Going to production](#going-to-production)
- [Next steps](#next-steps)

## Prerequisites

Before you begin this tutorial, make sure you have the following:

1. The AWS CLI. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
2. Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
3. An Amazon EC2 instance in the same VPC as your ElastiCache cache for connecting to the cache. By default, ElastiCache creates caches in your default VPC.
4. Basic familiarity with command line interfaces and caching concepts.
5. [Sufficient permissions](https://docs.aws.amazon.com/AmazonElastiCache/latest/dg/IAM.IdentityBasedPolicies.PredefinedPolicies.html) to create and manage ElastiCache resources in your AWS account.

**Time to complete:** Approximately 30 minutes

**Cost estimate:** Running the resources in this tutorial for one hour costs approximately $0.97. This includes the cost of an ElastiCache serverless cache with default settings. The actual cost may be lower if the cache is not actively used. The cleanup section will guide you through deleting resources to avoid ongoing charges.

Let's get started with creating and managing Amazon ElastiCache resources using the CLI.

## Set up security group for ElastiCache access

ElastiCache serverless uses ports 6379 and 6380 for Valkey and Redis OSS. Before creating a cache, you need to configure your security group to allow access to these ports.

**Get your default security group ID**

First, identify the default security group in your VPC:

```
$ SG_ID=$(aws ec2 describe-security-groups \
  --filters Name=group-name,Values=default \
  --query "SecurityGroups[0].GroupId" \
  --output text)

$ echo $SG_ID
sg-abcd1234
```

This command retrieves the ID of the default security group and stores it in the `SG_ID` variable for later use.

**Add inbound rules for ElastiCache ports**

For this tutorial, we'll add rules that allow your EC2 instance to access the ElastiCache ports. First, get your EC2 instance's security group ID:

```
$ EC2_SG_ID=$(aws ec2 describe-instances \
  --instance-ids i-1234xmplabcd \
  --query "Reservations[0].Instances[0].SecurityGroups[0].GroupId" \
  --output text)

$ echo $EC2_SG_ID
sg-abcd5678
```

Now, add inbound rules to allow traffic from your EC2 instance's security group:

```
$ aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 6379 \
  --source-group $EC2_SG_ID

{
    "Return": true,
    "SecurityGroupRules": [
        {
            "SecurityGroupRuleId": "sgr-abcd1234xmpl",
            "GroupId": "sg-abcd1234",
            "IpProtocol": "tcp",
            "FromPort": 6379,
            "ToPort": 6379,
            "ReferencedGroupInfo": {
                "GroupId": "sg-abcd5678"
            }
        }
    ]
}

$ aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 6380 \
  --source-group $EC2_SG_ID

{
    "Return": true,
    "SecurityGroupRules": [
        {
            "SecurityGroupRuleId": "sgr-abcd1234xmpl",
            "GroupId": "sg-abcd1234",
            "IpProtocol": "tcp",
            "FromPort": 6380,
            "ToPort": 6380,
            "ReferencedGroupInfo": {
                "GroupId": "sg-abcd5678"
            }
        }
    ]
}
```

These commands add rules to allow inbound traffic on ports 6379 and 6380 from your EC2 instance's security group, which is more secure than allowing access from any IP address.

## Create a Valkey serverless cache

Now that you've configured the security group, you can create an ElastiCache serverless cache with the Valkey engine.

**Create the cache**

Use the `create-serverless-cache` command to create a new cache:

```
$ aws elasticache create-serverless-cache \
  --serverless-cache-name my-valkey-cache \
  --engine valkey \
  --tags Key=Project,Value=Tutorial

{
    "ServerlessCache": {
        "ServerlessCacheName": "my-valkey-cache",
        "Description": "",
        "CreateTime": "2025-01-13T12:00:00.000Z",
        "Status": "CREATING",
        "Engine": "valkey",
        "MajorEngineVersion": "8",
        "FullEngineVersion": "valkey 8.0.0",
        "CacheUsageLimits": {
            "DataStorage": {
                "Maximum": 10,
                "Minimum": 0,
                "Unit": "GB"
            },
            "ECPUPerSecond": {
                "Maximum": 100000,
                "Minimum": 1000
            }
        },
        "SecurityGroupIds": [],
        "Endpoint": {
            "Address": "my-valkey-cache-abcd1234xmpl.serverless.use1.cache.amazonaws.com",
            "Port": 6379
        },
        "ARN": "arn:aws:elasticache:us-east-1:123456789012:serverlesscache:my-valkey-cache",
        "SubnetIds": []
    }
}
```

This command creates a new serverless cache named "my-valkey-cache" using the Valkey engine and adds a tag for better resource management. The initial status is `CREATING` as ElastiCache provisions the resources.

**Check the status of the cache creation**

Wait for the cache to become available before attempting to use it:

```
$ aws elasticache describe-serverless-caches \
  --serverless-cache-name my-valkey-cache \
  --query "ServerlessCaches[0].Status"

`AVAILABLE`
```

You can run this command periodically until the status changes from `CREATING` to `AVAILABLE`. This typically takes a few minutes.

## Connect to your cache

Once your cache is available, you can connect to it and start using it.

**Find your cache endpoint**

First, retrieve the endpoint for your ElastiCache cache:

```
$ aws elasticache describe-serverless-caches \
  --serverless-cache-name my-valkey-cache \
  --query "ServerlessCaches[0].Endpoint.Address" \
  --output text

my-valkey-cache-abcd1234xmpl.serverless.use1.cache.amazonaws.com
```

This command extracts just the endpoint address from the cache description, which you'll need to connect to the cache.

**Install valkey-cli on your EC2 instance**

To interact with your Valkey cache, you need to install the valkey-cli utility on your EC2 instance. Connect to your EC2 instance and run the following commands:

```
$ sudo amazon-linux-extras install epel -y
$ sudo yum install gcc jemalloc-devel openssl-devel tcl tcl-devel -y
$ wget https://github.com/valkey-io/valkey/archive/refs/tags/8.0.0.tar.gz
$ tar xvzf 8.0.0.tar.gz
$ cd valkey-8.0.0
$ make BUILD_TLS=yes
```

These commands install the necessary dependencies and build the valkey-cli utility with TLS support, which is required for connecting to ElastiCache serverless caches.

**Connect to your cache and perform operations**

Now you can connect to your cache using the valkey-cli utility:

```
$ cd valkey-8.0.0
$ src/valkey-cli -h my-valkey-cache-abcd1234xmpl.serverless.use1.cache.amazonaws.com --tls -p 6379
```

Once connected, you can run Valkey commands to read and write data:

```
my-valkey-cache-abcd1234xmpl.serverless.use1.cache.amazonaws.com:6379> set mykey "Hello ElastiCache"
OK
my-valkey-cache-abcd1234xmpl.serverless.use1.cache.amazonaws.com:6379> get mykey
"Hello ElastiCache"
my-valkey-cache-abcd1234xmpl.serverless.use1.cache.amazonaws.com:6379> exit
```

These commands set a key named "mykey" with the value "Hello ElastiCache" and then retrieve the value of that key.

## Clean up resources

When you're done with the tutorial, you can delete the resources you created to avoid incurring charges.

**Delete the cache**

Delete your ElastiCache serverless cache:

```
$ aws elasticache delete-serverless-cache \
  --serverless-cache-name my-valkey-cache

{
    "ServerlessCache": {
        "ServerlessCacheName": "my-valkey-cache",
        "Description": "",
        "CreateTime": "2025-01-13T12:00:00.000Z",
        "Status": "DELETING",
        "Engine": "valkey",
        "MajorEngineVersion": "8",
        "FullEngineVersion": "valkey 8.0.0",
        "CacheUsageLimits": {
            "DataStorage": {
                "Maximum": 10,
                "Minimum": 0,
                "Unit": "GB"
            },
            "ECPUPerSecond": {
                "Maximum": 100000,
                "Minimum": 1000
            }
        },
        "SecurityGroupIds": [],
        "Endpoint": {
            "Address": "my-valkey-cache-abcd1234xmpl.serverless.use1.cache.amazonaws.com",
            "Port": 6379
        },
        "ARN": "arn:aws:elasticache:us-east-1:123456789012:serverlesscache:my-valkey-cache",
        "SubnetIds": []
    }
}
```

This command initiates the deletion of your cache. The status changes to `DELETING` and ElastiCache begins the cleanup process.

**Verify cache deletion**

You can verify that the cache has been deleted by checking if it still appears in the list of caches:

```
$ aws elasticache describe-serverless-caches \
  --serverless-cache-name my-valkey-cache

An error occurred (CacheServerlessNotFoundException) when calling the DescribeServerlessCaches operation: Serverless Cache my-valkey-cache not found.
```

When you receive this error, it means the cache has been successfully deleted.

**Remove security group rules**

Remove the security group rules you added for ElastiCache:

```
$ aws ec2 revoke-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 6379 \
  --source-group $EC2_SG_ID

{
    "Return": true
}

$ aws ec2 revoke-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 6380 \
  --source-group $EC2_SG_ID

{
    "Return": true
}
```

These commands remove the inbound rules for ports 6379 and 6380 that you added at the beginning of the tutorial.

## Going to production

This tutorial is designed to help you learn how to use the ElastiCache API with the AWS CLI. For production deployments, consider the following best practices:

### Security considerations

1. **User authentication**: Configure user authentication for your cache using the `--user-group-id` parameter when creating the cache.
2. **Network security**: Use VPC endpoints or private subnets to isolate your cache from the public internet.
3. **Least privilege access**: Create IAM policies that grant only the permissions needed for your application to interact with ElastiCache.

### Reliability and performance

1. **Monitoring**: Set up CloudWatch alarms to monitor cache performance metrics like CPU utilization, memory usage, and connection count.
2. **Connection pooling**: Implement connection pooling in your application to efficiently manage connections to the cache.
3. **Error handling**: Design your application to handle cache failures gracefully, with appropriate retry logic and fallback mechanisms.

### Cost optimization

1. **Right-sizing**: Adjust the cache usage limits based on your workload requirements to avoid over-provisioning.
2. **Cache eviction policies**: Understand how ElastiCache handles memory pressure and configure appropriate TTL values for your data.

For more information on building production-ready applications with ElastiCache, refer to the [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html) and [ElastiCache Best Practices](https://docs.aws.amazon.com/AmazonElastiCache/latest/dg/BestPractices.html).

## Next steps

Now that you've learned the basics of creating and using an ElastiCache serverless cache, you can explore more advanced features:

- [Learn about ElastiCache serverless architecture](https://docs.aws.amazon.com/AmazonElastiCache/latest/dg/serverless-overview.html)
- [Explore different caching strategies](https://docs.aws.amazon.com/AmazonElastiCache/latest/dg/Strategies.html)
- [Configure user access control](https://docs.aws.amazon.com/AmazonElastiCache/latest/dg/Clusters.RBAC.html)
- [Set up CloudWatch monitoring for your cache](https://docs.aws.amazon.com/AmazonElastiCache/latest/dg/CacheMetrics.html)
- [Learn about high availability with read replicas](https://docs.aws.amazon.com/AmazonElastiCache/latest/dg/ReadReplicas.html)
