# AWS CodeBuild Tutorial: Creating and Starting a Build Project

This tutorial guides you through creating a CodeBuild project and starting a build. You will learn how to use AWS CLI commands to manage CodeBuild resources.

## Topics

- [Prerequisites](#prerequisites)
- [Generate a unique suffix](#generate-a-unique-suffix)
- [Create a temporary directory](#create-a-temporary-directory)
- [Create the project configuration file](#create-the-project-configuration-file)
- [Replace placeholder with unique suffix](#replace-placeholder-with-unique-suffix)
- [Create the CodeBuild project](#create-the-codebuild-project)
- [Start the build](#start-the-build)
- [Clean up resources](#clean-up-resources)
- [Next steps](#next-steps)

## Prerequisites

Before you begin this tutorial, make sure you have the following:

- The AWS CLI. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html).
- Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
- Basic familiarity with command line interfaces.
- Sufficient permissions to create and manage CodeBuild projects.

## Generate a unique suffix

We generate a unique suffix to ensure that the project name is unique. This prevents conflicts with existing projects.

**Generate a unique suffix:**

```bash
$ SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
```

**Result:** `$SUFFIX`

## Create a temporary directory

A temporary directory is created to store our JSON configuration file. This directory will be cleaned up at the end of the tutorial.

**Create a temporary directory:**

```bash
$ TEMP_DIR=$(mktemp -d)
```

**Result:** `$TEMP_DIR`

## Create the project configuration file

We create a JSON file that defines the CodeBuild project configuration. This includes the project name, source details, artifacts, environment, and service role.

**Create the project configuration file:**

```bash
$ cat > "$TEMP_DIR/create.json" << 'ENDJSON'
{
  "name": "build-PLACEHOLDER",
  "source": {
    "type": "NO_SOURCE",
    "buildspec": "version: 0.2\nphases:\n  build:\n    commands:\n      - echo hello"
  },
  "artifacts": {
    "type": "NO_ARTIFACTS"
  },
  "environment": {
    "type": "LINUX_CONTAINER",
    "image": "aws/codebuild/standard:7.0",
    "computeType": "BUILD_GENERAL1_SMALL"
  },
  "serviceRole": "arn:aws:iam::123456789012:role/doc-babu-codebuild-role"
}
ENDJSON
```

**Result:** Configuration file created at `$TEMP_DIR/create.json`

## Replace placeholder with unique suffix

We replace the placeholder in the JSON file with the unique suffix to create a unique project name.

**Replace placeholder with unique suffix:**

```bash
$ sed -i "s/PLACEHOLDER/$SUFFIX/" "$TEMP_DIR/create.json"
```

**Result:** Placeholder replaced with `$SUFFIX`

## Create the CodeBuild project

We use the AWS CLI to create a CodeBuild project using the configuration file. This will set up the project with the specified settings.

**Create the CodeBuild project:**

```bash
$ PROJECT_ARN=$(aws codebuild create-project --cli-input-json "file://$TEMP_DIR/create.json" --query 'project.arn' --output text)
```

**Result:** Project ARN: `$PROJECT_ARN`

## Start the build

We start a build for the newly created project. This will execute the buildspec defined in the project configuration.

**Start the build:**

```bash
$ BUILD_ID=$(aws codebuild start-build --project-name "build-$SUFFIX" --query 'build.id' --output text)
```

**Result:** Build ID: `$BUILD_ID`

## Clean up resources

To avoid unnecessary charges, clean up the resources you created. The script automatically handles this by trapping the EXIT signal and deleting the created project and temporary directory.

## Next steps

- Learn more about [CodeBuild project settings](https://docs.aws.amazon.com/codebuild/latest/userguide/project-settings.html).
- Explore [buildspec reference](https://docs.aws.amazon.com/codebuild/latest/userguide/build-spec-ref.html) for more complex build configurations.
- Discover how to [monitor builds](https://docs.aws.amazon.com/codebuild/latest/userguide/monitor.html) using CloudWatch.