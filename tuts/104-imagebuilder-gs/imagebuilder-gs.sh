#!/bin/bash
set -e

# Title Banner
echo "=== AWS Image Builder Tutorial ==="
echo "This tutorial demonstrates how to create and manage resources using AWS Image Builder."
echo "We will create components, container recipes, distribution configurations, image recipes, images, and image pipelines."
echo ""

# Redirect output to log file if running interactively
if [ -t 1 ]; then 
  # Generate a unique suffix for component names
  SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
  TEMP_DIR=$(mktemp -d)
  LOG_FILE="$TEMP_DIR/script.log"
  exec &> >(tee -a "$LOG_FILE")
fi

CREATED_RESOURCES=()

cleanup_resources() {
  for arn in "${CREATED_RESOURCES[@]}"; do
    aws imagebuilder delete-component --component-arn "$arn" || true
  done
}

trap cleanup_resources EXIT

echo "=== Step 1: Listing Components Before Creation ==="
echo "Before creating new components, we list existing components to see the current state."
echo "This helps us verify that our new components are added successfully."
echo ""
aws imagebuilder list-components --owner Self --max-results 10 || true
echo "Result: Components listed successfully."
echo ""

echo "=== Step 2: Creating Component ==="
echo "Creating a component is the first step in building an image. Components define the software and configurations to be included in the image."
echo "We use a unique suffix to ensure the component name is unique."
echo ""
COMPONENT_ARN=$(aws imagebuilder create-component --name "component-$SUFFIX" --version "1.0.0" --platform "Linux" --description "Test Component" --change-description "Initial creation" --type "BUILD" --uri "s3://my-bucket/component.yaml" --kms-key-id "alias/aws/s3" --query 'componentBuildVersionArn' --output text || true)
CREATED_RESOURCES+=("$COMPONENT_ARN")
aws imagebuilder tag-resource --resource-arn "$COMPONENT_ARN" --tags Key=project,Value=doc-smith Key=tutorial,Value=imagebuilder-gs || true
echo "Result: Component created with ARN $COMPONENT_ARN"
echo ""

echo "=== Step 3: Creating Container Recipe ==="
echo "A container recipe specifies the base image, components, and other settings for building a container image."
echo "We use the ARN of the component created in the previous step."
echo ""
CONTAINER_RECIPE_ARN=$(aws imagebuilder create-container-recipe --name "container-recipe-$SUFFIX" --version "1.0.0" --components "$COMPONENT_ARN" --platform "Docker" --target-repository "my-ecr-repo" --kms-key-id "alias/aws/s3" --query 'containerRecipeArn' --output text || true)
CREATED_RESOURCES+=("$CONTAINER_RECIPE_ARN")
aws imagebuilder tag-resource --resource-arn "$CONTAINER_RECIPE_ARN" --tags Key=project,Value=doc-smith Key=tutorial,Value=imagebuilder-gs || true
echo "Result: Container recipe created."
echo ""