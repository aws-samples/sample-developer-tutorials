#!/bin/bash
set -e
SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
echo "Creating Detective graph..."
GRAPH_ARN=$(aws detective create-graph --query 'GraphArn' --output text)
echo "Graph: $GRAPH_ARN"
aws detective list-graphs --query 'GraphList[0].Arn' --output text
echo "Deleting graph..."
aws detective delete-graph --graph-arn "$GRAPH_ARN" || true
echo "PASS"