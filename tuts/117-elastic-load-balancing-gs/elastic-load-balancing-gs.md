# Create an Application Load Balancer with Elastic Load Balancing

## Overview

In this tutorial, you use the AWS CLI to create an Application Load Balancer (ALB) in your default VPC. You create a security group, target group, and HTTP listener, then verify the ALB is active. You then delete all resources during cleanup.

## Prerequisites

- AWS CLI installed and configured with appropriate permissions.
- A default VPC with at least two subnets in different Availability Zones.
- An IAM principal with permissions for `elbv2:CreateLoadBalancer`, `elbv2:CreateTargetGroup`, `elbv2:CreateListener`, `elbv2:DescribeLoadBalancers`, `elbv2:DeleteLoadBalancer`, `elbv2:DeleteTargetGroup`, `elbv2:DeleteListener`, `ec2:CreateSecurityGroup`, `ec2:AuthorizeSecurityGroupIngress`, `ec2:DeleteSecurityGroup`, `ec2:DescribeVpcs`, and `ec2:DescribeSubnets`.

## Step 1: Get VPC and subnets

Identify the default VPC and select two subnets for the ALB. An ALB requires subnets in at least two Availability Zones.

```bash
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" \
    --query 'Vpcs[0].VpcId' --output text)

SUBNETS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" \
    --query 'Subnets[:2].SubnetId' --output text)
SUBNET1=$(echo "$SUBNETS" | awk '{print $1}')
SUBNET2=$(echo "$SUBNETS" | awk '{print $2}')
echo "VPC: $VPC_ID  Subnets: $SUBNET1, $SUBNET2"
```

## Step 2: Create a security group

Create a security group that allows inbound HTTP traffic on port 80.

```bash
RANDOM_ID=$(openssl rand -hex 4)

SG_ID=$(aws ec2 create-security-group --group-name "tut-alb-sg-${RANDOM_ID}" \
    --description "Tutorial ALB security group" --vpc-id "$VPC_ID" \
    --query 'GroupId' --output text)

aws ec2 authorize-security-group-ingress --group-id "$SG_ID" \
    --protocol tcp --port 80 --cidr 0.0.0.0/0 > /dev/null
echo "Security group: $SG_ID"
```

This rule allows HTTP traffic from any source. In production, restrict the CIDR to known IP ranges.

## Step 3: Create a target group

Create an IP-based target group. The ALB forwards traffic to targets registered in this group.

```bash
TG_NAME="tut-tg-${RANDOM_ID}"

TG_ARN=$(aws elbv2 create-target-group --name "$TG_NAME" \
    --protocol HTTP --port 80 --vpc-id "$VPC_ID" \
    --target-type ip \
    --query 'TargetGroups[0].TargetGroupArn' --output text)
echo "Target group: $TG_ARN"
```

Target type `ip` lets you register IP addresses directly. Use `instance` to register EC2 instances by ID instead.

## Step 4: Create the Application Load Balancer

Create the ALB across the two subnets with the security group attached.

```bash
ALB_NAME="tut-alb-${RANDOM_ID}"

ALB_ARN=$(aws elbv2 create-load-balancer --name "$ALB_NAME" \
    --subnets $SUBNET1 $SUBNET2 \
    --security-groups "$SG_ID" \
    --query 'LoadBalancers[0].LoadBalancerArn' --output text)
echo "ALB ARN: $ALB_ARN"
```

## Step 5: Wait for ALB to be active

The ALB takes 1–2 minutes to provision. Wait for it to reach the `active` state.

```bash
aws elbv2 wait load-balancer-available --load-balancer-arns "$ALB_ARN"

DNS_NAME=$(aws elbv2 describe-load-balancers --load-balancer-arns "$ALB_ARN" \
    --query 'LoadBalancers[0].DNSName' --output text)
echo "DNS: $DNS_NAME"
```

The DNS name is publicly resolvable. Without registered targets, requests to this DNS return a 503 error.

## Step 6: Create an HTTP listener

Create a listener on port 80 that forwards traffic to the target group.

```bash
LISTENER_ARN=$(aws elbv2 create-listener --load-balancer-arn "$ALB_ARN" \
    --protocol HTTP --port 80 \
    --default-actions "Type=forward,TargetGroupArn=$TG_ARN" \
    --query 'Listeners[0].ListenerArn' --output text)
echo "Listener: $LISTENER_ARN"
```

The default action forwards all requests to the target group. You can add rules to route requests based on path or host header.

## Step 7: Describe the ALB

View the ALB configuration.

```bash
aws elbv2 describe-load-balancers --load-balancer-arns "$ALB_ARN" \
    --query 'LoadBalancers[0].{Name:LoadBalancerName,DNS:DNSName,State:State.Code,Type:Type}' \
    --output table
```

## Cleanup

Delete resources in reverse order. The ALB must be fully deleted before you can remove the target group.

```bash
aws elbv2 delete-listener --listener-arn "$LISTENER_ARN"
aws elbv2 delete-load-balancer --load-balancer-arn "$ALB_ARN"

echo "Waiting for ALB deletion..."
aws elbv2 wait load-balancers-deleted --load-balancer-arns "$ALB_ARN"

aws elbv2 delete-target-group --target-group-arn "$TG_ARN"
aws ec2 delete-security-group --group-id "$SG_ID"
```

ALBs incur hourly charges (~$0.02/hr) plus data processing fees. Clean up promptly to avoid costs.

The script automates all steps including cleanup:

```bash
bash elastic-load-balancing-gs.sh
```

## Related resources

- [Getting started with Application Load Balancers](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancer-getting-started.html)
- [Create an Application Load Balancer](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-application-load-balancer.html)
- [Target groups for ALBs](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html)
- [Elastic Load Balancing pricing](https://aws.amazon.com/elasticloadbalancing/pricing/)
