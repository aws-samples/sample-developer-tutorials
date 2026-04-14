#!/bin/bash
exec > >(tee -a "$(mktemp -d)/amis.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-$(aws configure get region 2>/dev/null)}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
echo "Step 1: Listing Amazon Linux 2023 AMIs"
aws ec2 describe-images --owners amazon --filters "Name=name,Values=al2023-ami-2023*-x86_64" "Name=state,Values=available" --query 'sort_by(Images, &CreationDate)[-3:].{Id:ImageId,Name:Name,Created:CreationDate}' --output table
echo "Step 2: Listing Ubuntu AMIs"
aws ec2 describe-images --owners 099720109477 --filters "Name=name,Values=ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04*" "Name=architecture,Values=x86_64" --query 'sort_by(Images, &CreationDate)[-3:].{Id:ImageId,Name:Name}' --output table
echo "Step 3: Describing a specific AMI"
AMI=$(aws ec2 describe-images --owners amazon --filters "Name=name,Values=al2023-ami-2023*-x86_64" --query 'sort_by(Images, &CreationDate)[-1].ImageId' --output text)
aws ec2 describe-images --image-ids "$AMI" --query 'Images[0].{Id:ImageId,Arch:Architecture,Root:RootDeviceType,Virt:VirtualizationType}' --output table
echo "Step 4: Listing your own AMIs"
aws ec2 describe-images --owners self --query 'Images[:5].{Id:ImageId,Name:Name,State:State}' --output table 2>/dev/null || echo "  No custom AMIs"
echo ""; echo "Tutorial complete. No resources created — read-only."
