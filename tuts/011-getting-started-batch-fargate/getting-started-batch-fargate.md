# Getting started with AWS Batch and Fargate using the AWS CLI

This tutorial demonstrates how to set up AWS Batch with Fargate orchestration and run a simple "Hello World" job using the AWS Command Line Interface (AWS CLI). You'll learn how to create compute environments, job queues, job definitions, and submit jobs to AWS Batch.

## Overview

AWS Batch is a fully managed service that enables you to run batch computing workloads on AWS. With Fargate, you can run containerized batch jobs without managing servers or clusters. This tutorial walks you through the essential components:

- **IAM execution role**: Allows AWS Batch to make API calls on your behalf
- **Compute environment**: Defines the compute resources where jobs run
- **Job queue**: Stores submitted jobs until they can be scheduled
- **Job definition**: Specifies how jobs should be executed
- **Job submission**: Submits and monitors job execution

By the end of this tutorial, you'll have a working AWS Batch setup that can process containerized workloads using Fargate.

## Topics

- [Prerequisites](#prerequisites)
- [Create an IAM execution role](#create-an-iam-execution-role)
- [Create a compute environment](#create-a-compute-environment)
- [Create a job queue](#create-a-job-queue)
- [Create a job definition](#create-a-job-definition)
- [Submit and monitor a job](#submit-and-monitor-a-job)
- [View job output](#view-job-output)
- [Clean up resources](#clean-up-resources)
- [Troubleshooting](#troubleshooting)
- [Going to production](#going-to-production)
- [Next steps](#next-steps)

## Prerequisites

Before you begin this tutorial, make sure you have the following.

1. The AWS CLI. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html). You can also [use AWS CloudShell](https://docs.aws.amazon.com/cloudshell/latest/userguide/welcome.html), which includes the AWS CLI.
2. Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
3. A default VPC in your AWS region. You can verify this by running:
   ```
   aws ec2 describe-vpcs --filters "Name=is-default,Values=true" --region <your-region>
   ```
   If you don't have a default VPC, you can [create one](https://docs.aws.amazon.com/vpc/latest/userguide/default-vpc.html) or modify the commands to use your existing VPC resources.
4. Basic familiarity with command line interfaces and containerization concepts.
5. [Sufficient permissions](https://docs.aws.amazon.com/batch/latest/userguide/security_iam_service-with-iam.html) to create and manage AWS Batch resources, IAM roles, and VPC resources in your AWS account.

**Time Required**: Approximately 15-20 minutes to complete this tutorial.

**Cost**: This tutorial uses AWS Fargate compute resources. The estimated cost for completing this tutorial is less than $0.01 USD, assuming you follow the cleanup instructions to delete resources immediately after completion. Fargate pricing is based on vCPU and memory resources consumed, charged per second with a 1-minute minimum. For current pricing information, see [AWS Fargate pricing](https://aws.amazon.com/fargate/pricing/).

## Create an IAM execution role

AWS Batch requires an execution role that allows Amazon ECS agents to make AWS API calls on your behalf. This role is necessary for Fargate tasks to pull container images and write logs to CloudWatch.

**Create a trust policy document**

First, create a trust policy that allows the ECS tasks service to assume the role.

```
$ cat > batch-execution-role-trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
```

**Create the execution role**

The following command creates an IAM role named `BatchEcsTaskExecutionRoleTutorial` using the trust policy you just created.

```
$ aws iam create-role \
    --role-name BatchEcsTaskExecutionRoleTutorial \
    --assume-role-policy-document file://batch-execution-role-trust-policy.json
```

```
{
    "Role": {
        "Path": "/",
        "RoleName": "BatchEcsTaskExecutionRoleTutorial",
        "RoleId": "AROAUVBFO26T7xmpl3RGYTVO",
        "Arn": "arn:aws:iam::<123456789012>:role/BatchEcsTaskExecutionRoleTutorial",
        "CreateDate": "2025-01-13T17:34:28+00:00",
        "AssumeRolePolicyDocument": {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Principal": {
                        "Service": "ecs-tasks.amazonaws.com"
                    },
                    "Action": "sts:AssumeRole"
                }
            ]
        }
    }
}
```

**Attach the required policy**

Attach the AWS managed policy that provides the necessary permissions for ECS task execution.

```
$ aws iam attach-role-policy \
    --role-name BatchEcsTaskExecutionRoleTutorial \
    --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
```

The role is now ready to be used by AWS Batch for Fargate task execution.

## Create a compute environment

A compute environment defines the compute resources where your batch jobs will run. For this tutorial, you'll create a managed Fargate compute environment that automatically provisions and scales resources based on job requirements.

**Get your VPC and subnet information**

First, get your default VPC ID and subnet IDs that will be needed for the compute environment.

```
$ aws ec2 describe-vpcs --filters "Name=is-default,Values=true" --query 'Vpcs[0].VpcId' --output text
```

```
vpc-12345678
```

```
$ aws ec2 describe-subnets --filters "Name=vpc-id,Values=<vpc-12345678>" --query 'Subnets[*].SubnetId' --output text
```

```
subnet-12345678 subnet-87654321 subnet-abcdef12
```

```
$ aws ec2 describe-security-groups --filters "Name=vpc-id,Values=<vpc-12345678>" "Name=group-name,Values=default" --query 'SecurityGroups[0].GroupId' --output text
```

```
sg-12345678
```

**Create the compute environment**

The following command creates a Fargate compute environment using your VPC resources. Replace the placeholder values with your actual VPC ID, subnet IDs, and security group ID from the previous commands. For more information about this command, see [create-compute-environment](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/batch/create-compute-environment.html) in the AWS CLI Command Reference. For more information about this command, see [create-compute-environment](https://docs.aws.amazon.com/cli/latest/reference/batch/create-compute-environment.html) in the AWS CLI Command Reference.

```
$ aws batch create-compute-environment \
    --compute-environment-name my-fargate-compute-env \
    --type MANAGED \
    --state ENABLED \
    --compute-resources type=FARGATE,maxvCpus=4,subnets=<subnet-12345678>,<subnet-87654321>,<subnet-abcdef12>,securityGroupIds=<sg-12345678>
```

```
{
    "computeEnvironmentName": "my-fargate-compute-env",
    "computeEnvironmentArn": "arn:aws:batch:<us-west-2>:<123456789012>:compute-environment/my-fargate-compute-env"
}
```

**Wait for the compute environment to be ready**

Check the status of your compute environment to ensure it's ready before proceeding.

```
$ aws batch describe-compute-environments \
    --compute-environments my-fargate-compute-env \
    --query 'computeEnvironments[0].status'
```

```
"VALID"
```

When the status shows `VALID`, your compute environment is ready to accept jobs.

## Create a job queue

A job queue stores submitted jobs until the AWS Batch scheduler runs them on resources in your compute environment. Jobs are processed in priority order within the queue.

**Create the job queue**

The following command creates a job queue with priority 900 that uses your Fargate compute environment. For more information about this command, see [create-job-queue](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/batch/create-job-queue.html) in the AWS CLI Command Reference. For more information about this command, see [create-job-queue](https://docs.aws.amazon.com/cli/latest/reference/batch/create-job-queue.html) in the AWS CLI Command Reference.

```
$ aws batch create-job-queue \
    --job-queue-name my-fargate-job-queue \
    --state ENABLED \
    --priority 900 \
    --compute-environment-order order=1,computeEnvironment=my-fargate-compute-env
```

```
{
    "jobQueueName": "my-fargate-job-queue",
    "jobQueueArn": "arn:aws:batch:<us-west-2>:<123456789012>:job-queue/my-fargate-job-queue"
}
```

**Verify the job queue is ready**

Check that your job queue is in the `ENABLED` state and ready to accept jobs.

```
$ aws batch describe-job-queues \
    --job-queues my-fargate-job-queue \
    --query 'jobQueues[0].state'
```

```
"ENABLED"
```

## Create a job definition

A job definition specifies how jobs are to be run, including the Docker image to use, resource requirements, and other parameters. For Fargate, you'll use resource requirements instead of traditional vCPU and memory parameters.

**Create the job definition**

The following command creates a job definition that runs a simple "hello world" command using the busybox container image. Replace `<123456789012>` with your actual AWS account ID. For more information about this command, see [register-job-definition](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/batch/register-job-definition.html) in the AWS CLI Command Reference.

```
$ aws batch register-job-definition \
    --job-definition-name my-fargate-job-def \
    --type container \
    --platform-capabilities FARGATE \
    --container-properties '{
        "image": "busybox",
        "resourceRequirements": [
            {"type": "VCPU", "value": "0.25"},
            {"type": "MEMORY", "value": "512"}
        ],
        "command": ["echo", "hello world"],
        "networkConfiguration": {
            "assignPublicIp": "ENABLED"
        },
        "executionRoleArn": "arn:aws:iam::<123456789012>:role/BatchEcsTaskExecutionRoleTutorial"
    }'
```

```
{
    "jobDefinitionName": "my-fargate-job-def",
    "jobDefinitionArn": "arn:aws:batch:<us-west-2>:<123456789012>:job-definition/my-fargate-job-def:1",
    "revision": 1
}
```

The job definition specifies 0.25 vCPU and 512 MB of memory, which are the minimum resources for a Fargate task. The `assignPublicIp` setting is enabled so the container can pull the busybox image from Docker Hub.

## Submit and monitor a job

Now that you have all the necessary components, you can submit a job to your queue and monitor its progress.

**Submit a job**

The following command submits a job to your queue using the job definition you created. For more information about this command, see [submit-job](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/batch/submit-job.html) in the AWS CLI Command Reference.

```
$ aws batch submit-job \
    --job-name my-hello-world-job \
    --job-queue my-fargate-job-queue \
    --job-definition my-fargate-job-def
```

```
{
    "jobArn": "arn:aws:batch:<us-west-2>:<123456789012>:job/my-hello-world-job",
    "jobName": "my-hello-world-job",
    "jobId": "1509xmpl-4224-4da6-9ba9-1d1acc96431a"
}
```

Make note of the `jobId` returned in the response, as you'll use it to monitor the job's progress.

**Monitor job status**

Use the job ID to check the status of your job. The job will progress through several states: `SUBMITTED`, `PENDING`, `RUNNABLE`, `STARTING`, `RUNNING`, and finally `SUCCEEDED` or `FAILED`.

```
$ aws batch describe-jobs --jobs <1509xmpl-4224-4da6-9ba9-1d1acc96431a>
```

```
{
    "jobs": [
        {
            "jobArn": "arn:aws:batch:<us-west-2>:<123456789012>:job/my-hello-world-job",
            "jobName": "my-hello-world-job",
            "jobId": "1509xmpl-4224-4da6-9ba9-1d1acc96431a",
            "jobQueue": "arn:aws:batch:<us-west-2>:<123456789012>:job-queue/my-fargate-job-queue",
            "status": "SUCCEEDED",
            "createdAt": 1705161908000,
            "jobDefinition": "arn:aws:batch:<us-west-2>:<123456789012>:job-definition/my-fargate-job-def:1"
        }
    ]
}
```

When the status shows `SUCCEEDED`, your job has completed successfully.

## View job output

After your job completes, you can view its output in CloudWatch Logs.

**Get the log stream name**

First, retrieve the log stream name from the job details.

```
$ aws batch describe-jobs --jobs <1509xmpl-4224-4da6-9ba9-1d1acc96431a> \
    --query 'jobs[0].container.logStreamName' \
    --output text
```

```
my-fargate-job-def/default/1509xmpl-4224-4da6-9ba9-1d1acc96431a
```

**View the job logs**

Use the log stream name to retrieve the job's output from CloudWatch Logs.

```
$ aws logs get-log-events \
    --log-group-name /aws/batch/job \
    --log-stream-name <my-fargate-job-def/default/1509xmpl-4224-4da6-9ba9-1d1acc96431a> \
    --query 'events[*].message' \
    --output text
```

```
hello world
```

The output shows "hello world", confirming that your job ran successfully.

## Clean up resources

To avoid ongoing charges, clean up the resources you created in this tutorial. You must delete resources in the correct order due to dependencies.

**Disable and delete the job queue**

First, disable the job queue, then delete it.

```
$ aws batch update-job-queue \
    --job-queue my-fargate-job-queue \
    --state DISABLED

$ aws batch delete-job-queue \
    --job-queue my-fargate-job-queue
```

**Disable and delete the compute environment**

After the job queue is deleted, disable and delete the compute environment.

```
$ aws batch update-compute-environment \
    --compute-environment my-fargate-compute-env \
    --state DISABLED

$ aws batch delete-compute-environment \
    --compute-environment my-fargate-compute-env
```

**Clean up the IAM role**

Remove the policy attachment and delete the IAM role.

```
$ aws iam detach-role-policy \
    --role-name BatchEcsTaskExecutionRoleTutorial \
    --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy

$ aws iam delete-role \
    --role-name BatchEcsTaskExecutionRoleTutorial
```

**Remove temporary files**

Delete the trust policy file you created.

```
$ rm batch-execution-role-trust-policy.json
```

All resources have been successfully cleaned up.

## Troubleshooting

If you encounter issues while following this tutorial, here are common problems and their solutions:

**Compute environment creation fails**

- **Error**: `Missing required parameter in computeResources: "maxvCpus"`
- **Solution**: Ensure you include the `maxvCpus`, `subnets`, and `securityGroupIds` parameters as shown in the tutorial

**Job fails to start**

- **Error**: Job remains in `RUNNABLE` state
- **Solution**: Check that your compute environment status is `VALID` and your job queue is `ENABLED`

**Cannot access job logs**

- **Error**: Log stream not found or returns empty results
- **Solution**: Ensure the job has completed successfully (`SUCCEEDED` status) before attempting to retrieve logs

**Resource deletion fails**

- **Error**: `Cannot delete, found existing JobQueue relationship`
- **Solution**: Delete resources in the correct order: job queue first, then compute environment, then IAM role. Wait for each deletion to complete before proceeding to the next step.

**VPC or subnet not found**

- **Error**: Invalid subnet ID or security group ID
- **Solution**: Verify your default VPC exists and use the resource discovery commands provided in the tutorial to get the correct IDs

For additional help, see the [AWS Batch troubleshooting guide](https://docs.aws.amazon.com/batch/latest/userguide/troubleshooting.html) and the [AWS Batch CLI Command Reference](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/batch/index.html).

## Going to production

This tutorial is designed to help you understand how AWS Batch works with Fargate. For production deployments, consider the following additional requirements:

**Security considerations:**

- Create dedicated security groups with minimal required access instead of using default security groups
- Use private subnets with NAT Gateway instead of public IP assignment for containers
- Store container images in Amazon ECR instead of using public repositories
- Implement VPC endpoints for AWS service communication to avoid internet traffic

**Architecture considerations:**

- Deploy across multiple Availability Zones for high availability
- Implement job retry strategies and dead letter queues for error handling
- Use multiple job queues with different priorities for workload management
- Configure auto scaling policies based on queue depth and resource utilization
- Implement monitoring and alerting for job failures and resource utilization

**Operational considerations:**

- Set up CloudWatch dashboards and alarms for monitoring
- Implement proper logging and audit trails
- Use AWS CloudFormation or AWS CDK for infrastructure as code
- Establish backup and disaster recovery procedures

For comprehensive guidance on production-ready architectures, see the [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/) and [AWS Security Best Practices](https://aws.amazon.com/architecture/security-identity-compliance/).

## Next steps

Now that you've completed this tutorial, you can explore more advanced AWS Batch features:

- [Job queues](https://docs.aws.amazon.com/batch/latest/userguide/job_queues.html) - Learn about job queue scheduling and priority management
- [Job definitions](https://docs.aws.amazon.com/batch/latest/userguide/job_definitions.html) - Explore advanced job definition configurations including environment variables, volumes, and retry strategies
- [Compute environments](https://docs.aws.amazon.com/batch/latest/userguide/compute_environments.html) - Understand different compute environment types and scaling options
- [Multi-node parallel jobs](https://docs.aws.amazon.com/batch/latest/userguide/multi-node-parallel-jobs.html) - Run jobs that span multiple compute nodes
- [Array jobs](https://docs.aws.amazon.com/batch/latest/userguide/array_jobs.html) - Submit large numbers of similar jobs efficiently
- [Best practices](https://docs.aws.amazon.com/batch/latest/userguide/best-practices.html) - Learn optimization techniques for production workloads

## Security Considerations

This tutorial demonstrates basic AWS CLI usage for educational purposes. For production environments:
- Follow the [AWS Well-Architected Security Pillar](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/)
- Implement least privilege access principles
- Enable appropriate logging and monitoring
- Review and apply security best practices specific to each service used

**Important:** This tutorial does not provide security guidance. Consult AWS security documentation and your security team for production deployments.