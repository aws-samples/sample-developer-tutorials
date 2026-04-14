#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/datasync.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-$(aws configure get region 2>/dev/null)}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
echo "Step 1: Listing agents"
aws datasync list-agents --query 'Agents[:5].{Arn:AgentArn,Name:Name,Status:Status}' --output table 2>/dev/null || echo "  No agents configured"
echo "Step 2: Listing locations"
aws datasync list-locations --query 'Locations[:5].{Uri:LocationUri,Arn:LocationArn}' --output table 2>/dev/null || echo "  No locations configured"
echo "Step 3: Listing tasks"
aws datasync list-tasks --query 'Tasks[:5].{Name:Name,Status:Status,Arn:TaskArn}' --output table 2>/dev/null || echo "  No tasks configured"
echo ""; echo "Tutorial complete. DataSync requires an agent (on-premises or EC2) for data transfer."
echo "No resources created — this tutorial shows the DataSync API structure."
rm -rf "$WORK_DIR"
