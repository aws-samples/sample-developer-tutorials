# Creating an Amazon ECS service for the EC2 launch type with the AWS CLI

This tutorial guides you through setting up an Amazon Elastic Container Service (ECS) cluster using the EC2 launch type with the AWS CLI. You'll learn how to create a cluster, launch a container instance, register a task definition, and create a service to run and maintain your containerized application.

## Topics

* [Prerequisites](#prerequisites)
* [Create an ECS cluster](#create-an-ecs-cluster)
* [Launch a container instance](#launch-a-container-instance)
* [Register a task definition](#register-a-task-definition)
* [Create and monitor a service](#create-and-monitor-a-service)
* [Clean up resources](#clean-up-resources)
* [Next steps](#next-steps)

## Prerequisites

Before you begin this tutorial, make sure you have the following.

1. The AWS CLI. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html). You can also [use AWS CloudShell](https://docs.aws.amazon.com/cloudshell/latest/userguide/welcome.html), which includes the AWS CLI.
2. Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
3. Basic familiarity with command line interfaces and containerization concepts.
4. An AWS account with permissions to create and manage ECS, EC2, and IAM resources. Your IAM user should have the [AmazonECS_FullAccess](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/security-iam-awsmanpol.html#security-iam-awsmanpol-AmazonECS_FullAccess) policy attached.
5. A default VPC in your AWS account. If you don't have one, you can [create a VPC](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/get-set-up-for-amazon-ecs.html#create-a-vpc) using the Amazon VPC console.

Before you start, verify your AWS CLI configuration. 

```
$ aws sts get-caller-identity
```

Output:

```
{
    "UserId": "AIDACKCEVSQ6C2EXAMPLE",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/username"
}
```
After verifying your CLI configuration, check that you have a default VPC available.

```
$ aws ec2 describe-vpcs --filters "Name=is-default,Values=true" --query 'Vpcs[0].VpcId' --output text
```

Output:

```
vpc-abcd1234
```

Let's get started with creating and managing Amazon ECS resources using the CLI.

## Create an ECS cluster

An ECS cluster is a logical grouping of tasks or services that run on container instances. In this section, you'll create a new cluster to host your containerized applications.

**Create a new cluster**

The following command creates a new ECS cluster named "MyCluster".

```
$ aws ecs create-cluster --cluster-name MyCluster
```

Output:

```
{
    "cluster": {
        "clusterName": "MyCluster",
        "status": "ACTIVE",
        "clusterArn": "arn:aws:ecs:us-east-1:123456789012:cluster/MyCluster"
    }
}
```

The response shows that your cluster has been created successfully and is in the `ACTIVE` status. You can now launch container instances and run tasks in this cluster.

**Verify cluster creation**

You can list all clusters in your account to verify that your cluster was created.

```
$ aws ecs list-clusters
```

Output:

```
{
    "clusterArns": [
        "arn:aws:ecs:us-east-1:123456789012:cluster/default",
        "arn:aws:ecs:us-east-1:123456789012:cluster/MyCluster"
    ]
}
```

The output shows both the default cluster (created automatically) and your new MyCluster.

## Launch a container instance

Container instances are EC2 instances that run the Amazon ECS container agent and have been registered into a cluster. In this section, you'll launch an EC2 instance using the ECS-optimized AMI.

**Get the ECS-optimized AMI ID**

First, retrieve the latest ECS-optimized Amazon Linux 2 AMI ID for your region.

```
$ aws ssm get-parameters --names /aws/service/ecs/optimized-ami/amazon-linux-2/recommended --query 'Parameters[0].Value' --output text | jq -r '.image_id'
```

Output:

```
ami-abcd1234
```

This command uses AWS Systems Manager Parameter Store to get the latest ECS-optimized AMI ID. The AMI includes the ECS container agent and Docker runtime pre-installed.

**Create a security group**

Create a security group that allows SSH access for managing your container instance and HTTP access for the web server.

```
$ aws ec2 create-security-group --group-name ecs-tutorial-sg --description "ECS tutorial security group"
```

Output:

```
{
    "GroupId": "sg-abcd1234"
}
```

```
$ aws ec2 authorize-security-group-ingress --group-id sg-abcd1234 --protocol tcp --port 80 --cidr 0.0.0.0/0
```

Output:

```
{
    "Return": true,
    "SecurityGroupRules": [
        {
            "SecurityGroupRuleId": "sgr-efgh5678",
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

The security group now allows SSH access from the specified IP range and HTTP access from anywhere. In a production environment, you should restrict SSH access to your specific IP address and consider limiting HTTP access as needed.

**Create a key pair**

Create an EC2 key pair for SSH access to your container instance.

```
$ aws ec2 create-key-pair --key-name ecs-tutorial-key --query 'KeyMaterial' --output text > ecs-tutorial-key.pem
$ chmod 400 ecs-tutorial-key.pem
```

The private key is saved to your local machine with appropriate permissions for SSH access.

**Launch the container instance**

Launch an EC2 instance using the ECS-optimized AMI and configure it to join your cluster.

```
$ aws ec2 run-instances --image-id ami-abcd1234 --instance-type t3.micro --key-name ecs-tutorial-key --security-group-ids sg-abcd1234 --iam-instance-profile Name=ecsInstanceRole --user-data '#!/bin/bash
echo ECS_CLUSTER=MyCluster >> /etc/ecs/ecs.config'
```

Output:

```
{
    "Instances": [
        {
            "InstanceId": "i-abcd1234",
            "ImageId": "ami-abcd1234",
            "State": {
                "Code": 0,
                "Name": "pending"
            },
            "PrivateDnsName": "",
            "PublicDnsName": "",
            "StateReason": {
                "Code": "pending",
                "Message": "pending"
            },
            "InstanceType": "t3.micro",
            "KeyName": "ecs-tutorial-key",
            "LaunchTime": "2025-01-13T10:30:00.000Z"
        }
    ]
}
```

The user data script configures the ECS agent to register the instance with your MyCluster. The instance uses the ecsInstanceRole IAM role, which provides the necessary permissions for the ECS agent.

**Verify container instance registration**

After a few minutes, check that your container instance has registered with the cluster.

```
$ aws ecs list-container-instances --cluster MyCluster
```

Output:

```
{
    "containerInstanceArns": [
        "arn:aws:ecs:us-east-1:123456789012:container-instance/MyCluster/abcd1234-5678-90ab-cdef-1234567890ab"
    ]
}
```

The output shows that one container instance has successfully registered with your cluster.

**Get container instance details**

You can get detailed information about your container instance, including available resources.

```
$ aws ecs describe-container-instances --cluster MyCluster --container-instances abcd1234-5678-90ab-cdef-1234567890ab
```

Output:

```
{
    "containerInstances": [
        {
            "containerInstanceArn": "arn:aws:ecs:us-east-1:123456789012:container-instance/MyCluster/abcd1234-5678-90ab-cdef-1234567890ab",
            "ec2InstanceId": "i-abcd1234",
            "status": "ACTIVE",
            "runningTasksCount": 0,
            "pendingTasksCount": 0,
            "agentConnected": true,
            "registeredResources": [
                {
                    "name": "CPU",
                    "type": "INTEGER",
                    "integerValue": 1024
                },
                {
                    "name": "MEMORY",
                    "type": "INTEGER",
                    "integerValue": 995
                }
            ],
            "remainingResources": [
                {
                    "name": "CPU",
                    "type": "INTEGER",
                    "integerValue": 1024
                },
                {
                    "name": "MEMORY",
                    "type": "INTEGER",
                    "integerValue": 995
                }
            ]
        }
    ]
}
```

The output shows that your container instance is active and has 1024 CPU units and 995 MB of memory available for running tasks.

## Register a task definition

A task definition is a blueprint that describes how a container should run. In this section, you'll create a simple task definition that runs a busybox container.

**Create a task definition file**

Create a JSON file that defines your task. This example creates a simple task that runs an nginx web server container.

```
$ cat > nginx-task.json << 'EOF'
{
    "family": "nginx-task",
    "containerDefinitions": [
        {
            "name": "nginx",
            "image": "public.ecr.aws/docker/library/nginx:latest",
            "cpu": 256,
            "memory": 512,
            "essential": true,
            "portMappings": [
                {
                    "containerPort": 80,
                    "hostPort": 80,
                    "protocol": "tcp"
                }
            ]
        }
    ],
    "requiresCompatibilities": ["EC2"],
    "networkMode": "bridge"
}
EOF
```

This task definition specifies a container that runs an nginx web server, exposing port 80 for HTTP traffic.

**Register the task definition**

Register your task definition with Amazon ECS.

```
$ aws ecs register-task-definition --cli-input-json file://nginx-task.json
```

Output:

```
{
    "taskDefinition": {
        "taskDefinitionArn": "arn:aws:ecs:us-east-1:123456789012:task-definition/nginx-task:1",
        "family": "nginx-task",
        "revision": 1,
        "status": "ACTIVE",
        "containerDefinitions": [
            {
                "name": "nginx",
                "image": "public.ecr.aws/docker/library/nginx:latest",
                "cpu": 256,
                "memory": 512,
                "essential": true,
                "portMappings": [
                    {
                        "containerPort": 80,
                        "hostPort": 80,
                        "protocol": "tcp"
                    }
                ],
                "environment": [],
                "mountPoints": [],
                "volumesFrom": []
            }
        ],
        "volumes": [],
        "networkMode": "bridge",
        "compatibilities": [
            "EC2"
        ],
        "requiresCompatibilities": [
            "EC2"
        ]
    }
}
```

The response shows that your task definition has been registered successfully with revision 1. You can now use this task definition to create a service.

**List task definitions**

You can list all task definitions in your account to verify registration.

```
$ aws ecs list-task-definitions
```

Output:

```
{
    "taskDefinitionArns": [
        "arn:aws:ecs:us-east-1:123456789012:task-definition/nginx-task:1"
    ]
}
```

The output shows your newly registered task definition.

## Create and monitor a service

Now that you have a cluster, container instance, and task definition, you can create a service. An ECS service runs and maintains a desired number of tasks simultaneously and can replace unhealthy tasks automatically.

**Create a service**

Use the create-service command to create a service that maintains one running instance of your nginx task.

```
$ aws ecs create-service --cluster MyCluster --service-name nginx-service --task-definition nginx-task:1 --desired-count 1
```

Output:

```
{
    "service": {
        "serviceArn": "arn:aws:ecs:us-east-1:123456789012:service/MyCluster/nginx-service",
        "serviceName": "nginx-service",
        "clusterArn": "arn:aws:ecs:us-east-1:123456789012:cluster/MyCluster",
        "taskDefinition": "arn:aws:ecs:us-east-1:123456789012:task-definition/nginx-task:1",
        "desiredCount": 1,
        "runningCount": 0,
        "pendingCount": 0,
        "launchType": "EC2",
        "status": "ACTIVE",
        "createdAt": "2025-01-13T10:45:00.000Z"
    }
}
```

The response shows that your service has been created successfully. The service will automatically start one task and maintain it in a running state.

**List services**

Check the services running in your cluster.

```
$ aws ecs list-services --cluster MyCluster
```

Output:

```
{
    "serviceArns": [
        "arn:aws:ecs:us-east-1:123456789012:service/MyCluster/nginx-service"
    ]
}
```

The output shows one service running in your cluster.

**Get detailed service information**

Get detailed information about your service, including the current status and task counts.

```
$ aws ecs describe-services --cluster MyCluster --services nginx-service
```

Output:

```
{
    "services": [
        {
            "serviceArn": "arn:aws:ecs:us-east-1:123456789012:service/MyCluster/nginx-service",
            "serviceName": "nginx-service",
            "clusterArn": "arn:aws:ecs:us-east-1:123456789012:cluster/MyCluster",
            "taskDefinition": "arn:aws:ecs:us-east-1:123456789012:task-definition/nginx-task:1",
            "desiredCount": 1,
            "runningCount": 1,
            "pendingCount": 0,
            "launchType": "EC2",
            "status": "ACTIVE",
            "createdAt": "2025-01-13T10:45:00.000Z",
            "events": [
                {
                    "id": "abcd1234-5678-90ab-cdef-1234567890ab",
                    "createdAt": "2025-01-13T10:45:30.000Z",
                    "message": "(service nginx-service) has started 1 tasks: (task abcd1234-5678-90ab-cdef-1234567890ab)."
                }
            ]
        }
    ]
}
```

The output shows that your service is active with one running task. The events section provides information about recent service activities.

**List tasks in the service**

Check the tasks that are running as part of your service.

```
$ aws ecs list-tasks --cluster MyCluster --service-name nginx-service
```

Output:

```
{
    "taskArns": [
        "arn:aws:ecs:us-east-1:123456789012:task/MyCluster/abcd1234-5678-90ab-cdef-1234567890ab"
    ]
}
```

**Get detailed task information**

Get detailed information about the task running in your service.

```
$ aws ecs describe-tasks --cluster MyCluster --tasks abcd1234-5678-90ab-cdef-1234567890ab
```

Output:

```
{
    "tasks": [
        {
            "taskArn": "arn:aws:ecs:us-east-1:123456789012:task/MyCluster/abcd1234-5678-90ab-cdef-1234567890ab",
            "clusterArn": "arn:aws:ecs:us-east-1:123456789012:cluster/MyCluster",
            "taskDefinitionArn": "arn:aws:ecs:us-east-1:123456789012:task-definition/nginx-task:1",
            "containerInstanceArn": "arn:aws:ecs:us-east-1:123456789012:container-instance/MyCluster/abcd1234-5678-90ab-cdef-1234567890ab",
            "lastStatus": "RUNNING",
            "desiredStatus": "RUNNING",
            "containers": [
                {
                    "containerArn": "arn:aws:ecs:us-east-1:123456789012:container/MyCluster/abcd1234-5678-90ab-cdef-1234567890ab/abcd1234-5678-90ab-cdef-1234567890ab",
                    "taskArn": "arn:aws:ecs:us-east-1:123456789012:task/MyCluster/abcd1234-5678-90ab-cdef-1234567890ab",
                    "name": "nginx",
                    "lastStatus": "RUNNING",
                    "networkBindings": [
                        {
                            "bindIP": "0.0.0.0",
                            "containerPort": 80,
                            "hostPort": 80,
                            "protocol": "tcp"
                        }
                    ]
                }
            ],
            "createdAt": "2025-01-13T10:45:00.000Z",
            "startedAt": "2025-01-13T10:45:30.000Z"
        }
    ]
}
```

The output shows that your task is running and the nginx container is bound to port 80 on the host. You can access the web server using the public IP address of your EC2 instance.

**Test the web server**

Get the public IP address of your container instance and test the nginx web server.

```
$ aws ec2 describe-instances --instance-ids i-abcd1234 --query 'Reservations[0].Instances[0].PublicIpAddress' --output text
```

Output:

```
203.0.113.25
```

```
$ curl http://203.0.113.25
```

Output:

```
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you can see this page, the nginx web server is successfully installed and working.</p>
...
</body>
</html>
```

The nginx welcome page confirms that your service is running successfully and accessible from the internet.

## Clean up resources

To avoid incurring charges, clean up the resources you created in this tutorial.

**Delete the service**

First, update the service to have zero desired tasks, then delete the service.

```
$ aws ecs update-service --cluster MyCluster --service nginx-service --desired-count 0
```

Output:

```
{
    "service": {
        "serviceArn": "arn:aws:ecs:us-east-1:123456789012:service/MyCluster/nginx-service",
        "serviceName": "nginx-service",
        "desiredCount": 0,
        "runningCount": 1,
        "pendingCount": 0,
        "status": "ACTIVE"
    }
}
```

Wait for the running tasks to stop, then delete the service.

```
$ aws ecs delete-service --cluster MyCluster --service nginx-service
```

Output:

```
{
    "service": {
        "serviceArn": "arn:aws:ecs:us-east-1:123456789012:service/MyCluster/nginx-service",
        "serviceName": "nginx-service",
        "status": "DRAINING"
    }
}
```

**Terminate the EC2 instance**

Terminate the container instance you created.

```
$ aws ec2 terminate-instances --instance-ids i-abcd1234
```

Output:

```
{
    "TerminatingInstances": [
        {
            "InstanceId": "i-abcd1234",
            "CurrentState": {
                "Code": 32,
                "Name": "shutting-down"
            },
            "PreviousState": {
                "Code": 16,
                "Name": "running"
            }
        }
    ]
}
```

**Delete the security group and key pair**

Clean up the security group and key pair you created.

```
$ aws ec2 delete-security-group --group-id sg-abcd1234
$ aws ec2 delete-key-pair --key-name ecs-tutorial-key
$ rm ecs-tutorial-key.pem
```

**Delete the ECS cluster**

Finally, delete the ECS cluster.

```
$ aws ecs delete-cluster --cluster MyCluster
```

Output:

```
{
    "cluster": {
        "clusterArn": "arn:aws:ecs:us-east-1:123456789012:cluster/MyCluster",
        "clusterName": "MyCluster",
        "status": "INACTIVE"
    }
}
```

All resources have been successfully cleaned up.

## Next steps

Now that you've learned how to create and manage Amazon ECS services with the EC2 launch type, you can explore more advanced features:

* [Use Application Load Balancers](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-load-balancing.html) to distribute traffic across multiple tasks in your service
* [Configure auto scaling](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-auto-scaling.html) to automatically adjust the number of running tasks based on demand
* [Set up CloudWatch logging](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/using_awslogs.html) to collect and monitor logs from your containers
* [Use Amazon ECR](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ECR_on_ECS.html) to store and manage your container images
* [Deploy multi-container applications](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definitions.html) using more complex task definitions
* [Configure service discovery](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-discovery.html) to enable services to find and communicate with each other
