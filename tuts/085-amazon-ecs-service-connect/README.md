# ECS: Service Connect

Deploy two ECS Fargate services that communicate using Amazon ECS Service Connect.

## Source

https://docs.aws.amazon.com/AmazonECS/latest/developerguide/create-service-connect.html

## Use case

- ID: ecs/service-connect
- Phase: create
- Complexity: advanced
- Core actions: ecs:CreateCluster, ecs:CreateService, ecs:RegisterTaskDefinition, servicediscovery:CreateHttpNamespace

## What it does

1. Creates an ECS cluster with Service Connect defaults
2. Creates a Cloud Map namespace for service discovery
3. Creates the ecsTaskExecutionRole (if it doesn't exist)
4. Registers task definitions for client and server services
5. Creates a security group and authorizes traffic
6. Deploys server and client services with Service Connect
7. Verifies services are running and connected
8. Cleans up all resources including security group rules

## Running

```bash
bash amazon-ecs-service-connect.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash amazon-ecs-service-connect.sh
```

## Resources created

- ECS cluster
- Cloud Map HTTP namespace
- IAM role (ecsTaskExecutionRole, if not pre-existing)
- 2 ECS task definitions
- Security group with ingress rules
- 2 ECS Fargate services
- CloudWatch log groups

## Estimated time

- Run: ~5 minutes (Fargate task provisioning)
- Cleanup: ~3 minutes (service drain + security group detach)

## Cost

Fargate pricing: ~$0.04/hour for two minimal tasks. Clean up promptly after the tutorial.

## Related docs

- [Service Connect](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-connect.html)
- [Creating a service with Service Connect](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/create-service-connect.html)
- [Amazon ECS task execution IAM role](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html)
