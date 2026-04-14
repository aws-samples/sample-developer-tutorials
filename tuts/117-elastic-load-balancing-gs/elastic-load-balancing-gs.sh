#!/bin/bash
# Tutorial: Create an Application Load Balancer
# Source: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancer-getting-started.html

WORK_DIR=$(mktemp -d)
LOG_FILE="$WORK_DIR/elbv2-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null)}}
if [ -z "$REGION" ]; then
    echo "ERROR: No AWS region configured. Set one with: export AWS_DEFAULT_REGION=us-east-1"
    exit 1
fi
export AWS_DEFAULT_REGION="$REGION"
echo "Region: $REGION"

RANDOM_ID=$(openssl rand -hex 4)
ALB_NAME="tut-alb-${RANDOM_ID}"
TG_NAME="tut-tg-${RANDOM_ID}"

handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }
trap 'handle_error $LINENO' ERR

cleanup() {
    echo ""
    echo "Cleaning up resources..."
    [ -n "$LISTENER_ARN" ] && aws elbv2 delete-listener --listener-arn "$LISTENER_ARN" 2>/dev/null && echo "  Deleted listener"
    [ -n "$ALB_ARN" ] && aws elbv2 delete-load-balancer --load-balancer-arn "$ALB_ARN" 2>/dev/null && echo "  Deleted ALB $ALB_NAME"
    # Wait for ALB to be deleted before deleting TG
    if [ -n "$ALB_ARN" ]; then
        echo "  Waiting for ALB deletion..."
        aws elbv2 wait load-balancers-deleted --load-balancer-arns "$ALB_ARN" 2>/dev/null || sleep 30
    fi
    [ -n "$TG_ARN" ] && aws elbv2 delete-target-group --target-group-arn "$TG_ARN" 2>/dev/null && echo "  Deleted target group $TG_NAME"
    [ -n "$SG_ID" ] && aws ec2 delete-security-group --group-id "$SG_ID" 2>/dev/null && echo "  Deleted security group $SG_ID"
    rm -rf "$WORK_DIR"
    echo "Cleanup complete."
}

# Step 1: Get VPC and subnets
echo "Step 1: Getting VPC and subnets"
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query 'Vpcs[0].VpcId' --output text)
SUBNETS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" \
    --query 'Subnets[:2].SubnetId' --output text)
SUBNET1=$(echo "$SUBNETS" | awk '{print $1}')
SUBNET2=$(echo "$SUBNETS" | awk '{print $2}')
echo "  VPC: $VPC_ID"
echo "  Subnets: $SUBNET1, $SUBNET2"

# Step 2: Create security group
echo "Step 2: Creating security group"
SG_ID=$(aws ec2 create-security-group --group-name "tut-alb-sg-${RANDOM_ID}" \
    --description "Tutorial ALB security group" --vpc-id "$VPC_ID" \
    --query 'GroupId' --output text)
aws ec2 authorize-security-group-ingress --group-id "$SG_ID" \
    --protocol tcp --port 80 --cidr 0.0.0.0/0 > /dev/null
echo "  Security group: $SG_ID (port 80 open)"

# Step 3: Create target group
echo "Step 3: Creating target group: $TG_NAME"
TG_ARN=$(aws elbv2 create-target-group --name "$TG_NAME" \
    --protocol HTTP --port 80 --vpc-id "$VPC_ID" \
    --target-type ip \
    --query 'TargetGroups[0].TargetGroupArn' --output text)
echo "  Target group ARN: $TG_ARN"

# Step 4: Create ALB
echo "Step 4: Creating Application Load Balancer: $ALB_NAME"
ALB_ARN=$(aws elbv2 create-load-balancer --name "$ALB_NAME" \
    --subnets $SUBNET1 $SUBNET2 \
    --security-groups "$SG_ID" \
    --query 'LoadBalancers[0].LoadBalancerArn' --output text)
echo "  ALB ARN: $ALB_ARN"

# Step 5: Wait for ALB to be active
echo "Step 5: Waiting for ALB to be active..."
aws elbv2 wait load-balancer-available --load-balancer-arns "$ALB_ARN"
DNS_NAME=$(aws elbv2 describe-load-balancers --load-balancer-arns "$ALB_ARN" \
    --query 'LoadBalancers[0].DNSName' --output text)
echo "  DNS: $DNS_NAME"

# Step 6: Create listener
echo "Step 6: Creating HTTP listener"
LISTENER_ARN=$(aws elbv2 create-listener --load-balancer-arn "$ALB_ARN" \
    --protocol HTTP --port 80 \
    --default-actions "Type=forward,TargetGroupArn=$TG_ARN" \
    --query 'Listeners[0].ListenerArn' --output text)
echo "  Listener ARN: $LISTENER_ARN"

# Step 7: Describe the ALB
echo "Step 7: ALB details"
aws elbv2 describe-load-balancers --load-balancer-arns "$ALB_ARN" \
    --query 'LoadBalancers[0].{Name:LoadBalancerName,DNS:DNSName,State:State.Code,Type:Type}' --output table

echo ""
echo "Tutorial complete."
echo "The ALB is running but has no targets registered."
echo "Note: ALBs incur hourly charges (~\$0.02/hr). Clean up promptly."
echo ""
echo "Do you want to clean up all resources? (y/n): "
read -r CHOICE
if [[ "$CHOICE" =~ ^[Yy]$ ]]; then
    cleanup
else
    echo "Resources left running. ALB charges ~\$0.02/hr."
    echo "Manual cleanup:"
    echo "  aws elbv2 delete-listener --listener-arn $LISTENER_ARN"
    echo "  aws elbv2 delete-load-balancer --load-balancer-arn $ALB_ARN"
    echo "  # Wait 1-2 minutes, then:"
    echo "  aws elbv2 delete-target-group --target-group-arn $TG_ARN"
    echo "  aws ec2 delete-security-group --group-id $SG_ID"
fi
