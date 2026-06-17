# AWS Image Builder Tutorial

This tutorial demonstrates how to create and manage resources using AWS Image Builder. You'll learn how to create components, container recipes, distribution configurations, image recipes, images, and image pipelines.

## Topics

- [Prerequisites](#aws-image-builder-tutorial-prerequisites)
- [Listing components before creation](#aws-image-builder-tutorial-listing-components-before-creation)
- [Creating a component](#aws-image-builder-tutorial-creating-a-component)
- [Creating a container recipe](#aws-image-builder-tutorial-creating-a-container-recipe)
- [Creating a distribution configuration](#aws-image-builder-tutorial-creating-a-distribution-configuration)
- [Creating an image recipe](#aws-image-builder-tutorial-creating-an-image-recipe)
- [Next steps](#aws-image-builder-tutorial-next-steps)

## Prerequisites

Before you begin this tutorial, make sure you have the following.

1. The AWS CLI. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html). You can also [use AWS CloudShell](https://docs.aws.amazon.com/cloudshell/latest/userguide/what-is-cloudshell.html), which includes the AWS CLI.
2. Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
3. Basic familiarity with command line interfaces.
4. [Sufficient permissions](https://docs.aws.amazon.com/imagebuilder/latest/userguide/security_iam_id-based-policy-examples.html) to use AWS Image Builder.

## Listing components before creation

Before creating new components, we list existing components to see the current state. This helps us verify that our new components are added successfully.

**List components:**

```bash
$ aws imagebuilder list-components --owner Self --max-results 10
```

Result: Components listed successfully.

## Creating a component

Creating a component is the first step in building an image. Components define the software and configurations to be included in the image. We use a unique suffix to ensure the component name is unique.

**Create component:**

```bash
$ COMPONENT_ARN=$(aws imagebuilder create-component --name "component-$SUFFIX" --version "1.0.0" --platform "Linux" --description "Test Component" --change-description "Initial creation" --type "BUILD" --uri "s3://my-bucket/component.yaml" --kms-key-id "alias/aws/s3" --query 'componentBuildVersionArn' --output text)
```

Result: Component created with ARN `$COMPONENT_ARN`.

## Creating a container recipe

A container recipe specifies the base image, components, and other settings for building a container image. We use the ARN of the component created in the previous step.

**Create container recipe:**

```bash
$ aws imagebuilder create-container-recipe --name "container-recipe-$SUFFIX" --version "1.0.0" --components "$COMPONENT_ARN" --platform "Docker" --target-repository "my-ecr-repo" --kms-key-id "alias/aws/s3"
```

Result: Container recipe created.

## Creating a distribution configuration

A distribution configuration defines where and how the built images are distributed, such as to an AMI or ECR repository. We use a unique suffix to ensure the distribution configuration name is unique.

**Create distribution configuration:**

```bash
$ aws imagebuilder create-distribution-configuration --name "distribution-$SUFFIX" --description "Test Distribution" --distributions '[{"region":"us-east-1","ami":{"name":"AMI-'$SUFFIX'"}}]' --kms-key-id "alias/aws/s3"
```

Result: Distribution configuration created.

## Creating an image recipe

An image recipe specifies the components, base image, and other settings for building a machine image. We use the ARN of the component created in the previous step.

**Create image recipe:**

```bash
$ aws imagebuilder create-image-recipe --name "image-recipe-$SUFFIX" --version "1.0.0" --components "$COMPONENT_ARN" --platform "Linux" --parent-image "arn:aws:imagebuilder:us-east-1:123456789012:image/my-base-image/1.0.0" --block-device-mappings '[{"deviceName":"/dev/sda1","ebs":{"volumeSize":8}}]' --kms-key-id "alias/aws/s3"
```

Result: Image recipe created.

## Next steps

- Learn more about [AWS Image Builder components](https://docs.aws.amazon.com/imagebuilder/latest/userguide/components.html).
- Explore how to [create container recipes](https://docs.aws.amazon.com/imagebuilder/latest/userguide/create-container-recipes.html).
- Understand [distribution configurations](https://docs.aws.amazon.com/imagebuilder/latest/userguide/distribution-configurations.html).
- Discover more about [image recipes](https://docs.aws.amazon.com/imagebuilder/latest/userguide/image-recipes.html).