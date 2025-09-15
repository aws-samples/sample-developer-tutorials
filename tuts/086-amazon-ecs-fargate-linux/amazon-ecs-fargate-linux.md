# Create an Amazon ECS Linux task for the Fargate launch type using the AWS CLI

This tutorial shows you how to create and run an Amazon ECS Linux task using the Fargate launch type with the AWS CLI. You'll learn how to create an ECS cluster, register a task definition, create a service, and access your running application.

## Topics

- [Prerequisites](#prerequisites)
- [Create the cluster](#create-the-cluster)
- [Create a task definition](#create-a-task-definition)
- [Create the service](#create-the-service)
- [View your service](#view-your-service)
- [Clean up](#clean-up)
- [Going to production](#going-to-production)
- [Next steps](#next-steps)

## Prerequisites

Before you begin this tutorial, make sure you have the following.

1. The AWS CLI. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html). You can also [use AWS CloudShell](https://docs.aws.amazon.com/cloudshell/latest/userguide/welcome.html), which includes the AWS CLI.
2. Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
3. [Sufficient permissions](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/security_iam_id-based-policy-examples.html) to create and manage Amazon ECS resources in your AWS account.
4. A default VPC in your chosen AWS Region. If you don't have a default VPC, you can [create one](https://docs.aws.amazon.com/vpc/latest/userguide/default-vpc.html).

The AWS CLI attempts to automatically create the task execution IAM role, which is required for Fargate tasks. To ensure that the AWS CLI can create this IAM role, one of the following must be true:

- Your user has administrator access.
- Your user has the IAM permissions to create a service role.
- A user with administrator access has manually created the task execution role so that it is available on the account to be used.

### Cost considerations

This tutorial creates AWS resources that incur charges. The estimated cost for completing this tutorial is approximately **$0.02 USD**, assuming you complete it within 30 minutes and clean up resources immediately afterward. The primary cost comes from AWS Fargate compute charges (approximately $0.045 per hour for the minimum configuration used in this tutorial). All other resources (VPC, security groups, IAM roles) are free of charge. For more information about AWS Fargate pricing, see [AWS Fargate Pricing](https://aws.amazon.com/fargate/pricing/).

**Important**: The security group you create in this tutorial allows HTTP traffic from anywhere on the internet (0.0.0.0/0). This configuration is appropriate for this tutorial, but you should restrict access to specific IP ranges in production environments.

## Create the cluster

An Amazon ECS cluster is a logical grouping of tasks or services. In this section, you'll create a cluster to host your Fargate tasks.

**Create an ECS cluster**

The following command creates a new ECS cluster with a unique name.

```
$ aws ecs create-cluster --cluster-name my-fargate-cluster
```

Output:

```
{
    "cluster": {
        "clusterArn": "arn:aws:ecs:us-west-2:123456789012:cluster/my-fargate-cluster",
        "clusterName": "my-fargate-cluster",
        "status": "ACTIVE",
        "registeredContainerInstancesCount": 0,
        "runningTasksCount": 0,
        "pendingTasksCount": 0,
        "activeServicesCount": 0,
        "statistics": [],
        "tags": [],
        "settings": [
            {
                "name": "containerInsights",
                "value": "disabled"
            }
        ],
        "capacityProviders": [],
        "defaultCapacityProviderStrategy": []
    }
}
```

The response shows that your cluster has been created successfully with an `ACTIVE` status. Note the cluster ARN, which uniquely identifies your cluster.

## Create a task definition

A task definition is like a blueprint for your application. It specifies which Docker image to use for containers, how many containers to use in the task, and the resource allocation for each container.

**Register a task definition**

First, create a JSON file that defines your task. The following command creates a task definition file for a simple web application. Replace the `executionRoleArn` with your own.

```
$ cat > task-definition.json << 'EOF'
{
    "family": "sample-fargate",
    "networkMode": "awsvpc",
    "requiresCompatibilities": ["FARGATE"],
    "cpu": "256",
    "memory": "512",
    "executionRoleArn": "arn:aws:iam::123456789012:role/ecsTaskExecutionRole",
    "containerDefinitions": [
        {
            "name": "fargate-app",
            "image": "public.ecr.aws/docker/library/httpd:latest",
            "portMappings": [
                {
                    "containerPort": 80,
                    "hostPort": 80,
                    "protocol": "tcp"
                }
            ],
            "essential": true,
            "entryPoint": ["sh", "-c"],
            "command": [
                "/bin/sh -c \"echo '<html> <head> <title>Amazon ECS Sample App</title> <style>body {margin-top: 40px; background-color: #333;} </style> </head><body> <div style=color:white;text-align:center> <h1>Amazon ECS Sample App</h1> <h2>Congratulations!</h2> <p>Your application is now running on a container in Amazon ECS.</p> </div></body></html>' >  /usr/local/apache2/htdocs/index.html && httpd-foreground\""
            ]
        }
    ]
}
EOF
```

This task definition specifies a Fargate-compatible task that runs a simple web server. The task uses 256 CPU units and 512 MB of memory, which are the minimum values for Fargate tasks.

**Register the task definition**

Now register the task definition with Amazon ECS using the following command.

```
$ aws ecs register-task-definition --cli-input-json file://task-definition.json
```

Output:

```
{
    "taskDefinition": {
        "taskDefinitionArn": "arn:aws:ecs:us-west-2:123456789012:task-definition/sample-fargate:1",
        "family": "sample-fargate",
        "taskRoleArn": null,
        "executionRoleArn": "arn:aws:iam::123456789012:role/ecsTaskExecutionRole",
        "networkMode": "awsvpc",
        "revision": 1,
        "volumes": [],
        "status": "ACTIVE",
        "requiresAttributes": [
            {
                "name": "com.amazonaws.ecs.capability.logging-driver.awslogs"
            },
            {
                "name": "ecs.capability.execution-role-awslogs"
            },
            {
                "name": "com.amazonaws.ecs.capability.docker-remote-api.1.19"
            },
            {
                "name": "com.amazonaws.ecs.capability.docker-remote-api.1.21"
            },
            {
                "name": "com.amazonaws.ecs.capability.task-iam-role"
            },
            {
                "name": "ecs.capability.execution-role-ecr-pull"
            },
            {
                "name": "com.amazonaws.ecs.capability.docker-remote-api.1.18"
            },
            {
                "name": "ecs.capability.task-eni"
            },
            {
                "name": "com.amazonaws.ecs.capability.docker-remote-api.1.29"
            }
        ],
        "placementConstraints": [],
        "compatibilities": [
            "EC2",
            "FARGATE"
        ],
        "requiresCompatibilities": [
            "FARGATE"
        ],
        "cpu": "256",
        "memory": "512",
        "containerDefinitions": [
            {
                "name": "fargate-app",
                "image": "public.ecr.aws/docker/library/httpd:latest",
                "cpu": 0,
                "memory": null,
                "memoryReservation": null,
                "links": null,
                "portMappings": [
                    {
                        "containerPort": 80,
                        "hostPort": 80,
                        "protocol": "tcp"
                    }
                ],
                "essential": true,
                "entryPoint": [
                    "sh",
                    "-c"
                ],
                "command": [
                    "/bin/sh -c \"echo '<html> <head> <title>Amazon ECS Sample App</title> <style>body {margin-top: 40px; background-color: #333;} </style> </head><body> <div style=color:white;text-align:center> <h1>Amazon ECS Sample App</h1> <h2>Congratulations!</h2> <p>Your application is now running on a container in Amazon ECS.</p> </div></body></html>' >  /usr/local/apache2/htdocs/index.html && httpd-foreground\""
                ],
                "environment": [],
                "mountPoints": [],
                "volumesFrom": [],
                "logConfiguration": null
            }
        ]
    }
}
```

The response confirms that your task definition has been registered successfully. Note the task definition ARN and revision number, which you'll use when creating the service.

## Create the service

A service runs and maintains a specified number of tasks simultaneously in an Amazon ECS cluster. In this section, you'll create a service that runs one instance of your task definition.

**Set up networking**

Before creating the service, you need to set up the networking components. First, get your default VPC ID and create a security group.

```
$ VPC_ID=$(aws ec2 describe-vpcs --filters "Name=is-default,Values=true" --query "Vpcs[0].VpcId" --output text)
$ echo "Using default VPC: $VPC_ID"
```

Output:

```
Using default VPC: vpc-abcd1234
```

**Create a security group**

Create a security group that allows HTTP traffic on port 80.

```
$ SECURITY_GROUP_ID=$(aws ec2 create-security-group \
    --group-name ecs-fargate-sg \
    --description "Security group for ECS Fargate tasks" \
    --vpc-id $VPC_ID \
    --query "GroupId" --output text)
$ echo "Created security group: $SECURITY_GROUP_ID"
```

Output:

```
Created security group: sg-abcd1234
```

**Add an inbound rule**

Add an inbound rule to allow HTTP traffic from anywhere on the internet.

```
$ aws ec2 authorize-security-group-ingress \
    --group-id $SECURITY_GROUP_ID \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0
```

Output:

```
{
    "Return": true,
    "SecurityGroupRules": [
        {
            "SecurityGroupRuleId": "sgr-abcd1234",
            "GroupId": "sg-abcd1234",
            "GroupOwnerId": "123456789012",
            "IsEgress": false,
            "IpProtocol": "tcp",
            "FromPort": 80,
            "ToPort": 80,
            "CidrIpv4": "0.0.0.0/0"
        }
    ]
}
```

**Get subnet information**

Get the subnet IDs from your default VPC to use for the service network configuration.

```
$ SUBNET_IDS=$(aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query "Subnets[*].SubnetId" \
    --output text | tr '\t' ',')
$ echo "Using subnets: $SUBNET_IDS"
```

Output:

```
Using subnets: subnet-abcd1234,subnet-efgh5678,subnet-ijkl9012,subnet-mnop3456
```

**Create the ECS service**

Now create the service using your task definition and network configuration.

```
$ aws ecs create-service \
    --cluster my-fargate-cluster \
    --service-name my-fargate-service \
    --task-definition sample-fargate \
    --desired-count 1 \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_IDS],securityGroups=[$SECURITY_GROUP_ID],assignPublicIp=ENABLED}"
```

Output:

```
{
    "service": {
        "serviceArn": "arn:aws:ecs:us-west-2:123456789012:service/my-fargate-cluster/my-fargate-service",
        "serviceName": "my-fargate-service",
        "clusterArn": "arn:aws:ecs:us-west-2:123456789012:cluster/my-fargate-cluster",
        "loadBalancers": [],
        "serviceRegistries": [],
        "status": "ACTIVE",
        "desiredCount": 1,
        "runningCount": 0,
        "pendingCount": 0,
        "launchType": "FARGATE",
        "platformVersion": "LATEST",
        "taskDefinition": "arn:aws:ecs:us-west-2:123456789012:task-definition/sample-fargate:1",
        "deploymentConfiguration": {
            "maximumPercent": 200,
            "minimumHealthyPercent": 100
        },
        "deployments": [
            {
                "id": "ecs-svc/1234567890123456789",
                "status": "PRIMARY",
                "taskDefinition": "arn:aws:ecs:us-west-2:123456789012:task-definition/sample-fargate:1",
                "desiredCount": 1,
                "pendingCount": 0,
                "runningCount": 0,
                "createdAt": 1673596800.000,
                "updatedAt": 1673596800.000,
                "launchType": "FARGATE",
                "platformVersion": "1.4.0",
                "networkConfiguration": {
                    "awsvpcConfiguration": {
                        "subnets": [
                            "subnet-abcd1234",
                            "subnet-efgh5678",
                            "subnet-ijkl9012",
                            "subnet-mnop3456"
                        ],
                        "securityGroups": [
                            "sg-abcd1234"
                        ],
                        "assignPublicIp": "ENABLED"
                    }
                }
            }
        ],
        "events": [],
        "createdAt": 1673596800.000,
        "placementConstraints": [],
        "placementStrategy": [],
        "networkConfiguration": {
            "awsvpcConfiguration": {
                "subnets": [
                    "subnet-abcd1234",
                    "subnet-efgh5678",
                    "subnet-ijkl9012",
                    "subnet-mnop3456"
                ],
                "securityGroups": [
                    "sg-abcd1234"
                ],
                "assignPublicIp": "ENABLED"
            }
        },
        "healthCheckGracePeriodSeconds": 0,
        "schedulingStrategy": "REPLICA"
    }
}
```

The response shows that your service has been created successfully. The service will start deploying your task, which may take a few minutes to become available.

## View your service

After creating the service, you can check its status and get the public IP address of your running task.

**Wait for the service to stabilize**

Use the following command to wait for your service to reach a stable state.

```
$ aws ecs wait services-stable --cluster my-fargate-cluster --services my-fargate-service
```

This command will wait until the service deployment is complete and the desired number of tasks are running.

**Check service status**

Verify that your service is running correctly.

```
$ aws ecs describe-services \
    --cluster my-fargate-cluster \
    --services my-fargate-service
```
Output:

```
{
    "services": [
        {
            "serviceArn": "arn:aws:ecs:us-west-2:123456789012:service/my-fargate-cluster/my-fargate-service",
            "serviceName": "my-fargate-service",
            "clusterArn": "arn:aws:ecs:us-west-2:123456789012:cluster/my-fargate-cluster",
            "loadBalancers": [],
            "serviceRegistries": [],
            "status": "ACTIVE",
            "desiredCount": 1,
            "runningCount": 1,
            "pendingCount": 0,
            "launchType": "FARGATE",
            "platformVersion": "LATEST",
            "taskDefinition": "arn:aws:ecs:us-west-2:123456789012:task-definition/sample-fargate:1",
            "deploymentConfiguration": {
                "maximumPercent": 200,
                "minimumHealthyPercent": 100
            },
            "deployments": [
                {
                    "id": "ecs-svc/1234567890123456789",
                    "status": "PRIMARY",
                    "taskDefinition": "arn:aws:ecs:us-west-2:123456789012:task-definition/sample-fargate:1",
                    "desiredCount": 1,
                    "pendingCount": 0,
                    "runningCount": 1,
                    "createdAt": 1673596800.000,
                    "updatedAt": 1673596800.000,
                    "launchType": "FARGATE",
                    "platformVersion": "1.4.0",
                    "networkConfiguration": {
                        "awsvpcConfiguration": {
                            "subnets": [
                                "subnet-abcd1234",
                                "subnet-efgh5678",
                                "subnet-ijkl9012",
                                "subnet-mnop3456"
                            ],
                            "securityGroups": [
                                "sg-abcd1234"
                            ],
                            "assignPublicIp": "ENABLED"
                        }
                    },
                    "rolloutState": "COMPLETED"
                }
            ],
            "events": [
                {
                    "id": "abcd1234-5678-90ab-cdef-1234567890ab",
                    "createdAt": 1673596800.000,
                    "message": "(service my-fargate-service) has reached a steady state."
                }
            ],
            "createdAt": 1673596800.000,
            "placementConstraints": [],
            "placementStrategy": [],
            "networkConfiguration": {
                "awsvpcConfiguration": {
                    "subnets": [
                        "subnet-abcd1234",
                        "subnet-efgh5678",
                        "subnet-ijkl9012",
                        "subnet-mnop3456"
                    ],
                    "securityGroups": [
                        "sg-abcd1234"
                    ],
                    "assignPublicIp": "ENABLED"
                }
            },
            "healthCheckGracePeriodSeconds": 0,
            "schedulingStrategy": "REPLICA"
        }
    ]
}
```

The output shows that your service is `ACTIVE` with 1 running task and has reached a steady state.

**Get the public IP address**

To access your application, you need to get the public IP address of the running task.

```
$ TASK_ARN=$(aws ecs list-tasks \
    --cluster my-fargate-cluster \
    --service-name my-fargate-service \
    --query "taskArns[0]" --output text)
$ echo "Task ARN: $TASK_ARN"
```
Output:

```
Task ARN: arn:aws:ecs:us-west-2:123456789012:task/my-fargate-cluster/abcd1234567890abcdef1234567890ab
```

```
$ ENI_ID=$(aws ecs describe-tasks \
    --cluster my-fargate-cluster \
    --tasks $TASK_ARN \
    --query "tasks[0].attachments[0].details[?name=='networkInterfaceId'].value" \
    --output text)
$ echo "Network Interface ID: $ENI_ID"
```
Output:

```
Network Interface ID: eni-abcd1234
```

```
$ PUBLIC_IP=$(aws ec2 describe-network-interfaces \
    --network-interface-ids $ENI_ID \
    --query "NetworkInterfaces[0].Association.PublicIp" \
    --output text)
$ echo "Your application is available at: http://$PUBLIC_IP"
```

Output:

```
Your application is available at: http://203.0.113.75
```

You can now open this URL in your web browser to see your running application. You should see a simple web page with the message "Amazon ECS Sample App" and "Congratulations! Your application is now running on a container in Amazon ECS."

## Clean up

When you're finished with this tutorial, clean up the resources to avoid incurring charges for resources you're not using.

**Scale the service to zero tasks**

First, scale your service down to zero tasks.

```
$ aws ecs update-service \
    --cluster my-fargate-cluster \
    --service my-fargate-service \
    --desired-count 0
```

**Wait for the service to stabilize**

Wait for the service to finish scaling down.

```
$ aws ecs wait services-stable \
    --cluster my-fargate-cluster \
    --services my-fargate-service
```

**Delete the service**

Delete the service from your cluster.

```
$ aws ecs delete-service \
    --cluster my-fargate-cluster \
    --service my-fargate-service
```

**Delete the cluster**

Delete the ECS cluster.

```
$ aws ecs delete-cluster --cluster my-fargate-cluster
```

**Delete the security group**

Finally, delete the security group you created.

```
$ aws ec2 delete-security-group --group-id $SECURITY_GROUP_ID
```

All resources created in this tutorial have been cleaned up.

## Going to production

This tutorial is designed to help you understand how Amazon ECS and AWS Fargate work. The configuration used here is suitable for learning and testing, but requires several modifications for production use.

### Security considerations

**Network security**: This tutorial creates a security group that allows HTTP traffic from anywhere on the internet (0.0.0.0/0). In production, you should restrict access to specific IP ranges or use an Application Load Balancer with more restrictive security groups.

**VPC design**: The tutorial uses the default VPC for simplicity. Production applications should use a custom VPC with private subnets for tasks and public subnets for load balancers.

**Container security**: Consider using private container registries, enabling image vulnerability scanning, and implementing least-privilege IAM policies for your tasks.

### High availability and scalability

**Multi-AZ deployment**: Deploy your service across multiple Availability Zones for fault tolerance.

**Auto scaling**: Configure service auto scaling based on CPU utilization, memory utilization, or custom metrics.

**Load balancing**: Use an Application Load Balancer to distribute traffic across multiple tasks and provide health checks.

### Monitoring and logging

**Container Insights**: Enable Amazon ECS Container Insights for detailed monitoring of your clusters, services, and tasks.

**Application logging**: Configure centralized logging using Amazon CloudWatch Logs or other logging solutions.

**Distributed tracing**: Implement AWS X-Ray for distributed tracing across your microservices.

### Additional resources

For comprehensive guidance on production-ready architectures and security best practices, see:

- [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html)
- [Amazon ECS security best practices](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/security.html)
- [AWS Architecture Center](https://aws.amazon.com/architecture/)
- [Amazon ECS Workshop](https://ecsworkshop.com/)

## Next steps

Now that you've successfully created and run an Amazon ECS task using Fargate, you can explore additional features:

- [Amazon ECS task definitions](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definitions.html) - Learn more about configuring task definitions with advanced options like environment variables, volumes, and logging.
- [Amazon ECS services](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html) - Discover how to configure load balancers, auto scaling, and service discovery for your services.
- [Amazon ECS clusters](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/clusters.html) - Explore cluster management, capacity providers, and container insights.
- [AWS Fargate](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_Fargate.html) - Learn about Fargate platform versions, task networking, and storage options.
- [Amazon ECS security](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/security.html) - Understand security best practices for ECS tasks and services.
