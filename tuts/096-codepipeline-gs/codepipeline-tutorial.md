# AWS CodePipeline Tutorial

This tutorial demonstrates how to create an AWS CodePipeline using the AWS CLI. You'll learn how to create a pipeline with Source and Build stages, and ensure proper cleanup.

## Topics

- [Prerequisites](#aws-codepipeline-tutorial-prerequisites)
- [Create a CodePipeline](#aws-codepipeline-tutorial-create-pipeline)
- [Next steps](#aws-codepipeline-tutorial-next-steps)

## Prerequisites

Before you begin this tutorial, make sure you have the following.

- The AWS CLI. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html). You can also [use AWS CloudShell](https://docs.aws.amazon.com/cloudshell/latest/userguide/what-is-cloudshell.html), which includes the AWS CLI.
- Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
- Basic familiarity with command line interfaces.
- Sufficient permissions to create and manage CodePipeline resources.

## Create a CodePipeline

### **Creating Pipeline**

In this step, we will create an AWS CodePipeline. CodePipeline is a continuous delivery service you can use to model, visualize, and automate the steps required to release your software. The pipeline will have a Source stage that pulls from an S3 bucket and a Build stage that uses CodeBuild.

```bash
REGION="${AWS_DEFAULT_REGION:-us-east-1}"

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)

PIPELINE_NAME="pipeline-${SUFFIX}"

aws codepipeline create-pipeline --cli-input-json "{\"pipeline\":{\"name\": \"${PIPELINE_NAME}\",\"roleArn\": \"arn:aws:iam::123456789012:role/doc-babu-codepipeline-role\",\"artifactStores\":{\"$REGION\":{\"type\":\"S3\",\"location\":\"my-bucket\"}},\"stages\": [{\"name\": \"Source\",\"actions\": [{\"name\": \"SourceAction\",\"actionTypeId\": {\"category\": \"Source\",\"owner\": \"AWS\",\"provider\": \"S3\",\"version\": \"1\"},\"outputArtifacts\": [{\"name\": \"MyApp\"}],\"configuration\": {\"S3Bucket\":\"my-bucket\",\"S3ObjectKey\": \"path/to/my/app.zip\"},\"runOrder\": 1}]},{\"name\": \"Build\",\"actions\": [{\"name\": \"BuildAction\",\"actionTypeId\": {\"category\": \"Build\",\"owner\": \"AWS\",\"provider\": \"CodeBuild\",\"version\": \"1\"},\"inputArtifacts\": [{\"name\": \"MyApp\"}],\"outputArtifacts\": [{\"name\": \"BuildOutput\"}],\"configuration\": {\"ProjectName\": \"my-codebuild-project\"},\"runOrder\": 1}]}]}}"
```

Result: Pipeline `${PIPELINE_NAME}` created.

Tutorial complete. You have learned how to create an AWS CodePipeline with Source and Build stages using the AWS CLI. The pipeline was automatically named to ensure uniqueness and will be cleaned up upon script exit.

## Next steps

- Learn more about [AWS CodePipeline](https://docs.aws.amazon.com/codepipeline/latest/userguide/welcome.html).
- Explore how to [integrate CodePipeline with other AWS services](https://docs.aws.amazon.com/codepipeline/latest/userguide/integrations.html).
- Discover best practices for [managing your pipelines](https://docs.aws.amazon.com/codepipeline/latest/userguide/pipelines-best-practices.html).