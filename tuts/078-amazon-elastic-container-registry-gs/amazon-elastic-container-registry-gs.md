# Getting started with Amazon ECR using the AWS CLI

This tutorial guides you through the process of creating, pushing, pulling, and managing Docker container images with Amazon Elastic Container Registry (ECR) using the AWS Command Line Interface (AWS CLI).

## Prerequisites

Before you begin this tutorial, make sure you have the following:

1. The AWS CLI. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
2. Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
3. Docker installed on your local machine or EC2 instance. Visit the [Docker installation guide](https://docs.docker.com/engine/installation/) for instructions specific to your operating system.
4. Basic familiarity with Docker concepts and commands.
5. [Sufficient permissions](https://docs.aws.amazon.com/AmazonECR/latest/userguide/security-iam.html) to create and manage ECR resources in your AWS account.

**Cost Information**: The cost of running this tutorial is minimal. Amazon ECR charges $0.10 per GB-month for storage and has data transfer costs that vary by region. For this tutorial, with a approximately 200MB image stored for a short time, the cost is less than $0.01. AWS Free Tier includes 500MB of storage per month for private repositories, which would cover this tutorial. See [Amazon ECR pricing](https://aws.amazon.com/ecr/pricing/) for more details.

**Time to Complete**: Approximately 20-30 minutes.

Before you start, set the environment variables for your AWS account ID and region:

```
$ export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
$ export AWS_REGION=$(aws configure get region)
```

## Create a Docker image

First, you'll create a simple web application Docker image that you'll later push to Amazon ECR.

**Create a Dockerfile**

Create a file named `Dockerfile` with the following content:

```
FROM public.ecr.aws/amazonlinux/amazonlinux:latest

# Install dependencies
RUN yum update -y && \
 yum install -y httpd

# Install apache and write hello world message
RUN echo 'Hello World!' > /var/www/html/index.html

# Configure apache
RUN echo 'mkdir -p /var/run/httpd' >> /root/run_apache.sh && \
 echo 'mkdir -p /var/lock/httpd' >> /root/run_apache.sh && \
 echo '/usr/sbin/httpd -D FOREGROUND' >> /root/run_apache.sh && \
 chmod 755 /root/run_apache.sh

EXPOSE 80

CMD /root/run_apache.sh
```

This Dockerfile uses the Amazon Linux image from Amazon ECR Public Gallery as a base. It installs the Apache web server, creates a simple "Hello World" web page, and configures Apache to run in the foreground.

**Build the Docker image**

Build the Docker image using the following command:

```
$ docker build -t hello-app .
```

The `-t` flag tags your image with the name "hello-app". The dot at the end specifies that the Dockerfile is in the current directory.

**Verify the image was created**

List your Docker images to confirm that the image was created successfully:

```
$ docker images --filter reference=hello-app
```

You should see output similar to:

```
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
hello-app           latest              abcd1234e567        1 minute ago        194MB
```

## Create an Amazon ECR repository

Now that you have a Docker image, you need to create an Amazon ECR repository to store it.

**Create a repository**

Create a repository named "hello-app-repository" using the following command:

```
$ aws ecr create-repository --repository-name hello-app-repository
```

The command returns information about the newly created repository, including its Amazon Resource Name (ARN) and URI:

```
{
    "repository": {
        "repositoryArn": "arn:aws:ecr:us-east-1:123456789012:repository/hello-app-repository",
        "registryId": "123456789012",
        "repositoryName": "hello-app-repository",
        "repositoryUri": "123456789012.dkr.ecr.us-east-1.amazonaws.com/hello-app-repository",
        "createdAt": "2025-01-13T12:00:00.000Z",
        "imageTagMutability": "MUTABLE",
        "imageScanningConfiguration": {
            "scanOnPush": false
        },
        "encryptionConfiguration": {
            "encryptionType": "AES256"
        }
    }
}
```

Take note of the `repositoryUri` value, as you'll need it in the next steps.

## Authenticate to Amazon ECR

Before you can push or pull images, you need to authenticate your Docker client to your Amazon ECR registry.

**Get authentication token**

Use the `get-login-password` command to retrieve an authentication token and authenticate your Docker client:

```
$ aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
```

If successful, you'll see the output:

```
Login Succeeded
```

This authentication is valid for 12 hours, after which you'll need to authenticate again.

## Push an image to Amazon ECR

Now that you've authenticated to Amazon ECR, you can tag and push your Docker image to your repository.

**Tag the image**

Tag your local image with the Amazon ECR repository URI:

```
$ docker tag hello-app:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/hello-app-repository:latest
```

This command doesn't produce any output, but it creates a new tag for your image that points to your Amazon ECR repository.

**Push the image**

Push the tagged image to Amazon ECR:

```
$ docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/hello-app-repository:latest
```

You'll see output showing the progress of the push operation:

```
The push refers to repository [123456789012.dkr.ecr.us-east-1.amazonaws.com/hello-app-repository]
abcd1234: Pushed
5678efgh: Pushed
90ijklmn: Pushed
opqr1234: Pushed
latest: digest: sha256:abcd1234efgh5678ijkl90mnopqr1234stuvwxyz1234567890abcdefghijkl size: 6774
```

## Pull an image from Amazon ECR

After pushing an image to Amazon ECR, you can pull it to any machine that has Docker installed and appropriate permissions.

**Remove the local image**

To demonstrate pulling from ECR, first remove the local tagged image:

```
$ docker rmi $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/hello-app-repository:latest
```

**Pull the image**

Now pull the image from Amazon ECR:

```
$ docker pull $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/hello-app-repository:latest
```

You'll see output showing the progress of the pull operation:

```
latest: Pulling from hello-app-repository
abcd1234: Pull complete
5678efgh: Pull complete
90ijklmn: Pull complete
opqr1234: Pull complete
Digest: sha256:abcd1234efgh5678ijkl90mnopqr1234stuvwxyz1234567890abcdefghijkl
Status: Downloaded newer image for 123456789012.dkr.ecr.us-east-1.amazonaws.com/hello-app-repository:latest
```

## Delete resources

When you're done with the tutorial, you should clean up the resources you created to avoid incurring any unnecessary charges.

**Delete the image**

Delete the image from your Amazon ECR repository:

```
$ aws ecr batch-delete-image --repository-name hello-app-repository --image-ids imageTag=latest
```

The command returns information about the deleted image:

```
{
    "imageIds": [
        {
            "imageDigest": "sha256:abcd1234efgh5678ijkl90mnopqr1234stuvwxyz1234567890abcdefghijkl",
            "imageTag": "latest"
        }
    ],
    "failures": []
}
```

**Delete the repository**

Delete the Amazon ECR repository:

```
$ aws ecr delete-repository --repository-name hello-app-repository --force
```

The `--force` flag is required because the repository contained images. The command returns information about the deleted repository:

```
{
    "repository": {
        "repositoryArn": "arn:aws:ecr:us-east-1:123456789012:repository/hello-app-repository",
        "registryId": "123456789012",
        "repositoryName": "hello-app-repository",
        "repositoryUri": "123456789012.dkr.ecr.us-east-1.amazonaws.com/hello-app-repository",
        "createdAt": "2025-01-13T12:00:00.000Z",
        "imageTagMutability": "MUTABLE"
    }
}
```

**Remove local Docker images**

Finally, remove the local Docker image:

```
$ docker rmi hello-app:latest
```

## Going to production

This tutorial is designed to teach you the basics of using Amazon ECR with the AWS CLI. For production environments, consider these additional best practices:

### Security best practices

1. **Enable image scanning** - Scan your container images for security vulnerabilities:
   ```
   $ aws ecr create-repository --repository-name hello-app-repository --image-scanning-configuration scanOnPush=true
   ```

2. **Configure image tag immutability** - Prevent overwriting existing image tags:
   ```
   $ aws ecr create-repository --repository-name hello-app-repository --image-tag-mutability IMMUTABLE
   ```

3. **Implement repository policies** - Restrict access to your repositories using IAM policies.

4. **Use non-root users** - In production Dockerfiles, create and use non-root users to run your applications.

### Architecture best practices

1. **Implement lifecycle policies** - Automatically manage image retention to control costs and repository size.

2. **Set up cross-region replication** - For disaster recovery, replicate critical images across regions.

3. **Optimize image size** - Use multi-stage builds to create smaller, more efficient container images.

4. **Automate with infrastructure as code** - Use AWS CloudFormation or AWS CDK to automate repository creation and configuration.

For more information on production best practices, refer to:
- [Amazon ECR Best Practices Guide](https://docs.aws.amazon.com/AmazonECR/latest/userguide/best-practices.html)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [AWS Security Best Practices](https://aws.amazon.com/architecture/security-identity-compliance/)

## Next steps

Now that you've learned the basics of using Amazon ECR with the AWS CLI, you can explore more advanced features:

- [Setting up image scanning](https://docs.aws.amazon.com/AmazonECR/latest/userguide/image-scanning.html) to identify software vulnerabilities in your container images
- [Configuring lifecycle policies](https://docs.aws.amazon.com/AmazonECR/latest/userguide/lifecycle_policy.html) to manage the lifecycle of images in your repositories
- [Setting up cross-region replication](https://docs.aws.amazon.com/AmazonECR/latest/userguide/replication.html) to copy images to repositories in different AWS Regions
- [Using Amazon ECR with Amazon ECS](https://docs.aws.amazon.com/AmazonECR/latest/userguide/ECR_on_ECS.html) to deploy your container images on Amazon Elastic Container Service
- [Using Amazon ECR with Amazon EKS](https://docs.aws.amazon.com/AmazonECR/latest/userguide/ECR_on_EKS.html) to deploy your container images on Amazon Elastic Kubernetes Service
