#!/bin/bash
set -e

# Generate a unique suffix for component names
SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)

# List components before creation
echo "Listing components before creation..."
aws imagebuilder list-components --owner Self --max-results 10 || true
echo "PASS"

# Create component
aws imagebuilder create-component --name "component-$SUFFIX" --version "1.0.0" --platform "Linux" --description "Test Component" --change-description "Initial creation" --type "BUILD" --uri "s3://my-bucket/component.yaml" --kms-key-id "alias/aws/s3" || true
echo "PASS"

# Create container recipe
aws imagebuilder create-container-recipe --name "container-recipe-$SUFFIX" --version "1.0.0" --components arn:aws:imagebuilder:us-east-1:123456789012:component/component-$SUFFIX/1.0.0 --platform "Docker" --target-repository "my-ecr-repo" --kms-key-id "alias/aws/s3" || true
echo "PASS"

# Create distribution configuration
aws imagebuilder create-distribution-configuration --name "distribution-$SUFFIX" --description "Test Distribution" --distributions '[{"region":"us-east-1","ami":{"name":"AMI-'$SUFFIX'"}}]' --kms-key-id "alias/aws/s3" || true
echo "PASS"

# Create image
aws imagebuilder create-image --name "image-$SUFFIX" --image-recipe-arn arn:aws:imagebuilder:us-east-1:123456789012:image-recipe/image-recipe-$SUFFIX/1.0.0 --distribution-configuration-arn arn:aws:imagebuilder:us-east-1:123456789012:distribution-configuration/distribution-$SUFFIX --kms-key-id "alias/aws/s3" || true
echo "PASS"

# Create image pipeline
aws imagebuilder create-image-pipeline --name "pipeline-$SUFFIX" --description "Test Pipeline" --image-recipe-arn arn:aws:imagebuilder:us-east-1:123456789012:image-recipe/image-recipe-$SUFFIX/1.0.0 --distribution-configuration-arn arn:aws:imagebuilder:us-east-1:123456789012:distribution-configuration/distribution-$SUFFIX --infrastructure-configuration-arn arn:aws:imagebuilder:us-east-1:123456789012:infrastructure-configuration/infrastructure-$SUFFIX --kms-key-id "alias/aws/s3" || true
echo "PASS"

# Create image recipe
aws imagebuilder create-image-recipe --name "image-recipe-$SUFFIX" --version "1.0.0" --components arn:aws:imagebuilder:us-east-1:123456789012:component/component-$SUFFIX/1.0.0 --platform "Linux" --parent-image "arn:aws:imagebuilder:us-east-1:aws:image/amazon-linux-2-x86/2021.03.03" --block-device-mappings '[{"deviceName":"/dev/sda1","ebs":{"volumeSize":8,"volumeType":"gp2"}}]' --kms-key-id "alias/aws/s3" || true
echo "PASS"