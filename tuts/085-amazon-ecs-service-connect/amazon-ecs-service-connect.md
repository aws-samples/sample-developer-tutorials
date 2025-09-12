# Configure Amazon ECS Service Connect with the AWS CLI

This tutorial guides you through setting up Amazon ECS Service Connect using the AWS Command Line Interface (AWS CLI). You'll learn how to create an ECS cluster with Service Connect enabled, deploy a containerized application, and configure service discovery for inter-service communication.

## Topics

- [Prerequisites](#prerequisites)
- [Create the VPC infrastructure](#create-the-vpc-infrastructure)
- [Set up logging](#set-up-logging)
- [Create the ECS cluster](#create-the-ecs-cluster)
- [Configure IAM roles](#configure-iam-roles)
- [Register the task definition](#register-the-task-definition)
- [Create the service with Service Connect](#create-the-service-with-service-connect)
- [Verify the deployment](#verify-the-deployment)
- [Clean up resources](#clean-up-resources)
- [Going to production](#going-to-production)
- [Next steps](#next-steps)

## Prerequisites

Before you begin this tutorial, make sure you have the following.

1. The AWS CLI. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html). You can also [use AWS CloudShell](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_CLI.html), which includes the AWS CLI.
2. Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
3. Basic familiarity with containerization concepts and Docker.
4. [Sufficient permissions](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/security-iam-awsmanpol.html#security-iam-awsmanpol-AmazonECS_FullAccess) to create and manage ECS resources, VPC resources, and IAM roles in your AWS account.

### Cost considerations

This tutorial creates AWS resources that incur charges. The estimated cost for running this tutorial is approximately **$0.017 per hour** (based on US East 1 pricing), primarily from the ECS Fargate task. If you complete the tutorial in 2-3 hours, the total cost will be approximately $0.035-$0.052. **Follow the cleanup instructions** at the end of this tutorial to avoid ongoing charges.

Let's get started with creating the infrastructure needed for ECS Service Connect.

## Create the VPC infrastructure

Service Connect requires a VPC with proper networking configuration. In this section, you'll create a VPC with public subnets, an internet gateway, and security groups for your ECS tasks.

**Create a VPC**

The following command creates a new VPC with a CIDR block that provides enough IP addresses for your ECS tasks.

```
aws ec2 create-vpc --cidr-block 10.0.0.0/16
```

The command returns details about the new VPC, including its ID. Note the `VpcId` value for use in subsequent commands.

```
{
    "Vpc": {
        "CidrBlock": "10.0.0.0/16",
        "DhcpOptionsId": "dopt-abcd1234",
        "State": "pending",
        "VpcId": "vpc-abcd1234",
        "OwnerId": "123456789012",
        "InstanceTenancy": "default",
        "Ipv6CidrBlockAssociationSet": [],
        "CidrBlockAssociationSet": [
            {
                "AssociationId": "vpc-cidr-assoc-abcd1234",
                "CidrBlock": "10.0.0.0/16",
                "CidrBlockState": {
                    "State": "associated"
                }
            }
        ],
        "IsDefault": false
    }
}
```

**Enable DNS support**

ECS Service Connect requires DNS resolution within the VPC. Enable DNS support and DNS hostnames for your VPC.

```
aws ec2 modify-vpc-attribute --vpc-id vpc-abcd1234 --enable-dns-support
aws ec2 modify-vpc-attribute --vpc-id vpc-abcd1234 --enable-dns-hostnames
```

These commands enable DNS resolution and hostname assignment, which are required for Service Connect to function properly.

**Create public subnets**

Create two public subnets in different availability zones to provide high availability for your ECS tasks.

```
aws ec2 create-subnet --vpc-id vpc-abcd1234 --cidr-block 10.0.0.0/24 --availability-zone us-west-2a
aws ec2 create-subnet --vpc-id vpc-abcd1234 --cidr-block 10.0.1.0/24 --availability-zone us-west-2b
```

Each command creates a subnet in a different availability zone. Note the `SubnetId` values from the output for use in later steps.

**Set up internet connectivity**

Create an internet gateway and attach it to your VPC to provide internet access for your ECS tasks.

```
aws ec2 create-internet-gateway
```

The command returns an internet gateway ID. Use this ID to attach the gateway to your VPC.

```
aws ec2 attach-internet-gateway --internet-gateway-id igw-abcd1234 --vpc-id vpc-abcd1234
```

**Configure routing**

Create a route table and add a route to the internet gateway to enable outbound internet access.

```
aws ec2 create-route-table --vpc-id vpc-abcd1234
```

Add a default route to the internet gateway and associate the route table with your subnets.

```
aws ec2 create-route --route-table-id rtb-abcd1234 --destination-cidr-block 0.0.0.0/0 --gateway-id igw-abcd1234
aws ec2 associate-route-table --route-table-id rtb-abcd1234 --subnet-id subnet-abcd1234
aws ec2 associate-route-table --route-table-id rtb-abcd1234 --subnet-id subnet-efgh5678
```

These commands ensure that your ECS tasks can reach the internet to pull container images and communicate with AWS services.

**Create a security group**

Create a security group that allows HTTP traffic within the VPC for your ECS tasks.

```
aws ec2 create-security-group --group-name tutorial-ecs-sg --description "ECS Service Connect security group" --vpc-id vpc-abcd1234
```

Add an inbound rule to allow HTTP traffic from within the VPC.

```
aws ec2 authorize-security-group-ingress --group-id sg-abcd1234 --protocol tcp --port 80 --cidr 10.0.0.0/16
```

This security group configuration follows the principle of least privilege by only allowing HTTP traffic from within the VPC.

## Set up logging

CloudWatch Logs provides centralized logging for your ECS tasks and Service Connect proxy. Create log groups for both the application and the Service Connect proxy.

**Create log groups**

The following commands create log groups for the nginx application and the Service Connect proxy.

```
aws logs create-log-group --log-group-name /ecs/service-connect-nginx
aws logs create-log-group --log-group-name /ecs/service-connect-proxy
```

These log groups will store logs from your application container and the Service Connect proxy, making it easier to troubleshoot issues and monitor your services.

## Create the ECS cluster

An ECS cluster with Service Connect provides a logical grouping of tasks and services with built-in service discovery capabilities.

**Create the cluster with Service Connect defaults**

The following command creates an ECS cluster with Service Connect enabled and sets up a default namespace.

```
aws ecs create-cluster --cluster-name tutorial-cluster --service-connect-defaults namespace=service-connect
```

The command creates both the ECS cluster and a Service Connect namespace. The namespace provides service discovery within the cluster.

```
{
    "cluster": {
        "clusterArn": "arn:aws:ecs:us-west-2:123456789012:cluster/tutorial-cluster",
        "clusterName": "tutorial-cluster",
        "serviceConnectDefaults": {
            "namespace": "arn:aws:servicediscovery:us-west-2:123456789012:namespace/ns-xmpl1234"
        },
        "status": "PROVISIONING",
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
        "defaultCapacityProviderStrategy": [],
        "attachments": [
            {
                "id": "a1b2c3d4-5678-90ab-cdef-xmpl12345678",
                "type": "sc",
                "status": "ATTACHING",
                "details": []
            }
        ],
        "attachmentsStatus": "UPDATE_IN_PROGRESS"
    }
}
```

**Verify cluster creation**

Check that your cluster is active and ready to host services.

```
aws ecs describe-clusters --clusters tutorial-cluster
```

Wait for the cluster status to show `ACTIVE` before proceeding to the next step.

## Configure IAM roles

ECS tasks require IAM roles to interact with AWS services. You'll need both a task execution role and a task role for Service Connect functionality.

**Create the task execution role**

The task execution role allows ECS to pull container images and write logs to CloudWatch.

```
aws iam create-role --role-name ecsTaskExecutionRole --assume-role-policy-document '{
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
}'
```

Attach the managed policy that provides the necessary permissions.

```
aws iam attach-role-policy --role-name ecsTaskExecutionRole --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
```

**Create the task role**

The task role provides permissions for the running task, including ECS Exec capabilities.

```
aws iam create-role --role-name ecsTaskRole --assume-role-policy-document '{
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
}'
```

Add an inline policy for ECS Exec functionality.

```
aws iam put-role-policy --role-name ecsTaskRole --policy-name ECSExecPolicy --policy-document '{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ssmmessages:CreateControlChannel",
                "ssmmessages:CreateDataChannel",
                "ssmmessages:OpenControlChannel",
                "ssmmessages:OpenDataChannel"
            ],
            "Resource": "*"
        }
    ]
}'
```

These roles provide the minimum permissions required for ECS tasks with Service Connect and ECS Exec capabilities.

## Register the task definition

A task definition specifies the container configuration and Service Connect settings for your application.

**Create the task definition**

The following command registers a task definition for an nginx web server with Service Connect configuration.

```
aws ecs register-task-definition --family service-connect-nginx --execution-role-arn arn:aws:iam::123456789012:role/ecsTaskExecutionRole --task-role-arn arn:aws:iam::123456789012:role/ecsTaskRole --network-mode awsvpc --requires-compatibilities FARGATE --cpu 256 --memory 512 --container-definitions '[
    {
        "name": "webserver",
        "image": "public.ecr.aws/docker/library/nginx:latest",
        "cpu": 100,
        "portMappings": [
            {
                "name": "nginx",
                "containerPort": 80,
                "protocol": "tcp",
                "appProtocol": "http"
            }
        ],
        "essential": true,
        "logConfiguration": {
            "logDriver": "awslogs",
            "options": {
                "awslogs-group": "/ecs/service-connect-nginx",
                "awslogs-region": "us-west-2",
                "awslogs-stream-prefix": "nginx"
            }
        }
    }
]'
```

The task definition includes a named port mapping with `appProtocol` specified, which is required for Service Connect to understand how to route traffic to your service.

```
{
    "taskDefinition": {
        "taskDefinitionArn": "arn:aws:ecs:us-west-2:123456789012:task-definition/service-connect-nginx:1",
        "family": "service-connect-nginx",
        "taskRoleArn": "arn:aws:iam::123456789012:role/ecsTaskRole",
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
                "name": "webserver",
                "image": "public.ecr.aws/docker/library/nginx:latest",
                "cpu": 100,
                "memory": 0,
                "portMappings": [
                    {
                        "name": "nginx",
                        "containerPort": 80,
                        "hostPort": 80,
                        "protocol": "tcp",
                        "appProtocol": "http"
                    }
                ],
                "essential": true,
                "environment": [],
                "mountPoints": [],
                "volumesFrom": [],
                "logConfiguration": {
                    "logDriver": "awslogs",
                    "options": {
                        "awslogs-group": "/ecs/service-connect-nginx",
                        "awslogs-region": "us-west-2",
                        "awslogs-stream-prefix": "nginx"
                    }
                }
            }
        ]
    }
}
```

## Create the service with Service Connect

An ECS service manages the desired number of running tasks and integrates with Service Connect for service discovery.

**Create the service**

The following command creates an ECS service with Service Connect enabled.

```
aws ecs create-service --cluster tutorial-cluster --service-name service-connect-nginx-service --task-definition service-connect-nginx --desired-count 1 --launch-type FARGATE --platform-version LATEST --network-configuration 'awsvpcConfiguration={assignPublicIp=ENABLED,securityGroups=[sg-abcd1234],subnets=[subnet-abcd1234,subnet-efgh5678]}' --service-connect-configuration '{
    "enabled": true,
    "services":[
        {
            "portName": "nginx",
            "clientAliases":[
                {
                    "port": 80
                }
            ]
        }
    ],
    "logConfiguration":{
        "logDriver": "awslogs",
        "options":{
            "awslogs-group": "/ecs/service-connect-proxy",
            "awslogs-region": "us-west-2",
            "awslogs-stream-prefix": "service-connect-proxy"
        }
    }
}' --enable-execute-command
```

The Service Connect configuration enables service discovery and creates a client alias that other services can use to connect to this service.

```
{
    "service": {
        "serviceArn": "arn:aws:ecs:us-west-2:123456789012:service/tutorial-cluster/service-connect-nginx-service",
        "serviceName": "service-connect-nginx-service",
        "clusterArn": "arn:aws:ecs:us-west-2:123456789012:cluster/tutorial-cluster",
        "loadBalancers": [],
        "serviceRegistries": [],
        "status": "ACTIVE",
        "desiredCount": 1,
        "runningCount": 0,
        "pendingCount": 0,
        "launchType": "FARGATE",
        "platformVersion": "LATEST",
        "platformFamily": "Linux",
        "taskDefinition": "arn:aws:ecs:us-west-2:123456789012:task-definition/service-connect-nginx:1",
        "deploymentConfiguration": {
            "deploymentCircuitBreaker": {
                "enable": false,
                "rollback": false
            },
            "maximumPercent": 200,
            "minimumHealthyPercent": 100
        },
        "deployments": [
            {
                "id": "ecs-svc/1234567890123456789",
                "status": "PRIMARY",
                "taskDefinition": "arn:aws:ecs:us-west-2:123456789012:task-definition/service-connect-nginx:1",
                "desiredCount": 1,
                "pendingCount": 0,
                "runningCount": 0,
                "failedTasks": 0,
                "createdAt": "2025-01-13T12:00:00.000000+00:00",
                "updatedAt": "2025-01-13T12:00:00.000000+00:00",
                "launchType": "FARGATE",
                "platformVersion": "1.4.0",
                "platformFamily": "Linux",
                "networkConfiguration": {
                    "awsvpcConfiguration": {
                        "subnets": [
                            "subnet-abcd1234",
                            "subnet-efgh5678"
                        ],
                        "securityGroups": [
                            "sg-abcd1234"
                        ],
                        "assignPublicIp": "ENABLED"
                    }
                },
                "rolloutState": "IN_PROGRESS",
                "rolloutStateReason": "ECS deployment ecs-svc/1234567890123456789 in progress.",
                "serviceConnectConfiguration": {
                    "enabled": true,
                    "namespace": "service-connect",
                    "services": [
                        {
                            "portName": "nginx",
                            "clientAliases": [
                                {
                                    "port": 80
                                }
                            ]
                        }
                    ],
                    "logConfiguration": {
                        "logDriver": "awslogs",
                        "options": {
                            "awslogs-group": "/ecs/service-connect-proxy",
                            "awslogs-region": "us-west-2",
                            "awslogs-stream-prefix": "service-connect-proxy"
                        }
                    }
                },
                "serviceConnectResources": [
                    {
                        "discoveryName": "nginx",
                        "discoveryArn": "arn:aws:servicediscovery:us-west-2:123456789012:service/srv-xmpl1234"
                    }
                ]
            }
        ],
        "roleArn": "arn:aws:iam::123456789012:role/aws-service-role/ecs.amazonaws.com/AWSServiceRoleForECS",
        "events": [],
        "createdAt": "2025-01-13T12:00:00.000000+00:00",
        "placementConstraints": [],
        "placementStrategy": [],
        "networkConfiguration": {
            "awsvpcConfiguration": {
                "subnets": [
                    "subnet-abcd1234",
                    "subnet-efgh5678"
                ],
                "securityGroups": [
                    "sg-abcd1234"
                ],
                "assignPublicIp": "ENABLED"
            }
        },
        "healthCheckGracePeriodSeconds": 0,
        "schedulingStrategy": "REPLICA",
        "deploymentController": {
            "type": "ECS"
        },
        "createdBy": "arn:aws:iam::123456789012:user/tutorial-user",
        "enableECSManagedTags": false,
        "propagateTags": "NONE",
        "enableExecuteCommand": true
    }
}
```

**Wait for service stability**

Wait for the service to reach a stable state before proceeding.

```
aws ecs wait services-stable --cluster tutorial-cluster --services service-connect-nginx-service
```

This command waits until the service deployment is complete and all tasks are running successfully.

## Verify the deployment

After creating your service, verify that Service Connect is working correctly and your application is accessible.

**Check service status**

Verify that your service is running and has the expected number of tasks.

```
aws ecs describe-services --cluster tutorial-cluster --services service-connect-nginx-service --query 'services[0].{Status:status,Running:runningCount,Desired:desiredCount}'
```

The output should show that the service is active with one running task.

```
{
    "Status": "ACTIVE",
    "Running": 1,
    "Desired": 1
}
```

**View Service Connect configuration**

Check the Service Connect configuration to confirm it's properly set up.

```
aws ecs describe-services --cluster tutorial-cluster --services service-connect-nginx-service --query 'services[0].deployments[0].serviceConnectConfiguration'
```

The output shows the Service Connect namespace, service discovery name, and client aliases that other services can use to connect to your nginx service.

```
{
    "enabled": true,
    "namespace": "arn:aws:servicediscovery:us-west-2:123456789012:namespace/ns-xmpl1234",
    "services": [
        {
            "portName": "nginx",
            "discoveryName": "nginx",
            "clientAliases": [
                {
                    "port": 80,
                    "dnsName": "nginx.service-connect"
                }
            ]
        }
    ],
    "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
            "awslogs-group": "/ecs/service-connect-proxy",
            "awslogs-region": "us-west-2",
            "awslogs-stream-prefix": "service-connect-proxy"
        }
    }
}
```

**Verify Service Connect namespace**

Confirm that the Service Connect namespace is active in AWS Cloud Map.

```
aws servicediscovery list-namespaces --query "Namespaces[?Name=='service-connect']"
```

This command shows the namespace created by Service Connect for service discovery within your cluster.

Your nginx service is now accessible to other services in the same namespace using the DNS name `nginx.service-connect` on port 80. Service Connect automatically handles load balancing and service discovery between your containerized applications.

## Clean up resources

To avoid incurring charges, delete the resources you created in this tutorial when you're finished experimenting.

**Delete the ECS service and cluster**

First, scale the service to zero tasks, then delete the service and cluster.

```
aws ecs update-service --cluster tutorial-cluster --service service-connect-nginx-service --desired-count 0
aws ecs delete-service --cluster tutorial-cluster --service service-connect-nginx-service --force
aws ecs delete-cluster --cluster tutorial-cluster
```

**Delete networking resources**

Remove the VPC and associated networking components.

```
aws ec2 delete-security-group --group-id sg-abcd1234
aws ec2 disassociate-route-table --association-id rtbassoc-abcd1234
aws ec2 delete-route-table --route-table-id rtb-abcd1234
aws ec2 detach-internet-gateway --internet-gateway-id igw-abcd1234 --vpc-id vpc-abcd1234
aws ec2 delete-internet-gateway --internet-gateway-id igw-abcd1234
aws ec2 delete-subnet --subnet-id subnet-abcd1234
aws ec2 delete-subnet --subnet-id subnet-efgh5678
aws ec2 delete-vpc --vpc-id vpc-abcd1234
```

**Delete log groups**

Remove the CloudWatch log groups to stop incurring log storage charges.

```
aws logs delete-log-group --log-group-name /ecs/service-connect-nginx
aws logs delete-log-group --log-group-name /ecs/service-connect-proxy
```

**Clean up IAM roles (optional)**

If you created the IAM roles specifically for this tutorial, you can delete them.

```
aws iam detach-role-policy --role-name ecsTaskExecutionRole --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
aws iam delete-role-policy --role-name ecsTaskRole --policy-name ECSExecPolicy
aws iam delete-role --role-name ecsTaskExecutionRole
aws iam delete-role --role-name ecsTaskRole
```

## Going to production

This tutorial is designed to help you learn how ECS Service Connect works in a simple, cost-effective environment. For production deployments, you should consider additional security, scalability, and operational requirements that are beyond the scope of this tutorial.

### Security considerations

- **Private subnets**: Move ECS tasks to private subnets and use a NAT Gateway for outbound internet access
- **Service Connect TLS**: Enable TLS encryption for service-to-service communication
- **Secrets management**: Use AWS Secrets Manager for sensitive configuration data
- **Network security**: Implement more restrictive security group rules and consider network ACLs
- **Container security**: Scan container images for vulnerabilities and use private ECR repositories

### Architecture considerations

- **Auto scaling**: Configure ECS Service Auto Scaling based on CloudWatch metrics
- **Load balancing**: Add an Application Load Balancer for external traffic
- **Multi-region deployment**: Implement cross-region deployment for disaster recovery
- **Monitoring and observability**: Add comprehensive monitoring, alerting, and distributed tracing
- **Database integration**: Add managed database services with proper scaling and backup strategies

For comprehensive guidance on production-ready architectures, see the [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html) and [AWS Architecture Center](https://aws.amazon.com/architecture/). For security best practices, see the [AWS Security Best Practices](https://docs.aws.amazon.com/security/latest/userguide/security-best-practices.html).

## Next steps

Now that you've successfully configured ECS Service Connect, consider exploring these related topics:

- [Service Connect concepts](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-connect-concepts.html) - Learn more about Service Connect architecture and components
- [Service Connect configuration](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-connect-configuration.html) - Explore advanced Service Connect configuration options
- [ECS Service Connect with Application Load Balancer](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-connect-alb.html) - Integrate Service Connect with load balancers for external traffic
- [Service Connect TLS encryption](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-connect-tls.html) - Secure inter-service communication with TLS
- [ECS Exec](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-exec.html) - Debug and troubleshoot your containers using ECS Exec
- [Amazon ECS monitoring](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cloudwatch-metrics.html) - Monitor your ECS services with CloudWatch metrics and logs
