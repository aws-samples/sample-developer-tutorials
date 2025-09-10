# Getting started with Amazon EMR using the AWS CLI

This tutorial guides you through setting up an Amazon EMR cluster, running a Spark application, and cleaning up resources using the AWS Command Line Interface (AWS CLI). You'll learn how to create an EMR cluster, submit a Spark job to process data, and view the results.

## Prerequisites

Before you begin this tutorial, make sure you have the following:

1. The AWS CLI. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
2. Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
3. An EC2 key pair for SSH access to your cluster. If you don't have one, the tutorial will create one for you.
4. [Sufficient permissions](https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-iam-roles.html) to create and manage EMR resources in your AWS account.

### Cost

This tutorial creates AWS resources that will incur charges. The estimated cost for running this tutorial for one hour is approximately $0.20 USD (in the US East region), which includes:

- EMR cluster with 3 m5.xlarge instances: approximately $0.19/hour
- S3 storage and requests: <$0.01/hour

To minimize costs, make sure to follow the cleanup instructions at the end of the tutorial to terminate all resources.

## Create an EC2 key pair

Amazon EMR requires an EC2 key pair for SSH access to the cluster instances. If you don't already have a key pair in
your current AWS region, create one now.

```bash
aws ec2 create-key-pair --key-name emr-tutorial-key --query 'KeyMaterial' --output text > emr-tutorial-key.pem
```

This command creates a new key pair named "emr-tutorial-key" and saves the private key to a file called
"emr-tutorial-key.pem".

**Set proper permissions on the key file**

For security, set the correct permissions on your private key file:

```bash
chmod 400 emr-tutorial-key.pem
```

**Note the key pair name**
```bash
# List all available key pairs in your current Region
aws ec2 describe-key-pairs --query 'KeyPairs[*].KeyName' --output table
```

Remember the key pair name you're using (either an existing one or "emr-tutorial-key" if you created a new one). You'll
need this when creating your EMR cluster.

## Set up storage and prepare your application

Amazon EMR uses Amazon S3 to store input data, scripts, and output results. In this section, you'll create an S3 bucket and prepare the necessary files for your EMR application.

**Create an S3 bucket**

First, create an S3 bucket to store your application code, input data, and results. For this tutorial, we'll use a bucket name with the prefix "amzndemo-s3-demo".

```bash
aws s3 mb s3://amzndemo-s3-demo-bucket
```

This command creates a new S3 bucket. Remember that S3 bucket names must be globally unique, so you might need to use a different name if "amzndemo-s3-demo-bucket" is already taken.

**Create a PySpark script**

Next, create a PySpark script that will analyze food establishment inspection data. This script will find the top 10 establishments with the most "Red" health violations.

```bash
cat > health_violations.py << 'EOL'
import argparse

from pyspark.sql import SparkSession

def calculate_red_violations(data_source, output_uri):
    """
    Processes sample food establishment inspection data and queries the data to find the top 10 establishments
    with the most Red violations from 2006 to 2020.

    :param data_source: The URI of your food establishment data CSV, such as 's3://amzndemo-s3-demo-bucket/food-establishment-data.csv'.
    :param output_uri: The URI where output is written, such as 's3://amzndemo-s3-demo-bucket/restaurant_violation_results'.
    """
    with SparkSession.builder.appName("Calculate Red Health Violations").getOrCreate() as spark:
        # Load the restaurant violation CSV data
        if data_source is not None:
            restaurants_df = spark.read.option("header", "true").csv(data_source)

        # Create an in-memory DataFrame to query
        restaurants_df.createOrReplaceTempView("restaurant_violations")

        # Create a DataFrame of the top 10 restaurants with the most Red violations
        top_red_violation_restaurants = spark.sql("""SELECT name, count(*) AS total_red_violations 
          FROM restaurant_violations 
          WHERE violation_type = 'RED' 
          GROUP BY name 
          ORDER BY total_red_violations DESC LIMIT 10""")

        # Write the results to the specified output URI
        top_red_violation_restaurants.write.option("header", "true").mode("overwrite").csv(output_uri)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--data_source', help="The URI for you CSV restaurant data, like an S3 bucket location.")
    parser.add_argument(
        '--output_uri', help="The URI where output is saved, like an S3 bucket location.")
    args = parser.parse_args()

    calculate_red_violations(args.data_source, args.output_uri)
EOL
```

After creating the script, upload it to your S3 bucket:

```bash
aws s3 cp health_violations.py s3://amzndemo-s3-demo-bucket/
```

**Download and upload sample data**

Now, download the sample food establishment inspection data and upload it to your S3 bucket:

```bash
curl -o food_establishment_data.zip https://docs.aws.amazon.com/emr/latest/ManagementGuide/samples/food_establishment_data.zip
unzip food_establishment_data.zip
aws s3 cp food_establishment_data.csv s3://amzndemo-s3-demo-bucket/
```

This data contains health inspection records for food establishments, including violation types and points. The PySpark script will analyze this data to find establishments with the most "Red" violations.

## Launch an Amazon EMR cluster

With your storage and application prepared, you can now launch an Amazon EMR cluster. In this section, you'll create the necessary IAM roles and launch a cluster with Spark installed.

**Create default IAM roles**

Amazon EMR requires specific IAM roles to function properly. The following command creates the default roles needed:

```bash
aws emr create-default-roles
```

This command creates three roles: EMR_DefaultRole, EMR_EC2_DefaultRole, and EMR_AutoScaling_DefaultRole. These roles provide the necessary permissions for EMR to interact with other AWS services.

**Launch a Spark cluster**

Now, launch an EMR cluster with Spark installed:

```bash
aws emr create-cluster \
  --name "EMR Tutorial Cluster" \
  --release-label emr-6.10.0 \
  --applications Name=Spark \
  --ec2-attributes KeyName=your-key-pair-name \
  --instance-type m5.xlarge \
  --instance-count 3 \
  --use-default-roles \
  --log-uri s3://amzndemo-s3-demo-bucket/logs/
```

Replace `your-key-pair-name` with the name of your EC2 key pair. In this tutorial, we use "emr-tutorial-key" as your key pair name. 
This command creates a cluster with one primary node and two core nodes, all using m5.xlarge instances. The cluster will have Spark installed and will use the default IAM roles.

The command returns a cluster ID, which you'll need for subsequent operations:

```json
{
    "ClusterId": "j-1234ABCD5678",
    "ClusterArn": "arn:aws:elasticmapreduce:us-west-2:123456789012:cluster/j-1234ABCD5678"
}
```

**Check cluster status**

Check the status of your cluster to see when it's ready:

```bash
aws emr describe-cluster --cluster-id j-1234ABCD5678
```

Replace `j-1234ABCD5678` with your actual cluster ID. The cluster is ready when its state changes to "WAITING":

```json
{
    "Cluster": {
        "Id": "j-1234ABCD5678",
        "Name": "EMR Tutorial Cluster",
        "Status": {
            "State": "WAITING",
            "StateChangeReason": {
                "Message": "Cluster ready to run steps."
            }
        }
    }
}
```

It may take 5-10 minutes for the cluster to reach the "WAITING" state.

## Submit work to your cluster

Once your cluster is ready, you can submit the PySpark application as a step. A step is a unit of work that contains instructions for processing data.

**Submit a Spark application**

Submit your PySpark script as a step to the cluster:

```bash
aws emr add-steps \
  --cluster-id j-1234ABCD5678 \
  --steps 'Type=Spark,Name="Health Violations Analysis",ActionOnFailure=CONTINUE,Args=["s3://amzndemo-s3-demo-bucket/health_violations.py","--data_source","s3://amzndemo-s3-demo-bucket/food_establishment_data.csv","--output_uri","s3://amzndemo-s3-demo-bucket/results/"]'
```

This command submits your PySpark script as a step to the cluster. The `Args` parameter specifies the script location and its arguments. The command returns a step ID:

```json
{
    "StepIds": [
        "s-1234ABCDEFGH"
    ]
}
```

**Check step status**

Monitor the status of your step. Replace `s-1234ABCDEFGH` with your actual step ID. 

```bash
aws emr describe-step --cluster-id j-1234ABCD5678 --step-id s-1234ABCDEFGH
```

The step is complete when its state changes to "COMPLETED":

```json
{
    "Step": {
        "Id": "s-1234ABCDEFGH",
        "Name": "Health Violations Analysis",
        "Status": {
            "State": "COMPLETED"
        }
    }
}
```

The step may take a few minutes to complete.

## View the results

After the step completes successfully, you can view the results in your S3 bucket.

**List output files**

List the files in the output directory:

```bash
aws s3 ls s3://amzndemo-s3-demo-bucket/results/
```

You should see output similar to:

```
2025-01-13 12:34:56          0 _SUCCESS
2025-01-13 12:34:56        219 part-00000-abcd1234-abcd-1234-abcd-abcd1234abcd-c000.csv
```

**Download and view results**

Download the results file to your local machine. Replace "part-00000-abcd1234-abcd-1234-abcd-abcd1234abcd-c000.csv" with the actual filename from your "aws s3 ls" output.

```bash
aws s3 cp s3://amzndemo-s3-demo-bucket/results/part-00000-abcd1234-abcd-1234-abcd-abcd1234abcd-c000.csv ./results.csv
```

View the contents of the results file:

```bash
cat results.csv
```

The output should show the top 10 establishments with the most red violations:

```
name,total_red_violations
SUBWAY,322
T-MOBILE PARK,315
WHOLE FOODS MARKET,299
PCC COMMUNITY MARKETS,251
TACO TIME,240
MCDONALD'S,177
THAI GINGER,153
SAFEWAY INC #1508,143
TAQUERIA EL RINCONSITO,134
HIMITSU TERIYAKI,128
```

## Connect to your cluster (optional)

You can connect to your cluster using SSH to view logs or run commands directly on the cluster.
**Prerequisites for SSH Connection**

Before connecting via SSH, you need to configure the security group to allow SSH access:

Step 1. Get your current IP address:
```bash
   curl -s https://checkip.amazonaws.com
```

Step 2. Find your cluster's security group. Replace "j-1234ABCD5678" with your cluster ID.

```bash
   aws emr describe-cluster --cluster-id j-1234ABCD5678 --query 'Cluster.Ec2InstanceAttributes.EmrManagedMasterSecurityGroup' --output text
```  
 

Step 3. Add SSH access rule to the security group. Replace "sg-xxxxxxxxx" with your security group ID that's returned in Step 2. Replace YOUR_IP_ADDRESS with the IP from
Step 1.

```bash
   aws ec2 authorize-security-group-ingress \
     --group-id sg-xxxxxxxxx \
     --protocol tcp \
     --port 22 \
     --cidr YOUR_IP_ADDRESS/32

**Connect via SSH**

Use the following command to connect to the primary node of your cluster. Replace "j-1234ABCD5678" with your actual cluster ID. Replace "`~/path/to/your-key-pair.pem`" with the path to your key pair file. In this example, we use "`~/emr-tutorial-key`" as the path to your key pair.

```bash
aws emr ssh --cluster-id j-1234ABCD5678 --key-pair-file ~/path/to/your-key-pair.pem
```

**View Spark logs**

Once connected, you can view Spark logs in two locations: 

Option 1: View local Spark service logs
```bash
cd /mnt/var/log/spark
ls -la
```
This directory contains logs for your Spark applications, which can be useful for debugging or understanding how your application ran.

Option 2: View detailed application logs
```bash
# List all Spark applications
hdfs dfs -ls /var/log/spark/apps/
```
It contains the application ID from the output. Save the application ID for the following use. The application logs in HDFS (/var/log/spark/apps/) contain the most detailed
information about your Spark job execution, including performance metrics, task details,
and any errors that occurred.
```bash
# Copy detailed logs for a specific application to your home directory and view the logs. Reaplce "application_XXXXXXXXX_XXXX" with your application ID.
```bash
hdfs dfs -get /var/log/spark/apps/application_XXXXXXXXX_XXXX ~/spark-app.log

head -20 ~/spark-app.log
```

Option 3: View logs with timestamps
```bash
sudo cat /var/log/spark/spark-history-server.out
```

**Useful commands while Connected**

• **Check cluster status:** `yarn application -list`
• **View HDFS contents:** `hdfs dfs -ls /`
• **Monitor system resources:** `top`
• **Exit SSH session:** `exit`

**Troubleshooting**

• **Connection timeout:** Verify that your security group allows SSH (port 22) from your IP
• **Permission denied:** Ensure your key pair file has correct permissions. Replace "`~/emr-tutorial-key.pem`" with the path to your key pair file. In this example, we use "`~/emr-tutorial-key`" as the path to your key pair.
```
chmod 400 ~/emr-tutorial-key.pem
```
• **Key not found:** Verify the path to your key pair file is correct


## Clean up resources

When you're finished with the tutorial, clean up your resources to avoid incurring additional charges.

**Terminate the cluster**

Terminate your EMR cluster. Replace "j-1234ABCD5678" with your cluster ID.

```bash
aws emr terminate-clusters --cluster-ids j-1234ABCD5678
```

Check the termination status. Replace "j-1234ABCD5678" with your cluster ID.

```bash
aws emr describe-cluster --cluster-id j-1234ABCD5678
```

The cluster is terminated when its state changes to "TERMINATED". An example response is as follows: 

```json
{
    "Cluster": {
        "Id": "j-1234ABCD5678",
        "Name": "EMR Tutorial Cluster",
        "Status": {
            "State": "TERMINATED",
            "StateChangeReason": {
                "Code": "USER_REQUEST",
                "Message": "Terminated by user request"
            }
        }
    }
}
```

**Delete S3 resources**

Delete the contents of your S3 bucket. Replace "amzndemo-s3-demo-bucket" with the name of your Amazon S3 bucket.

```bash
aws s3 rm s3://amzndemo-s3-demo-bucket --recursive
```

Then delete the bucket itself:

```bash
aws s3 rb s3://amzndemo-s3-demo-bucket
```

## Going to production

This tutorial is designed to help you learn how to use Amazon EMR with the AWS CLI in a development or test environment. For production deployments, consider the following best practices:

### Security considerations

1. **Custom IAM roles**: Create custom IAM roles with least privilege instead of using the default roles.
2. **VPC and security groups**: Configure a custom VPC and security groups to control network access.
3. **Encryption**: Enable encryption for data at rest (S3, EBS volumes) and in transit.
4. **Authentication and authorization**: Implement proper authentication for accessing EMR resources and results.
5. **Logging and monitoring**: Set up CloudTrail for API logging and CloudWatch for monitoring.

### Architecture considerations

1. **Scalability**: Use EMR managed scaling to automatically adjust cluster size based on workload.
2. **Reliability**: Consider multi-AZ deployments and implement proper error handling.
3. **Cost optimization**: Evaluate spot instances for cost savings and right-size your cluster.
4. **Performance**: Choose appropriate instance types and tune Spark configurations for your workload.
5. **Operational excellence**: Use infrastructure as code (CloudFormation, CDK) and implement CI/CD pipelines.

For more information on building production-ready solutions with Amazon EMR, refer to:
- [Amazon EMR Best Practices Guide](https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-plan.html)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Security Best Practices for Amazon EMR](https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-security.html)

## Next steps

Now that you've learned the basics of using Amazon EMR with the AWS CLI, explore these additional topics:

1. **Big data applications** - Discover and compare the [big data applications](https://docs.aws.amazon.com/emr/latest/ReleaseGuide/emr-release-components.html) you can install on an EMR cluster.
2. **Cluster planning** - Learn how to [plan, configure, and launch EMR clusters](https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-plan.html) that meet your specific requirements.
3. **Security** - Implement [security best practices](https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-security.html) for your EMR clusters.
4. **Cluster management** - Dive deeper into [managing EMR clusters](https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-manage.html) and adjusting resources with [EMR managed scaling](https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-managed-scaling.html).
5. **Web interfaces** - Learn how to [view web interfaces](https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-web-interfaces.html) hosted on EMR clusters.
