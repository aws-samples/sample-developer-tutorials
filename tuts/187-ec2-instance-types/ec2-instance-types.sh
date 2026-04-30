#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/tut.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null))}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
echo "Step 1: Listing instance type families"
aws ec2 describe-instance-types --filters "Name=instance-type,Values=t3.*" --query 'InstanceTypes[].{Type:InstanceType,vCPUs:VCpuInfo.DefaultVCpus,Memory:MemoryInfo.SizeInMiB}' --output table
echo "Step 2: Describing a specific type"
aws ec2 describe-instance-types --instance-types t3.micro --query 'InstanceTypes[0].{Type:InstanceType,vCPUs:VCpuInfo.DefaultVCpus,Memory:MemoryInfo.SizeInMiB,Network:NetworkInfo.NetworkPerformance,Arch:ProcessorInfo.SupportedArchitectures}' --output table
echo "Step 3: Finding instances by criteria"
aws ec2 describe-instance-types --filters "Name=vcpu-info.default-vcpus,Values=2" "Name=memory-info.size-in-mib,Values=4096" --query 'InstanceTypes[:5].{Type:InstanceType,vCPUs:VCpuInfo.DefaultVCpus,Memory:MemoryInfo.SizeInMiB}' --output table
echo ""; echo "Tutorial complete. No resources created — read-only."
rm -rf "$WORK_DIR"
