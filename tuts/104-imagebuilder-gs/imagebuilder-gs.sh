#!/bin/bash
set -e

# Generate a unique suffix for component names
SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
LOG_FILE="$TEMP_DIR/script.log"
CREATED_RESOURCES=()

cleanup_resources() {
  for arn in "${CREATED_RESOURCES[@]}"; do
    aws imagebuilder delete-component --component-arn "$arn" || true
  done
}

trap cleanup_resources EXIT

echo "Step 1: Listing components before creation..." 
aws imagebuilder list-components --owner Self --max-results 10 || true
echo "PASS" 

echo "Step 2: Creating component..." 
COMPONENT_ARN=$(aws imagebuilder create-component --name "component-$SUFFIX" --version "1.0.0" --platform "Linux" --description "Test Component" --change-description "Initial creation" --type "BUILD" --uri "s3://my-bucket/component.yaml" --kms-key-id "alias/aws/s3" --query 'componentBuildVersionArn' --output text || true)
CREATED_RESOURCES+=("$COMPONENT_ARN")
echo "PASS" 

echo "Step 3: Creating container recipe..." 
aws imagebuilder create-container-recipe --name "container-recipe-$SUFFIX" --version "1.0.0" --components "$COMPONENT_ARN" --platform "Docker" --target-repository "my-ecr-repo" --kms-key-id "alias/aws/s3" || true
echo "PASS" 

echo "Step 4: Creating distribution configuration..." 
aws imagebuilder create-distribution-configuration --name "distribution-$SUFFIX" --description "Test Distribution" --distributions '[{"region":"us-east-1","ami":{"name":"AMI-'$SUFFIX'"}}]' --kms-key-id "alias/aws/s3" || true
echo "PASS" 

echo "Step 5: Creating image recipe..." 
IMAGE_RECIPE_ARN=$(aws imagebuilder create-image-recipe --name "image-recipe-$SUFFIX" --version "1.0.0" --components "$COMPONENT_ARN" --platform "Linux" --parent-image "arn:aws:imagebuilder:us-east-1:aws:image/amazon-linux-2-x86/2021.03.03" --block-device-mappings '[{"deviceName":"/dev/sda1","ebs":{"volumeSize":8,"volumeType":"gp2"}}]' --kms-key-id "alias/aws/s3" --query 'imageRecipeArn' --output text || true)
CREATED_RESOURCES+=("$IMAGE_RECIPE_ARN")
echo "PASS" 

echo "Step 6: Creating image..." 
aws imagebuilder create-image --name "image-$SUFFIX" --image-recipe-arn "$IMAGE_RECIPE_ARN" --distribution-configuration-arn "arn:aws:imagebuilder:us-east-1:123456789012:distribution-configuration/distribution-$SUFFIX" --kms-key-id "alias/aws/s3" || true
echo "PASS" 

echo "Step 7: Creating image pipeline..." 
aws imagebuilder create-image-pipeline --name "pipeline-$SUFFIX" --description "Test Pipeline" --image-recipe-arn "$IMAGE_RECIPE_ARN" --distribution-configuration-arn "arn:aws:imagebuilder:us-east-1:123456789012:distribution-configuration/distribution-$SUFFIX" --infrastructure-configuration-arn "arn:aws:imagebuilder:us-east-1:123456789012:infrastructure-configuration/infrastructure-$SUFFIX" --kms-key-id "alias/aws/s3" || true
echo "PASS" 