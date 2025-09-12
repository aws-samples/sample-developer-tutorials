# Getting started with Amazon EKS using the AWS CLI

This tutorial guides you through creating and managing an Amazon Elastic Kubernetes Service (Amazon EKS) cluster using the AWS Command Line Interface (AWS CLI). You'll learn how to create all the required resources for a functional EKS cluster, including a VPC, IAM roles, the cluster itself, and a managed node group.

## Prerequisites

Before you begin this tutorial, make sure you have the following:

1. The AWS CLI version 2 installed and configured. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).

2. The `kubectl` command line tool installed. For installation instructions, see [Installing kubectl](https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html).

3. Sufficient IAM permissions to create and manage EKS clusters, IAM roles, CloudFormation stacks, and VPC resources. For more information about the required permissions, see [Amazon EKS IAM permissions](https://docs.aws.amazon.com/eks/latest/userguide/security_iam_service-with-iam.html).

4. Basic familiarity with Kubernetes concepts and command line interfaces.

5. **Estimated time**: This tutorial takes approximately 30-45 minutes to complete, not including wait times for resource creation (EKS cluster creation can take 10-15 minutes).

6. **Estimated cost**: The resources created in this tutorial will cost approximately $0.23 per hour ($166 per month if left running). This includes:
   - EKS Cluster: $0.10 per hour
   - EC2 Instances (2 x t3.medium): $0.0832 per hour
   - NAT Gateway: $0.045 per hour

Verify that your AWS CLI is properly configured by running the following command:

```
aws sts get-caller-identity
```

This command returns your AWS account ID, IAM user or role, and AWS account ARN, confirming that your credentials are set up correctly.

## Create a VPC for your EKS cluster

Amazon EKS requires a VPC with specific configurations to operate properly. In this section, you'll create a VPC with public and private subnets using an AWS CloudFormation template.

Run the following command to create a VPC using a CloudFormation template provided by AWS:

```
aws cloudformation create-stack \
  --stack-name my-eks-vpc-stack \
  --template-url https://s3.us-west-2.amazonaws.com/amazon-eks/cloudformation/2020-10-29/amazon-eks-vpc-private-subnets.yaml
```

This command creates a CloudFormation stack that provisions a VPC with both public and private subnets across multiple Availability Zones, along with the necessary route tables and security groups for an EKS cluster.

Wait for the stack creation to complete before proceeding:

```
aws cloudformation wait stack-create-complete \
  --stack-name my-eks-vpc-stack
```

The CloudFormation stack creates all the networking resources required for your EKS cluster, including subnets with the proper tagging for Kubernetes to use them effectively.

## Create IAM roles for your EKS cluster

Amazon EKS requires two IAM roles: one for the EKS cluster service and another for the worker nodes. In this section, you'll create both roles with the necessary permissions.

**Create the EKS cluster IAM role**

First, create a trust policy file that allows the EKS service to assume the role:

```
cat > eks-cluster-role-trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
```

This trust policy defines that only the EKS service can assume this role.

Now create the cluster role using the trust policy:

```
aws iam create-role \
  --role-name myAmazonEKSClusterRole \
  --assume-role-policy-document file://"eks-cluster-role-trust-policy.json"
```

Attach the required EKS cluster policy to the role:

```
aws iam attach-role-policy \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy \
  --role-name myAmazonEKSClusterRole
```

This policy grants the permissions necessary for EKS to create and manage resources on your behalf.

**Create the EKS node IAM role**

Create a trust policy file for the node role that allows EC2 instances to assume the role:

```
cat > node-role-trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
```

Create the node role using this trust policy:

```
aws iam create-role \
  --role-name myAmazonEKSNodeRole \
  --assume-role-policy-document file://"node-role-trust-policy.json"
```

Attach the three required policies to the node role:

```
aws iam attach-role-policy \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy \
  --role-name myAmazonEKSNodeRole

aws iam attach-role-policy \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly \
  --role-name myAmazonEKSNodeRole

aws iam attach-role-policy \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy \
  --role-name myAmazonEKSNodeRole
```

These policies allow the worker nodes to connect to the EKS cluster, download container images, and configure networking.

## Create your EKS cluster

Now that you have the necessary networking and IAM resources, you can create your EKS cluster. In this section, you'll retrieve information from your VPC and create the cluster.

First, retrieve the VPC ID, subnet IDs, and security group ID from the CloudFormation stack:

```
VPC_ID=$(aws cloudformation describe-stacks \
  --stack-name my-eks-vpc-stack \
  --query "Stacks[0].Outputs[?OutputKey=='VpcId'].OutputValue" \
  --output text)

SUBNET_IDS=$(aws cloudformation describe-stacks \
  --stack-name my-eks-vpc-stack \
  --query "Stacks[0].Outputs[?OutputKey=='SubnetIds'].OutputValue" \
  --output text)

SECURITY_GROUP_ID=$(aws cloudformation describe-stacks \
  --stack-name my-eks-vpc-stack \
  --query "Stacks[0].Outputs[?OutputKey=='SecurityGroups'].OutputValue" \
  --output text)
```

These commands extract the necessary resource IDs from the CloudFormation stack outputs.

Now create the EKS cluster using these resources:

```
aws eks create-cluster \
  --name my-cluster \
  --role-arn $(aws iam get-role --role-name myAmazonEKSClusterRole --query "Role.Arn" --output text) \
  --resources-vpc-config subnetIds=$SUBNET_IDS,securityGroupIds=$SECURITY_GROUP_ID
```

This command creates an EKS cluster named "my-cluster" using the IAM role and VPC resources you created earlier.

Creating an EKS cluster takes 10-15 minutes. Wait for the cluster to become active before proceeding:

```
aws eks wait cluster-active \
  --name my-cluster
```

This command will wait until the cluster is fully provisioned and active.

## Configure kubectl to communicate with your cluster

To interact with your Kubernetes cluster, you need to configure the `kubectl` tool. In this section, you'll update your kubeconfig file to connect to your new cluster.

Run the following command to update your kubeconfig:

```
aws eks update-kubeconfig \
  --name my-cluster
```

This command adds an entry to your kubeconfig file that contains the necessary information to connect to your EKS cluster.

Test your configuration by retrieving the cluster services:

```
kubectl get svc
```

If successful, you should see output similar to:

```
NAME             TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
svc/kubernetes   ClusterIP   10.100.0.1   <none>        443/TCP   1m
```

This confirms that your kubectl configuration is working correctly and can communicate with your EKS cluster.

## Create a managed node group

Now that your EKS cluster is running, you need to add worker nodes to run your applications. In this section, you'll create a managed node group that automatically provisions and manages EC2 instances for your cluster.

Create a managed node group using the node role you created earlier:

```
aws eks create-nodegroup \
  --cluster-name my-cluster \
  --nodegroup-name my-nodegroup \
  --node-role $(aws iam get-role --role-name myAmazonEKSNodeRole --query "Role.Arn" --output text) \
  --subnets $(echo $SUBNET_IDS | tr ',' ' ')
```

This command creates a managed node group named "my-nodegroup" in your EKS cluster, using the IAM role and subnets you specified.

Creating a node group takes 5-10 minutes. Wait for the node group to become active:

```
aws eks wait nodegroup-active \
  --cluster-name my-cluster \
  --nodegroup-name my-nodegroup
```

Once the node group is active, verify that the nodes have joined your cluster:

```
kubectl get nodes
```

You should see a list of nodes that have been provisioned and joined your cluster. If the nodes don't appear immediately, wait a minute or two and try again, as it takes some time for the nodes to register with the Kubernetes control plane.

## View your cluster resources

Now that your cluster is up and running with worker nodes, you can explore the resources that have been created. In this section, you'll use both AWS CLI and kubectl commands to view your cluster resources.

View detailed information about your cluster:

```
aws eks describe-cluster \
  --name my-cluster
```

This command provides comprehensive information about your EKS cluster, including its status, endpoint, and configuration.

View information about your node group:

```
aws eks describe-nodegroup \
  --cluster-name my-cluster \
  --nodegroup-name my-nodegroup
```

This command shows details about your managed node group, including the instance types, scaling configuration, and health status.

View all Kubernetes resources across all namespaces:

```
kubectl get all --all-namespaces
```

This command lists all Kubernetes resources (pods, services, deployments, etc.) running in your cluster across all namespaces.

## Troubleshooting

If you encounter issues during this tutorial, here are some common problems and their solutions:

**Issue: Insufficient permissions**

If you receive an error about insufficient permissions, ensure that your IAM user or role has the necessary permissions to create and manage EKS resources. You may need to attach additional policies or create a custom policy.

**Issue: Cluster creation fails**

If cluster creation fails, check the error message for details. Common issues include:
- VPC configuration problems: Ensure your VPC has both public and private subnets.
- Service quota limits: You may have reached your account's limit for EKS clusters.
- IAM role issues: Ensure the cluster role has the correct trust relationship and permissions.

**Issue: Nodes don't join the cluster**

If nodes don't appear when you run `kubectl get nodes`:
- Wait a few minutes, as it can take time for nodes to register.
- Check the node group status with `aws eks describe-nodegroup`.
- Verify that the node role has all three required policies attached.

**Issue: kubectl commands fail**

If kubectl commands return errors:
- Ensure you've run `aws eks update-kubeconfig` with the correct cluster name.
- Check that your AWS CLI credentials are valid and have EKS permissions.
- Verify that kubectl is properly installed and in your PATH.

## Clean up resources

When you're finished with your EKS cluster, it's important to clean up the resources to avoid incurring unnecessary charges. In this section, you'll delete all the resources you created.

First, delete the node group:

```
aws eks delete-nodegroup \
  --cluster-name my-cluster \
  --nodegroup-name my-nodegroup
```

Wait for the node group to be deleted:

```
aws eks wait nodegroup-deleted \
  --cluster-name my-cluster \
  --nodegroup-name my-nodegroup
```

Next, delete the EKS cluster:

```
aws eks delete-cluster \
  --name my-cluster
```

Wait for the cluster to be deleted:

```
aws eks wait cluster-deleted \
  --name my-cluster
```

Delete the CloudFormation stack that created your VPC:

```
aws cloudformation delete-stack \
  --stack-name my-eks-vpc-stack
```

Finally, delete the IAM roles you created:

```
aws iam detach-role-policy \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy \
  --role-name myAmazonEKSClusterRole

aws iam delete-role \
  --role-name myAmazonEKSClusterRole

aws iam detach-role-policy \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy \
  --role-name myAmazonEKSNodeRole

aws iam detach-role-policy \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly \
  --role-name myAmazonEKSNodeRole

aws iam detach-role-policy \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy \
  --role-name myAmazonEKSNodeRole

aws iam delete-role \
  --role-name myAmazonEKSNodeRole
```

These commands detach the policies from the roles and then delete the roles themselves.

## Going to production

This tutorial is designed to help you learn how to create and manage an EKS cluster using the AWS CLI. For production environments, consider the following additional best practices:

### Security considerations

1. **Network security**:
   - Place worker nodes in private subnets only
   - Use security groups to restrict traffic between pods
   - Consider using private API server endpoints

2. **IAM and RBAC**:
   - Implement fine-grained access control using Kubernetes RBAC
   - Use IAM roles for service accounts instead of node instance roles when possible
   - Follow the principle of least privilege for all IAM roles

3. **Encryption**:
   - Enable encryption for EKS secrets
   - Use AWS KMS for encrypting EBS volumes
   - Consider using network policies to encrypt pod-to-pod traffic

For more information on EKS security best practices, see [Amazon EKS security](https://docs.aws.amazon.com/eks/latest/userguide/security.html).

### Architecture considerations

1. **High availability**:
   - Deploy across multiple Availability Zones
   - Use multiple node groups for different workload types
   - Implement proper pod disruption budgets

2. **Scaling**:
   - Configure cluster autoscaler for automatic node scaling
   - Use horizontal pod autoscaler for application scaling
   - Consider Karpenter for more efficient node provisioning

3. **Monitoring and logging**:
   - Enable CloudWatch Container Insights
   - Set up Prometheus and Grafana for monitoring
   - Configure Fluentd or Fluent Bit for centralized logging

For more information on EKS architecture best practices, see the [EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/).

## Next steps

Now that you've learned how to create and manage an Amazon EKS cluster using the AWS CLI, you can explore more advanced features and use cases:

- Deploy a [sample application](https://docs.aws.amazon.com/eks/latest/userguide/sample-deployment.html) to your EKS cluster
- Learn how to [manage access to your cluster](https://docs.aws.amazon.com/eks/latest/userguide/grant-k8s-access.html) for other IAM users and roles
- Explore [cluster autoscaling](https://docs.aws.amazon.com/eks/latest/userguide/autoscaling.html) to automatically adjust the size of your node groups based on demand
- Configure [persistent storage](https://docs.aws.amazon.com/eks/latest/userguide/storage.html) for your applications using Amazon EBS or Amazon EFS
- Set up [monitoring and logging](https://docs.aws.amazon.com/eks/latest/userguide/monitoring.html) for your EKS cluster
- Implement [security best practices](https://docs.aws.amazon.com/eks/latest/userguide/security.html) for your Kubernetes workloads
