# ECS: Run a container on Fargate

Create an ECS Fargate cluster, deploy an nginx web server, and access it via public IP.

## Source

https://docs.aws.amazon.com/AmazonECS/latest/developerguide/getting-started-ecs-ec2.html

## Use case

- ID: ecs/fargate-linux
- Phase: create
- Complexity: intermediate
- Core actions: ecs:CreateCluster, ecs:RegisterTaskDefinition, ecs:CreateService

## What it does

1. Creates or verifies the ECS task execution role
2. Creates an ECS cluster
3. Registers a Fargate task definition with nginx
4. Creates a security group allowing HTTP from your IP
5. Creates an ECS Fargate service
6. Waits for the task to start running
7. Retrieves the public IP and displays the URL
8. Cleans up all resources

## Running

```bash
bash amazon-ecs-fargate-linux.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash amazon-ecs-fargate-linux.sh
```

## Resources created

- IAM role (ecsTaskExecutionRole, if not already present)
- ECS cluster
- Task definition (Fargate, nginx on port 80)
- Security group (HTTP from your IP only)
- ECS service (1 Fargate task)

## Estimated time

- Run: ~3 minutes (service stabilization)
- Cleanup: ~2 minutes (service drain and deletion)

## Cost

Fargate tasks incur charges while running (256 CPU, 512 MiB ≈ $0.01/hour). Cleanup stops all charges.

## Related docs

- [Getting started with Amazon ECS](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/getting-started-ecs-ec2.html)
- [Amazon ECS on AWS Fargate](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_Fargate.html)
- [Amazon ECS task execution IAM role](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html)
- [Amazon ECS Service Connect](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-connect.html)
